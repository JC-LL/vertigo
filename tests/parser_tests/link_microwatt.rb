require "fileutils"

puts "=> linking microwatt VHDL codes"
mw_sources=Dir["../microwatt/*.vhdl"]
mw_sources.each do |source|
  basename=File.basename(source,".vhdl")
  link="test_microwatt_#{basename}.vhd"
  puts "creating link #{link}"
  FileUtils.ln_s(source,link)
end
