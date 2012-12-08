module Smithy

  class Formula

    %w{url homepage md5}.each do |attr|
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

    # def self.url(value = nil, &block)
    #   if block_given?
    #     @url = block
    #   elsif value
    #     @url = value
    #   end

    #   @url
    # end

    # def url
    #   unless @url
    #     if self.class.url.is_a?(Proc)
    #       @url = instance_eval(&self.class.url)
    #     else
    #       @url = self.class.url
    #     end
    #   end

    #   @url
    # end

  end

end
