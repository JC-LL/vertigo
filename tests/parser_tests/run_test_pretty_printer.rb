require 'colorize'
require 'fileutils'

require_relative '../../lib/vertigo/compiler'

GREEN_TICK   ="\u2713".encode('utf-8').green
RED_CROSS    ="\u2717".encode('utf-8').red
GREEN_CROSS  ="\u2717".encode('utf-8').green

def test_all
  compiler=Vertigo::Compiler.new(mute:true,pp_to_file:true)
  FileUtils.rm Dir.glob("*_pp.vhd")
  vhdl_files=Dir["./test_*.vhd"].sort
  #vhdl_files=Dir["./test_MUST_fail.vhd"].sort
  nb_tests=vhdl_files.size
  passed=0
  total_lines=0
  total_time=0

  vhdl_files.each do |test|
    total_lines+=nb_lines=IO.readlines(test).size
    print str="=> compiling #{test} "
    print "."*(60-str.length)
    start=Time.new
    result=RED_CROSS
    begin
      ok=compiler.compile(test)
      result=ok ? GREEN_TICK : RED_CROSS
      passed+=1
    rescue Exception => e
      must_fail= (test=="./test_MUST_fail.vhd")
      if must_fail
        result=GREEN_CROSS+ ""
      else
        result=RED_CROSS
      end
      #puts e.backtrace
    end

    finish=Time.new
    total_time+=duration=(finish-start)
    duration_s="#{duration.round(3)}".ljust(5,'0')+" s "+ nb_lines.to_s.rjust(6)+" lines"
    puts duration_s+" "+result
  end
  passed+=1  # to account for MUST_FAIL.vhd
  puts "[statistics]".center(80,'=')
  puts "lines        : #{total_lines}"
  puts "total time   : #{total_time.round(3)} s"
  puts "line / s     : #{(total_lines/total_time).round(1)}"
  puts "success rate : #{passed}/#{nb_tests}  #{100*passed/nb_tests}%"
  puts "="*80
end

puts "[Vertigo tester : parser,pp]".center(80,'=')
test_all
