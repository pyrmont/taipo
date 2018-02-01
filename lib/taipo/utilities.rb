module Taipo

  # Utility methods for Taipo
  #
  # @since 1.4.0
  # @api private
  module Utilities

    # Check if a string is the name of an instance method
    #
    # @note All this does is check whether the given string begins with a hash
    #   symbol.
    #
    # @param str [String] the string to check
    #
    # @return [Boolean] the result
    #
    # @since 1.4.0
    # @api private
    def self.instance_method?(str)
      str[0] == '#'
    end

    # Return the type definition for an object
    #
    # @note This assume that each element returned by Enumerator#each has the same
    #   number of components.
    #
    # @param obj [Object] the object
    #
    # @return [String] a type definition of the object
    #
    # @since 1.4.0
    # @api private
    def self.object_to_type_def(obj)
      return obj.class.name unless obj.is_a? Enumerable

      if obj.is_a? Array
        element_types = Hash.new
        obj.each { |o| element_types[self.object_to_type_def(o)] = true }
        if element_types.empty?
          obj.class.name
        else
          obj.class.name + '<' + element_types.keys.join('|') + '>'
        end
      else
        element_types = Array.new
        obj.each.with_index do |element,index_e|
          element.each.with_index do |component,index_c|
            element_types[index_c] = Hash.new if index_e == 0
            c_type = self.object_to_type_def(component)
            element_types[index_c][c_type] = true
          end
        end
        inner = element_types.reduce('') do |memo,e|
          e_type = e.keys.join('|')
          (memo == '') ? e_type : memo + ',' + e_type
        end
        if element_types.empty?
          obj.class.name
        else
          obj.class.name + '<' + inner + '>'
        end
      end
    end

    # Check if a string is the name of a symbol
    #
    # @note All this does is check whether the given string begins with a colon.
    #
    # @param str [String] the string to check
    #
    # @return [Boolean] the result
    #
    # @since 1.4.0
    # @api private
    def self.symbol?(str)
      str[0] == ':'
    end
  end
end