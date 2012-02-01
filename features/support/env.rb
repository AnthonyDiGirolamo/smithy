require 'aruba/cucumber'
require 'fileutils'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
ENV['GLI_DEBUG'] = 'true'

Before do
  @dirs = [".", "tmp/aruba"]
  @real_hostname = ENV['HOSTNAME']
  #@real_home = ENV['HOME']
  #fake_home = File.join('/tmp','fake_home')
  #FileUtils.rm_rf fake_home, :secure => true
  #ENV['HOME'] = fake_home
end

After do
  #ENV['HOME'] = @real_home
  #config_file = File.join('/tmp','.todo.rc.yaml')
  #FileUtils.rm config_file if File.exists? config_file

  if @real_hostname
    ENV['HOSTNAME'] = @real_hostname
  end

  if @swroot
    FileUtils.rm_rf @swroot if File.exists? @swroot
  end

  if @config_backup
    FileUtils.cp @config_backup, "etc/smithyrc"
    FileUtils.rm @config_backup
  end
end
