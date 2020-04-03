--
-- Set associative dcache write-through
--
-- TODO (in no specific order):
--
-- * See list in icache.vhdl
-- * Complete load misses on the cycle when WB data comes instead of
--   at the end of line (this requires dealing with requests coming in
--   while not idle...)
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.common.all;
use work.helpers.all;
use work.wishbone_types.all;

entity dcache is
    generic (
        -- Line size in bytes
        LINE_SIZE : positive := 64;
        -- Number of lines in a set
        NUM_LINES : positive := 32;
        -- Number of ways
        NUM_WAYS  : positive := 4
        );
    port (
        clk          : in std_ulogic;
        rst          : in std_ulogic;

        d_in         : in Loadstore1ToDcacheType;
        d_out        : out DcacheToLoadstore1Type;

	stall_out    : out std_ulogic;

        wishbone_out : out wishbone_master_out;
        wishbone_in  : in wishbone_slave_out
        );
end entity dcache;

architecture rtl of dcache is
    -- BRAM organisation: We never access more than wishbone_data_bits at
    -- a time so to save resources we make the array only that wide, and
    -- use consecutive indices for to make a cache "line"
    --
    -- ROW_SIZE is the width in bytes of the BRAM (based on WB, so 64-bits)
    constant ROW_SIZE      : natural := wishbone_data_bits / 8;
    -- ROW_PER_LINE is the number of row (wishbone transactions) in a line
    constant ROW_PER_LINE  : natural := LINE_SIZE / ROW_SIZE;
    -- BRAM_ROWS is the number of rows in BRAM needed to represent the full
    -- dcache
    constant BRAM_ROWS     : natural := NUM_LINES * ROW_PER_LINE;

    -- Bit fields counts in the address

    -- ROW_BITS is the number of bits to select a row
    constant ROW_BITS      : natural := log2(BRAM_ROWS);
    -- ROW_LINEBITS is the number of bits to select a row within a line
    constant ROW_LINEBITS  : natural := log2(ROW_PER_LINE);
    -- LINE_OFF_BITS is the number of bits for the offset in a cache line
    constant LINE_OFF_BITS : natural := log2(LINE_SIZE);
    -- ROW_OFF_BITS is the number of bits for the offset in a row
    constant ROW_OFF_BITS  : natural := log2(ROW_SIZE);
    -- INDEX_BITS is the number if bits to select a cache line
    constant INDEX_BITS    : natural := log2(NUM_LINES);
    -- TAG_BITS is the number of bits of the tag part of the address
    constant TAG_BITS      : natural := 64 - LINE_OFF_BITS - INDEX_BITS;
    -- WAY_BITS is the number of bits to select a way
    constant WAY_BITS     : natural := log2(NUM_WAYS);

    -- Example of layout for 32 lines of 64 bytes:
    --
    -- ..  tag    |index|  line  |
    -- ..         |   row   |    |
    -- ..         |     |---|    | ROW_LINEBITS  (3)
    -- ..         |     |--- - --| LINE_OFF_BITS (6)
    -- ..         |         |- --| ROW_OFF_BITS  (3)
    -- ..         |----- ---|    | ROW_BITS      (8)
    -- ..         |-----|        | INDEX_BITS    (5)
    -- .. --------|              | TAG_BITS      (53)

    subtype row_t is integer range 0 to BRAM_ROWS-1;
    subtype index_t is integer range 0 to NUM_LINES-1;
    subtype way_t is integer range 0 to NUM_WAYS-1;

    -- The cache data BRAM organized as described above for each way
    subtype cache_row_t is std_ulogic_vector(wishbone_data_bits-1 downto 0);

    -- The cache tags LUTRAM has a row per set. Vivado is a pain and will
    -- not handle a clean (commented) definition of the cache tags as a 3d
    -- memory. For now, work around it by putting all the tags
    subtype cache_tag_t is std_logic_vector(TAG_BITS-1 downto 0);
