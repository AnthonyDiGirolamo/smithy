# require 'aruba/cucumber'
# require 'fileutils'
#
# ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
# ENV['GLI_DEBUG'] = 'true'
#
# Before do
#   @real_home = ENV['HOME']
#   fake_home = File.join('/tmp','fake_home')
#   FileUtils.rm_rf fake_home, :secure => true
#   ENV['HOME'] = fake_home
# end
#
# After do
#   ENV['HOME'] = @real_home
#   config_file = File.join('/tmp','.todo.rc.yaml')
#   FileUtils.rm config_file if File.exists? config_file
# end
