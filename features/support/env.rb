require 'aruba/cucumber'
require 'fileutils'
require 'ruby-debug'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
ENV['GLI_DEBUG'] = 'true'

Before do
  #@dirs = [".", "tmp/aruba"]
  @real_hostname = ENV['HOSTNAME']
  @aruba_timeout_seconds = 360

  #@real_home = ENV['HOME']
  #fake_home = File.join('/tmp','fake_home')
  #FileUtils.rm_rf fake_home, :secure => true
  #ENV['HOME'] = fake_home

  @original_config_file = ENV.delete 'SMITHY_CONFIG'
end

After do
  #ENV['HOME'] = @real_home
  #config_file = File.join('/tmp','.todo.rc.yaml')
  #FileUtils.rm config_file if File.exists? config_file

  if @real_hostname
    ENV['HOSTNAME'] = @real_hostname
  end

  if @temp_swroot
    FileUtils.rm_rf @temp_swroot if File.exists? @temp_swroot
  end

  if @config_backup
    FileUtils.cp "etc/smithyrc.original", "etc/smithyrc"
  end

  if @original_config_file
    ENV['SMITHY_CONFIG'] = @original_config_file
  end
end