--    type cache_tags_set_t is array(way_t) of cache_tag_t;
--    type cache_tags_array_t is array(index_t) of cache_tags_set_t;
    constant TAG_RAM_WIDTH : natural := TAG_BITS * NUM_WAYS;
    subtype cache_tags_set_t is std_logic_vector(TAG_RAM_WIDTH-1 downto 0);
    type cache_tags_array_t is array(index_t) of cache_tags_set_t;

    -- The cache valid bits
    subtype cache_way_valids_t is std_ulogic_vector(NUM_WAYS-1 downto 0);
    type cache_valids_t is array(index_t) of cache_way_valids_t;

    -- Storage. Hopefully "cache_rows" is a BRAM, the rest is LUTs
    signal cache_tags   : cache_tags_array_t;
    signal cache_valids : cache_valids_t;

    attribute ram_style : string;
    attribute ram_style of cache_tags : signal is "distributed";

    signal r0 : Loadstore1ToDcacheType;

    -- Type of operation on a "valid" input
    type op_t is (OP_NONE,
		  OP_LOAD_HIT,      -- Cache hit on load
		  OP_LOAD_MISS,     -- Load missing cache
		  OP_LOAD_NC,       -- Non-cachable load
		  OP_BAD,           -- BAD: Cache hit on NC load/store
		  OP_STORE_HIT,     -- Store hitting cache
		  OP_STORE_MISS);   -- Store missing cache

    -- Cache state machine
    type state_t is (IDLE,	       -- Normal load hit processing
		     RELOAD_WAIT_ACK,  -- Cache reload wait ack
                     FINISH_LD_MISS,   -- Extra cycle after load miss
		     STORE_WAIT_ACK,   -- Store wait ack
		     NC_LOAD_WAIT_ACK);-- Non-cachable load wait ack


    --
    -- Dcache operations:
    --
    -- In order to make timing, we use the BRAMs with an output buffer,
    -- which means that the BRAM output is delayed by an extra cycle.
    --
    -- Thus, the dcache has a 2-stage internal pipeline for cache hits
    -- with no stalls.
    --
    -- All other operations are handled via stalling in the first stage.
    --
    -- The second stage can thus complete a hit at the same time as the
    -- first stage emits a stall for a complex op.
    --

    -- First stage register, contains state for stage 1 of load hits
    -- and for the state machine used by all other operations
    --
    type reg_stage_1_t is record
	-- Latch the complete request from ls1
	req              : Loadstore1ToDcacheType;

	-- Cache hit state
	hit_way          : way_t;
	hit_load_valid   : std_ulogic;

	-- Data buffer for "slow" read ops (load miss and NC loads).
	slow_data        : std_ulogic_vector(63 downto 0);
	slow_valid       : std_ulogic;

        -- Signal to complete a failed stcx.
        stcx_fail        : std_ulogic;

	-- Cache miss state (reload state machine)
        state            : state_t;
        wb               : wishbone_master_out;
	store_way        : way_t;
	store_row        : row_t;
        store_index      : index_t;
    end record;

    signal r1 : reg_stage_1_t;

    -- Reservation information
    --
    type reservation_t is record
        valid : std_ulogic;
        addr  : std_ulogic_vector(63 downto LINE_OFF_BITS);
    end record;

    signal reservation : reservation_t;

    -- Async signals on incoming request
    signal req_index   : index_t;
    signal req_row     : row_t;
    signal req_hit_way : way_t;
    signal req_tag     : cache_tag_t;
    signal req_op      : op_t;
    signal req_data    : std_ulogic_vector(63 downto 0);
    signal req_laddr   : std_ulogic_vector(63 downto 0);

    signal early_req_row  : row_t;

    signal cancel_store : std_ulogic;
    signal set_rsrv     : std_ulogic;
    signal clear_rsrv   : std_ulogic;

    -- Cache RAM interface
    type cache_ram_out_t is array(way_t) of cache_row_t;
    signal cache_out   : cache_ram_out_t;

    -- PLRU output interface
    type plru_out_t is array(index_t) of std_ulogic_vector(WAY_BITS-1 downto 0);
    signal plru_victim : plru_out_t;
    signal replace_way : way_t;

    -- Wishbone read/write/cache write formatting signals
    signal bus_sel     : std_ulogic_vector(7 downto 0);

    --
    -- Helper functions to decode incoming requests
    --

    -- Return the cache line index (tag index) for an address
    function get_index(addr: std_ulogic_vector(63 downto 0)) return index_t is
    begin
        return to_integer(unsigned(addr(63-TAG_BITS downto LINE_OFF_BITS)));
    end;

    -- Return the cache row index (data memory) for an address
    function get_row(addr: std_ulogic_vector(63 downto 0)) return row_t is
    begin
        return to_integer(unsigned(addr(63-TAG_BITS downto ROW_OFF_BITS)));
    end;

    -- Returns whether this is the last row of a line
    function is_last_row_addr(addr: wishbone_addr_type) return boolean is
	constant ones : std_ulogic_vector(ROW_LINEBITS-1 downto 0) := (others => '1');
    begin
	return addr(LINE_OFF_BITS-1 downto ROW_OFF_BITS) = ones;
    end;

    -- Returns whether this is the last row of a line
    function is_last_row(row: row_t) return boolean is
	variable row_v : std_ulogic_vector(ROW_BITS-1 downto 0);
	constant ones  : std_ulogic_vector(ROW_LINEBITS-1 downto 0) := (others => '1');
    begin
	row_v := std_ulogic_vector(to_unsigned(row, ROW_BITS));
	return row_v(ROW_LINEBITS-1 downto 0) = ones;
    end;

    -- Return the address of the next row in the current cache line
    function next_row_addr(addr: wishbone_addr_type) return std_ulogic_vector is
	variable row_idx : std_ulogic_vector(ROW_LINEBITS-1 downto 0);
	variable result  : wishbone_addr_type;
    begin
	-- Is there no simpler way in VHDL to generate that 3 bits adder ?
	row_idx := addr(LINE_OFF_BITS-1 downto ROW_OFF_BITS);
	row_idx := std_ulogic_vector(unsigned(row_idx) + 1);
	result := addr;
	result(LINE_OFF_BITS-1 downto ROW_OFF_BITS) := row_idx;
	return result;
    end;

    -- Return the next row in the current cache line. We use a dedicated
    -- function in order to limit the size of the generated adder to be
    -- only the bits within a cache line (3 bits with default settings)
    --
    function next_row(row: row_t) return row_t is
       variable row_v  : std_ulogic_vector(ROW_BITS-1 downto 0);
       variable row_idx : std_ulogic_vector(ROW_LINEBITS-1 downto 0);
       variable result : std_ulogic_vector(ROW_BITS-1 downto 0);
    begin
       row_v := std_ulogic_vector(to_unsigned(row, ROW_BITS));
       row_idx := row_v(ROW_LINEBITS-1 downto 0);
       row_v(ROW_LINEBITS-1 downto 0) := std_ulogic_vector(unsigned(row_idx) + 1);
       return to_integer(unsigned(row_v));
    end;

    -- Get the tag value from the address
    function get_tag(addr: std_ulogic_vector(63 downto 0)) return cache_tag_t is
    begin
        return addr(63 downto 64-TAG_BITS);
    end;

    -- Read a tag from a tag memory row
    function read_tag(way: way_t; tagset: cache_tags_set_t) return cache_tag_t is
    begin
	return tagset((way+1) * TAG_BITS - 1 downto way * TAG_BITS);
    end;

    -- Write a tag to tag memory row
    procedure write_tag(way: in way_t; tagset: inout cache_tags_set_t;
			tag: cache_tag_t) is
    begin
	tagset((way+1) * TAG_BITS - 1 downto way * TAG_BITS) := tag;
    end;

