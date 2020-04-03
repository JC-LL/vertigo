entity test is
end entity;

architecture bhv of test is
begin

  reg_ctrl_out <= (63 downto 11 => '0', 10 downto  0 => reg_ctrl);

  -- from microwatt_dcache.vhd
  req_laddr <= r0.addr(63 downto LINE_OFF_BITS) & (LINE_OFF_BITS-1 downto 0 => '0');

  regs_t <= (1,2,3);
  regs_t <= (others => '0');
  regs_t <= ( (others => '0'), '0',"00" );
  regs_t <= ( (others => '0'), (others => '0'), '0',"00" );

end bhv;
