require 'pp'
require_relative '../lib/parser'

def test_all
  parser=Vertigo::Parser.new
  parser.verbose=false
  vhdl_files=Dir["./test_*.vhd"].sort
  nb_tests=vhdl_files.size
  passed=0
  vhdl_files.each do |test|
    puts "=> parsing #{test}"
    begin
      parser.parse(test)
      passed+=1
    rescue Exception => e
      color=test=="./test_MUST_fail.vhd" ? :green : :red
      message="[expected]" if color==:green
      puts "exception : #{e} #{message}".send(color)
      #puts e.backtrace
    end
  end
  passed+=1  # to account for MUST_FAIL.vhd
  puts "statistics".center(80,'=')
  puts "success rate : #{passed}/#{nb_tests}  #{100*passed/nb_tests}%"
  puts "="*80
end

if ARGV.any?
  parser=Vertigo::Parser.new(:verbose => true)
  parser.parse  ARGV.first
else
  test_all
end