begin

    assert LINE_SIZE mod ROW_SIZE = 0 report "LINE_SIZE not multiple of ROW_SIZE" severity FAILURE;
    assert ispow2(LINE_SIZE)    report "LINE_SIZE not power of 2" severity FAILURE;
    assert ispow2(NUM_LINES)    report "NUM_LINES not power of 2" severity FAILURE;
    assert ispow2(ROW_PER_LINE) report "ROW_PER_LINE not power of 2" severity FAILURE;
    assert (ROW_BITS = INDEX_BITS + ROW_LINEBITS)
	report "geometry bits don't add up" severity FAILURE;
    assert (LINE_OFF_BITS = ROW_OFF_BITS + ROW_LINEBITS)
	report "geometry bits don't add up" severity FAILURE;
    assert (64 = TAG_BITS + INDEX_BITS + LINE_OFF_BITS)
	report "geometry bits don't add up" severity FAILURE;
    assert (64 = TAG_BITS + ROW_BITS + ROW_OFF_BITS)
	report "geometry bits don't add up" severity FAILURE;
    assert (64 = wishbone_data_bits)
	report "Can't yet handle a wishbone width that isn't 64-bits" severity FAILURE;

    -- Generate PLRUs
    maybe_plrus: if NUM_WAYS > 1 generate
    begin
	plrus: for i in 0 to NUM_LINES-1 generate
	    -- PLRU interface
	    signal plru_acc    : std_ulogic_vector(WAY_BITS-1 downto 0);
	    signal plru_acc_en : std_ulogic;
	    signal plru_out    : std_ulogic_vector(WAY_BITS-1 downto 0);

	begin
	    plru : entity work.plru
		generic map (
		    BITS => WAY_BITS
		    )
		port map (
		    clk => clk,
		    rst => rst,
		    acc => plru_acc,
		    acc_en => plru_acc_en,
		    lru => plru_out
		    );

	    process(req_index, req_op, req_hit_way, plru_out)
	    begin
		-- PLRU interface
		if (req_op = OP_LOAD_HIT or
		    req_op = OP_STORE_HIT) and req_index = i then
		    plru_acc_en <= '1';
		else
		    plru_acc_en <= '0';
		end if;
		plru_acc <= std_ulogic_vector(to_unsigned(req_hit_way, WAY_BITS));
		plru_victim(i) <= plru_out;
	    end process;
	end generate;
    end generate;

    -- Latch the request in r0 as long as we're not stalling
    stage_0 : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r0.valid <= '0';
            elsif stall_out = '0' then
                r0 <= d_in;
            end if;
        end if;
    end process;

    -- Cache request parsing and hit detection
    dcache_request : process(all)
	variable is_hit  : std_ulogic;
	variable hit_way : way_t;
	variable op      : op_t;
        variable tmp     : std_ulogic_vector(63 downto 0);
        variable data    : std_ulogic_vector(63 downto 0);
	variable opsel   : std_ulogic_vector(3 downto 0);
        variable go      : std_ulogic;
    begin
	-- Extract line, row and tag from request
        req_index <= get_index(r0.addr);
        req_row <= get_row(r0.addr);
        req_tag <= get_tag(r0.addr);

        -- Only do anything if not being stalled by stage 1
        go := r0.valid and not stall_out;

        -- Calculate address of beginning of cache line, will be
        -- used for cache miss processing if needed
        --
        req_laddr <= r0.addr(63 downto LINE_OFF_BITS) &
                     (LINE_OFF_BITS-1 downto 0 => '0');

	-- Test if pending request is a hit on any way
	hit_way := 0;
	is_hit := '0';
	for i in way_t loop
	    if go = '1' and cache_valids(req_index)(i) = '1' then
		if read_tag(i, cache_tags(req_index)) = req_tag then
		    hit_way := i;
		    is_hit := '1';
		end if;
	    end if;
	end loop;

	-- The way that matched on a hit
	req_hit_way <= hit_way;

	-- The way to replace on a miss
	replace_way <= to_integer(unsigned(plru_victim(req_index)));

	-- Combine the request and cache his status to decide what
	-- operation needs to be done
	--
	opsel := go & r0.load & r0.nc & is_hit;
	case opsel is
	when "1101" => op := OP_LOAD_HIT;
	when "1100" => op := OP_LOAD_MISS;
	when "1110" => op := OP_LOAD_NC;
	when "1001" => op := OP_STORE_HIT;
	when "1000" => op := OP_STORE_MISS;
	when "1010" => op := OP_STORE_MISS;
	when "1011" => op := OP_BAD;
	when "1111" => op := OP_BAD;
	when others => op := OP_NONE;
	end case;

	req_op <= op;

        -- Version of the row number that is valid one cycle earlier
        -- in the cases where we need to read the cache data BRAM.
        -- If we're stalling then we need to keep reading the last
        -- row requested.
        if stall_out = '0' then
            early_req_row <= get_row(d_in.addr);
        else
            early_req_row <= req_row;
        end if;
    end process;

    -- Wire up wishbone request latch out of stage 1
    wishbone_out <= r1.wb;

   -- TODO: Generate errors
   -- err_nc_collision <= '1' when req_op = OP_BAD else '0';

    -- Generate stalls from stage 1 state machine
    stall_out <= '1' when r1.state /= IDLE else '0';

    -- Handle load-with-reservation and store-conditional instructions
    reservation_comb: process(all)
    begin
        cancel_store <= '0';
        set_rsrv <= '0';
        clear_rsrv <= '0';
        if stall_out = '0' and r0.valid = '1' and r0.reserve = '1' then
            -- XXX generate alignment interrupt if address is not aligned
            -- XXX or if r0.nc = '1'
            if r0.load = '1' then
                -- load with reservation
                set_rsrv <= '1';
            else
                -- store conditional
                clear_rsrv <= '1';
                if reservation.valid = '0' or
                    r0.addr(63 downto LINE_OFF_BITS) /= reservation.addr then
                    cancel_store <= '1';
                end if;
            end if;
        end if;
    end process;

    reservation_reg: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' or clear_rsrv = '1' then
                reservation.valid <= '0';
            elsif set_rsrv = '1' then
                reservation.valid <= '1';
                reservation.addr <= r0.addr(63 downto LINE_OFF_BITS);
            end if;
        end if;
    end process;

    -- Return data for loads & completion control logic
    --
    writeback_control: process(all)
    begin

	-- The mux on d_out.data defaults to the normal load hit case.
	d_out.valid <= '0';
	d_out.data <= cache_out(r1.hit_way);
        d_out.store_done <= '0';

	-- We have a valid load or store hit or we just completed a slow
	-- op such as a load miss, a NC load or a store
	--
	-- Note: the load hit is delayed by one cycle. However it can still
	-- not collide with r.slow_valid (well unless I miscalculated) because
	-- slow_valid can only be set on a subsequent request and not on its
	-- first cycle (the state machine must have advanced), which makes
	-- slow_valid at least 2 cycles from the previous hit_load_valid.
	--

	-- Sanity: Only one of these must be set in any given cycle
	assert (r1.slow_valid and r1.stcx_fail) /= '1' report
	    "unexpected slow_valid collision with stcx_fail"
	    severity FAILURE;
	assert ((r1.slow_valid or r1.stcx_fail) and r1.hit_load_valid) /= '1' report
	    "unexpected hit_load_delayed collision with slow_valid"
	    severity FAILURE;

	-- Load hit case is the standard path
	if r1.hit_load_valid = '1' then
            report "completing load hit";
            d_out.valid <= '1';
	end if;

	-- Slow ops (load miss, NC, stores)
	if r1.slow_valid = '1' then
	    -- If it's a load, enable register writeback and switch
	    -- mux accordingly
	    --
	    if r1.req.load then
		-- Read data comes from the slow data latch
		d_out.data <= r1.slow_data;
	    end if;
            d_out.store_done <= '1';

            report "completing store or load miss";
            d_out.valid <= '1';
	end if;

        if r1.stcx_fail = '1' then
            d_out.store_done <= '0';
            d_out.valid <= '1';
        end if;

    end process;

    --
    -- Generate a cache RAM for each way. This handles the normal
    -- reads, writes from reloads and the special store-hit update
    -- path as well.
    --
    -- Note: the BRAMs have an extra read buffer, meaning the output
    --       is pipelined an extra cycle. This differs from the
    --       icache. The writeback logic needs to take that into
    --       account by using 1-cycle delayed signals for load hits.
    --
    rams: for i in 0 to NUM_WAYS-1 generate
	signal do_read  : std_ulogic;
	signal rd_addr  : std_ulogic_vector(ROW_BITS-1 downto 0);
	signal do_write : std_ulogic;
	signal wr_addr  : std_ulogic_vector(ROW_BITS-1 downto 0);
	signal wr_data  : std_ulogic_vector(wishbone_data_bits-1 downto 0);
	signal wr_sel   : std_ulogic_vector(ROW_SIZE-1 downto 0);
	signal dout     : cache_row_t;
    begin
	way: entity work.cache_ram
	    generic map (
		ROW_BITS => ROW_BITS,
		WIDTH => wishbone_data_bits,
		ADD_BUF => true
		)
	    port map (
		clk     => clk,
		rd_en   => do_read,
		rd_addr => rd_addr,
		rd_data => dout,
		wr_en   => do_write,
		wr_sel  => wr_sel,
		wr_addr => wr_addr,
		wr_data => wr_data
		);
	process(all)
	    variable tmp_adr   : std_ulogic_vector(63 downto 0);
	    variable reloading : boolean;
	begin
	    -- Cache hit reads
	    do_read <= '1';
	    rd_addr <= std_ulogic_vector(to_unsigned(early_req_row, ROW_BITS));
	    cache_out(i) <= dout;

	    -- Write mux:
	    --
	    -- Defaults to wishbone read responses (cache refill),
	    --
	    -- For timing, the mux on wr_data/sel/addr is not dependent on anything
	    -- other than the current state. Only the do_write signal is.
	    --
	    if r1.state = IDLE then
		-- In IDLE state, the only write path is the store-hit update case
		wr_addr  <= std_ulogic_vector(to_unsigned(req_row, ROW_BITS));
		wr_data  <= r0.data;
		wr_sel   <= r0.byte_sel;
	    else
		-- Otherwise, we might be doing a reload
		wr_data <= wishbone_in.dat;
		wr_sel  <= (others => '1');
		wr_addr <= std_ulogic_vector(to_unsigned(r1.store_row, ROW_BITS));
	    end if;

	    -- The two actual write cases here
	    do_write <= '0';
	    reloading := r1.state = RELOAD_WAIT_ACK;
	    if reloading and wishbone_in.ack = '1' and r1.store_way = i then
		do_write <= '1';
	    end if;
	    if req_op = OP_STORE_HIT and req_hit_way = i and cancel_store = '0' then
		assert not reloading report "Store hit while in state:" &
		    state_t'image(r1.state)
		    severity FAILURE;
		do_write <= '1';
	    end if;
	end process;
    end generate;

    --
    -- Cache hit synchronous machine for the easy case. This handles load hits.
    --
    dcache_fast_hit : process(clk)
    begin
        if rising_edge(clk) then
	    -- If we have a request incoming, we have to latch it as r0.valid
	    -- is only set for a single cycle. It's up to the control logic to
	    -- ensure we don't override an uncompleted request (for now we are
	    -- single issue on load/stores so we are fine, later, we can generate
	    -- a stall output if necessary).

	    if req_op /= OP_NONE and stall_out = '0' then
		r1.req <= r0;
		report "op:" & op_t'image(req_op) &
		    " addr:" & to_hstring(r0.addr) &
		    " nc:" & std_ulogic'image(r0.nc) &
		    " idx:" & integer'image(req_index) &
		    " tag:" & to_hstring(req_tag) &
		    " way: " & integer'image(req_hit_way);
	    end if;

	    -- Fast path for load/store hits. Set signals for the writeback controls.
	    if req_op = OP_LOAD_HIT then
		r1.hit_way <= req_hit_way;
		r1.hit_load_valid <= '1';
	    else
		r1.hit_load_valid <= '0';
	    end if;
	end if;
    end process;

    --
    -- Every other case is handled by this state machine:
    --
    --   * Cache load miss/reload (in conjunction with "rams")
    --   * Load hits for non-cachable forms
    --   * Stores (the collision case is handled in "rams")
    --
    -- All wishbone requests generation is done here. This machine
    -- operates at stage 1.
    --
    dcache_slow : process(clk)
	variable tagset    : cache_tags_set_t;
	variable stbs_done : boolean;
    begin
        if rising_edge(clk) then
	    -- On reset, clear all valid bits to force misses
            if rst = '1' then
		for i in index_t loop
		    cache_valids(i) <= (others => '0');
		end loop;
                r1.state <= IDLE;
		r1.slow_valid <= '0';
                r1.wb.cyc <= '0';
                r1.wb.stb <= '0';

		-- Not useful normally but helps avoiding tons of sim warnings
		r1.wb.adr <= (others => '0');
            else
		-- One cycle pulses reset
		r1.slow_valid <= '0';
                r1.stcx_fail <= '0';

		-- Main state machine
		case r1.state is
                when IDLE =>
		    case req_op is
                    when OP_LOAD_HIT =>
                        -- stay in IDLE state

                    when OP_LOAD_MISS =>
			-- Normal load cache miss, start the reload machine
			--
			report "cache miss addr:" & to_hstring(r0.addr) &
			    " idx:" & integer'image(req_index) &
			    " way:" & integer'image(replace_way) &
			    " tag:" & to_hstring(req_tag);

			-- Force misses on that way while reloading that line
			cache_valids(req_index)(replace_way) <= '0';

			-- Store new tag in selected way
			for i in 0 to NUM_WAYS-1 loop
			    if i = replace_way then
				tagset := cache_tags(req_index);
				write_tag(i, tagset, req_tag);
				cache_tags(req_index) <= tagset;
			    end if;
			end loop;

			-- Keep track of our index and way for subsequent stores.
			r1.store_index <= req_index;
			r1.store_way <= replace_way;
			r1.store_row <= get_row(req_laddr);

			-- Prep for first wishbone read. We calculate the address of
			-- the start of the cache line and start the WB cycle
			--
			r1.wb.adr <= req_laddr(r1.wb.adr'left downto 0);
			r1.wb.sel <= (others => '1');
			r1.wb.we  <= '0';
			r1.wb.cyc <= '1';
			r1.wb.stb <= '1';

			-- Track that we had one request sent
			r1.state <= RELOAD_WAIT_ACK;

		    when OP_LOAD_NC =>
                        r1.wb.sel <= r0.byte_sel;
                        r1.wb.adr <= r0.addr(r1.wb.adr'left downto 3) & "000";
                        r1.wb.cyc <= '1';
                        r1.wb.stb <= '1';
			r1.wb.we <= '0';
			r1.state <= NC_LOAD_WAIT_ACK;

		    when OP_STORE_HIT | OP_STORE_MISS =>
                        r1.wb.sel <= r0.byte_sel;
                        r1.wb.adr <= r0.addr(r1.wb.adr'left downto 3) & "000";
			r1.wb.dat <= r0.data;
                        if cancel_store = '0' then
                            r1.wb.cyc <= '1';
                            r1.wb.stb <= '1';
                            r1.wb.we <= '1';
                            r1.state <= STORE_WAIT_ACK;
                        else
                            r1.stcx_fail <= '1';
                            r1.state <= IDLE;
                        end if;

		    -- OP_NONE and OP_BAD do nothing
		    when OP_NONE =>
		    when OP_BAD =>
		    end case;

		when RELOAD_WAIT_ACK =>
		    -- Requests are all sent if stb is 0
		    stbs_done := r1.wb.stb = '0';

		    -- If we are still sending requests, was one accepted ?
		    if wishbone_in.stall = '0' and not stbs_done then
			-- That was the last word ? We are done sending. Clear
			-- stb and set stbs_done so we can handle an eventual last
			-- ack on the same cycle.
			--
			if is_last_row_addr(r1.wb.adr) then
			    r1.wb.stb <= '0';
			    stbs_done := true;
			end if;

			-- Calculate the next row address
			r1.wb.adr <= next_row_addr(r1.wb.adr);
		    end if;

		    -- Incoming acks processing
		    if wishbone_in.ack = '1' then
			-- Is this the data we were looking for ? Latch it so
			-- we can respond later. We don't currently complete the
			-- pending miss request immediately, we wait for the
			-- whole line to be loaded. The reason is that if we
			-- did, we would potentially get new requests in while
			-- not idle, which we don't currently know how to deal
			-- with.
			--
			if r1.store_row = get_row(r1.req.addr) then
			    r1.slow_data <= wishbone_in.dat;
			end if;

			-- Check for completion
			if stbs_done and is_last_row(r1.store_row) then
			    -- Complete wishbone cycle
			    r1.wb.cyc <= '0';

			    -- Cache line is now valid
			    cache_valids(r1.store_index)(r1.store_way) <= '1';

                            -- Don't complete and go idle until next cycle, in
                            -- case the next request is for the last dword of
                            -- the cache line we just loaded.
                            r1.state <= FINISH_LD_MISS;
			end if;

			-- Increment store row counter
			r1.store_row <= next_row(r1.store_row);
		    end if;

                when FINISH_LD_MISS =>
                    -- Write back the load data that we got
                    r1.slow_valid <= '1';
                    r1.state <= IDLE;
                    report "completing miss !";

                when STORE_WAIT_ACK | NC_LOAD_WAIT_ACK =>
		    -- Clear stb when slave accepted request
                    if wishbone_in.stall = '0' then
			r1.wb.stb <= '0';
		    end if;

		    -- Got ack ? complete.
		    if wishbone_in.ack = '1' then
			if r1.state = NC_LOAD_WAIT_ACK then
			    r1.slow_data <= wishbone_in.dat;
			end if;
                        r1.state <= IDLE;
			r1.slow_valid <= '1';
			r1.wb.cyc <= '0';
			r1.wb.stb <= '0';
		    end if;
                end case;
	    end if;
	end if;
    end process;
end;
