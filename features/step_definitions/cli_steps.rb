Given /^an empty software root in "([^"]*)"$/ do |swroot|
  FileUtils.mkdir(swroot) unless File.directory?(swroot)
  @swroot = swroot
end

Given /^my architecture is set to "([^"]*)"$/ do |arch|
  @arch = arch
  @full_swroot = File.join(@swroot, arch)
  FileUtils.mkdir(@full_swroot) unless File.directory?(@full_swroot)
end

Given /^my config file contains:$/ do |string|
  config = "etc/smithyrc"
  @config_backup = "etc/smithyrc.backup"
  FileUtils.cp config, @config_backup
  File.open(config, "w+") do |file|
    file.puts string
    #file.readlines do |line|
      #puts line.upcase
    #end
  end
end
