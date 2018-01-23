module Taipo
  class TypeElement

    # A constraint on a type
    #
    # @since 1.0.0
    # @api private
    class Constraint
    
      # The identifier for an instance method
      #
      # @since 1.0.0
      # @api private
      METHOD = '#'

      # The name of the constraint
      #
      # @since 1.0.0
      # @api private
      attr_accessor :name

      # The value of the constraint
      #
      # @since 1.0.0
      # @api private
      attr_reader :value

      # Initialize a new constraint
      #
      # @param name [String|NilClass] the name of the constraint (if nil, this 
      #   is an instance method)
      # @param value [String|NilClass] the value of the constraint (sometimes a
      #   Constraint is initialized before the value is known)
      #
      # @raise [::TypeError] if +name+ or +value+ were of the wrong type, or 
      #   +value+ was not of the correct type for the type of constraint 
      # @raise [::ArgumentError] if +name+ was blank
      #
      # @since 1.0.0
      # @api private 
      def initialize(name: nil, value: nil)
        msg = 'Argument name was not nil or a String.'
        raise ::TypeError, msg unless name.nil? || name.is_a?(String)
        msg = 'Argument name was an empty string.'
        raise ::ArgumentError, msg if name&.empty?

        @name = if name.nil?
                  Constraint::METHOD
                elsif name == ':'
                  'val'
                else
                  name
                end
        @value = self.parse_value value
      end

      # Check if +arg+ is within this constraint
      #
      # @param arg [Object] the object to check
      #
      # @return [Boolean] the result
      #
      # @since 1.0.0
      # @api private
      def constrain?(arg)
        case @name
        when Constraint::METHOD
          arg.respond_to? @value
        when 'format'
          arg.is_a?(String) && arg =~ @value
        when 'len'
          arg.respond_to?('size') && arg.size == @value
        when 'max'
          if arg.is_a? Numeric
            arg <= @value
          else
            arg.respond_to?('size') && arg.size <= @value
          end
        when 'min'
          if arg.is_a? Numeric
            arg >= @value
          else
            arg.respond_to?('size') && arg.size >= @value
          end
        when 'val'
          if @value[0] == '"' && @value[-1] == '"'
            arg.to_s == @value.slice(1..-2)
          elsif arg.is_a? Symbol
            ":" + arg.to_s == @value
          else
            arg.to_s == @value
          end
        end
      end

      # Parse +v+ and convert to the appropriate form if necessary
      #
      # @param v [Object] the value
      #
      # @raise [::TypeError] if the value is not appropriate for this type of
      #   constraint
      #
      # @since 1.0.0
      # @api private
      def parse_value(v)
        return nil if v == nil

        case @name
        when Constraint::METHOD
          v
        when 'format'
          return v if v.is_a? Regexp
          msg = 'The value cannot be cast to a regular expression.'
          raise ::TypeError, msg unless v[0] == '/' && v[-1] == '/'
          Regexp.new v[1, v.length-2]
        when 'len', 'max', 'min'
          return v if v.is_a? Integer
          msg = 'The value cannot be cast to an Integer.'
          raise ::TypeError, msg unless v == v.to_i.to_s
          v.to_i
        when 'val'
          v
        end
      end

      # Return the String representation of this constraint
      #
      # @return [String] the String representation
      #
      # @since 1.0.0
      # @api private
      def to_s
        name_string = (@name == Constraint::METHOD) ? '#' : @name + ':'
        value_string = case @name
                       when Constraint::METHOD
                         @value
                       when 'format'
                         @value.inspect
                       when 'len', 'max', 'min', 'val'
                         @value.to_s
                       end
        name_string + value_string
      end

      # Set +v+ to be the value for this constraint
      #
      # @param v [Object] the value to set (this will be parsed using 
      #   {#parse_value})
      #
      # @raise [::TypeError] if the value is not appropriate for this type of
      #   constraint
      #
      # @since 1.0.0
      # @api private
      def value=(v)
        @value = self.parse_value v
      end
    end
  end
end
