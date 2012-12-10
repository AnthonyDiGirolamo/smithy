module Smithy
  class Formula
    attr_accessor :package

    def initialize(args = {})
      if args[:package]
        @package = args[:package]
        @version = @package.version
        @name    = @package.name
        @prefix  = @package.prefix
      end
    end

    # DSL and instance methods

    %w{url homepage md5 version name prefix}.each do |attr|
      class_eval %Q{
        def self.#{attr}(value = nil, &block)
          if block_given?
            @#{attr} = block
          elsif value
            @#{attr} = value
          end

          @#{attr}
        end

        def #{attr}
          unless @#{attr}
            if self.class.#{attr}.is_a?(Proc)
              @#{attr} = instance_eval(&self.class.#{attr})
            else
              @#{attr} = self.class.#{attr}
            end
          end

          @#{attr}
        end
      }
    end

  end #class Formula
end #module Smithy
