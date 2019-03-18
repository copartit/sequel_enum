module Sequel
  module Plugins
    module Enum
      def self.apply(model, opts = OPTS)
      end

      module ClassMethods
        
        def enums
          @enums ||= {}
        end

        def enum(alias_method_name, values)
          if values.is_a? Hash
            values.each do |key,val|
              raise ArgumentError, "index should be a symbol, #{key} provided which it's a #{key.class}" unless key.is_a? Symbol
              raise ArgumentError, "value should be an integer or string, #{val} provided which is a #{val.class}" unless [Integer, String].include? val.class
            end
          elsif values.is_a? Array
            values = Hash[values.map.with_index { |v, i| [v, i] }]
          else
            raise ArgumentError, "#enum expects the second argument to be an array of symbols or a hash like { :symbol => integer }"
          end

          define_method "#{alias_method_name}=" do |value|
            val = self.class.enums[alias_method_name].assoc(value.to_sym)
            val ||= value if self.class.enums[alias_method_name].values.include?(value.to_s) # allow passing the code directly
            raise "No enum mapping was found for #{value}, make sure this key is defined in your enum" unless val

            actual_column = self.class::FIELD_MAPPING[alias_method_name]
            self[actual_column] = val&.last
          end

          define_method "#{alias_method_name}" do
            actual_column = self.class::FIELD_MAPPING[alias_method_name]
            val = self.class.enums[alias_method_name].rassoc(self[actual_column])
            val ? val.first : self[actual_column]
          end

          values.each do |key, value|
            define_method "#{key}?" do
              self.send(alias_method_name) == key
            end
          end

          self.enums[alias_method_name] = values
        end
      end
    end
  end
end
