# Smithy is freely available under the terms of the BSD license given below. {{{
#
# Copyright (c) 2012. UT-BATTELLE, LLC. All rights reserved.
#
# Produced by the National Center for Computational Sciences at Oak Ridge
# National Laboratory. Smithy is a based on SWTools, more information on SWTools
# can be found at: http://www.olcf.ornl.gov/center-projects/swtools/
#
# This product includes software produced by UT-Battelle, LLC under Contract No.
# DE-AC05-00OR22725 with the Department of Energy.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# - Neither the name of the UT-BATTELLE nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# }}}

module Smithy
  class Config
    class << self
      attr_accessor :config_file_name, :config_file_hash, :global, :hostname,
        :arch, :root, :full_root, :web_root, :file_group, :descriptions_root,
        :web_architecture_names

      def group_writable?
        @global[:"disable-group-writable"] ? false : true
      end

      def load_configuration(gli_options = {})
        @global = gli_options
        options_to_merge = {}
        load_config_yaml

        return nil unless @config_file_hash

        # Pick some values from the config file
        options_to_merge[:"software-root"]   = @config_file_hash.try(:[], "software-root")
        options_to_merge[:"web-root"]        = @config_file_hash.try(:[], "web-root")
        options_to_merge[:"file-group-name"] = @config_file_hash.try(:[], "file-group-name")
        options_to_merge[:"descriptions-root"] = @config_file_hash.try(:[], "descriptions-root")
        options_to_merge[:"web-architecture-names"] = @config_file_hash.try(:[], "web-architecture-names")
        options_to_merge[:"download-cache"] = @config_file_hash.try(:[], "download-cache")
        options_to_merge[:"formula-directories"] = @config_file_hash.try(:[], "formula-directories")
        options_to_merge[:"global-error-log"] = @config_file_hash.try(:[], "global-error-log")

        set_hostname_and_arch
        options_to_merge[:arch] = @arch
        # options_to_merge[:"prgenv-prefix"] = get_prgenv_prefix

        # Merge the config file values with command line values,
        # options on the command line take precedence.
        @global.merge!(options_to_merge) do |key, values_command_line, values_config|
          if values_command_line.nil?
            values_config
          else
            values_command_line
          end
        end

        @arch = @global[:arch]
        @root = @global[:"software-root"]
        @file_group = @global[:"file-group-name"]
        @full_root = get_software_root
        @web_root = @global[:"web-root"]
        @descriptions_root = @global[:"descriptions-root"]
        @web_architecture_names = @global[:"web-architecture-names"]

        # Add new info
        @global[:full_software_root_path] = @full_root
        @global[:"file-group-id"]   = Etc.getgrnam(options_to_merge[:"file-group-name"]).try(:gid) if @global[:"file-group-name"]
      end

      def load_config_yaml
        config_path = File.expand_path(ENV['SMITHY_CONFIG']) if ENV['SMITHY_CONFIG']
        config_path = File.expand_path(global[:"config-file"]) if global[:"config-file"]

        if config_path.present? && File.exists?(config_path)
          @config_file_name = config_path
          begin
            @config_file_hash = YAML.load_file(config_path).stringify_keys
          rescue
            raise """Cannot interpret smithy config file. This is probably caused by malformed YAML.
       #{config_path}"""
          end
        else
          raise """Cannot read config file: #{@config_file_name}
       Please set the $SMITHY_CONFIG variable to a config file location
       Or use the --config-file=FILE option"""
        end
      end

      def architectures(options)
        if options[:all]
          puts @config_file_hash["hostname-architectures"].values.uniq.sort.join(" ")
        else
          notice_command "Current Hostname: ", @hostname, 30
          notice_command "Current Architecture: ", @arch, 30
          notice_command "All Architectures: ", @config_file_hash["hostname-architectures"].values.uniq.sort.join(", "), 30
        end
      end

      def compilers
        config_file_hash.try(:[], "compilers")
      end

      # def get_prgenv_prefix
      #   default_prefix = "PrgEnv-"

      #   default_prefix_from_config = @config_file_hash.try(:[], "programming-environment-prefix").try(:[], "default")
      #   default_prefix = default_prefix_from_config unless default_prefix_from_config.blank?

      #   prefix_from_config = @config_file_hash.try(:[], "programming-environment-prefix").try(:[], @arch)

      #   return prefix_from_config unless prefix_from_config.blank?

      #   return default_prefix
      # end

      def set_hostname_and_arch
        @hostname ||= ENV.try(:[], 'HOSTNAME').try(:dup)
        @hostname ||= `hostname -s`.try(:dup)
        @hostname.chomp!
        # Remove trailing numbers (if they exist) and a possible single trailing period
        @hostname.gsub!(/\.?$/,'')
        machine = @hostname.gsub(/(\d*)$/,'')

        @arch = global[:arch] if @arch.nil?
        @arch = @config_file_hash.try(:[], "hostname-architectures").try(:[], machine) if @arch.nil?
        @arch = @config_file_hash.try(:[], "hostname-architectures").try(:[], @hostname) if @arch.nil?
      end

      def get_software_root
        if @root.blank? || @arch.blank?
          raise """Cannot determine which architecture we are using.
       Please specify using --arch or add a '#{@hostname}' hostname entry to:
       #{@config_file_name}"""
        end

        s = File.join(@root, @arch)
        raise "The software-root directory '#{s}' does not exist" unless Dir.exist?(s)
        return s
      end

      def homedir
        @homedir ||= File.join(Dir.home(Etc.getlogin))
        @homedir
      end

      def last_prefix
        rc_file = File.join(homedir, '.smithyrc')
        if File.exists?(rc_file)
          h = YAML.load_file(rc_file).stringify_keys rescue nil
          return h["last"]
        else
          return nil
        end
      end

      def save_last_prefix(prefix)
        rc_file = File.join(homedir, '.smithyrc')
        h = {:last => prefix.encode('UTF-8')}
        File.open(rc_file, "w+") do |f|
          f.write(h.to_yaml)
        end
      end

      def reindex_completion_caches
        notice "Reindexing packages"
        FormulaCommand.initialize_directories
        formulas = FormulaCommand.formula_names
        packages = Package.all.collect{|s| s.gsub(/#{full_root}\//, '')}

        FileUtils.mkdir_p(File.join(homedir, ".smithy"))

        File.open(File.join(homedir, ".smithy", "completion_formulas"), "w+") do |f|
          f.puts formulas
        end
        File.open(File.join(homedir, ".smithy", "completion_packages"), "w+") do |f|
          f.puts packages
        end
        File.open(File.join(homedir, ".smithy", "completion_arches"), "w+") do |f|
          f.puts @config_file_hash["hostname-architectures"].values.uniq.sort
        end
      end

      def example_config
        example = {}
        example["software-root"]       = "/sw"
        example["download-cache"]      = "/sw/sources"
        example["formula-directories"] = [
          "/sw/tools/smithy/formulas",
          "/sw/tools/smithy/another_formula_directory"
        ]
        example["global-error-log"]    = "/sw/tools/smithy/exceptions.log"
        example["file-group-name"]        = "ccsstaff"
        example["descriptions-root"]      = "/sw/descriptions"
        example["web-root"]               = "/sw/descriptions_in_html"
        example["web-architecture-names"] = {
          "xk6"          => "titan",
          "xk7"          => "titan",
          "analysis-x64" => "lens",
          "smoky"        => "smoky"
        }
        # example["programming-environment-prefix"] = {
        #   "default" => "PrgEnv-",
        #   "smoky"   => "PE-",
        #   "sith"    => "PE-"
        # }
        example["hostname-architectures"] = {
          "everest-login" => "redhat6",
          "everest"       => "redhat6",
          "lens"          => "analysis-x64",
          "sith-login"    => "redhat6",
          "sith"          => "redhat6",
          "smoky-login"   => "smoky",
          "titan-login"   => "xk6",
          "titan-ext"     => "xk6",
          "yona-login"    => "yona",
          "yona"          => "yona"
        }
        example["compilers"] = ModuleFile::Environments

        return example.to_yaml
      end

    end
  end
end
