# Borrowed from Rails
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/object/try.rb
class Object
	def try(method, *args, &block)
		send(method, *args, &block)
	end
	remove_method :try
	alias_method :try, :__send__
end
class NilClass #:nodoc:
	def try(*args)
		nil
	end
end

module Smithy

	def notice(message)
		STDOUT.puts "==> "+message if STDOUT.tty?
	end

	def process_ouput(stdout, stderr, print_stdout = false, log_file = nil)
		unless stdout.empty?
			puts stdout if print_stdout
			log_file.puts stdout unless log_file.nil?
			stdout.replace("")
		end
		unless stderr.empty?
			puts stderr if print_stdout
			log_file.puts stderr unless log_file.nil?
			stderr.replace("")
		end
	end
end
