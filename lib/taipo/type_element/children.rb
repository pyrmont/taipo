module Taipo
  class TypeElement

    # A set of {Taipo::TypeElements} representing the types of the children of
    # a collection type
    #
    # @since 1.4.0
    # @api private
    class Children < Array

      # Initialize a new set of children
      #
      # @note The +children+ argument is an array of {Taipo::TypeElements}
      #   because the element returned by an enumerator for a collection can
      #   consist of multiple components (eg. in a Hash, where it consists of
      #   two elements).
      #
      # @param children [Array<Taipo::TypeElements>] the components that make
      #   up the children of the collection
      #
      # @since 1.4.0
      # @api private
      def initialize(children = nil)
        children&.each { |c| self.push c }
      end

      # Return the String representation of this object
      #
      # @return [String] the representation as a String
      #
      # @since 1.4.0
      # @api private
      def to_s
        inner = self.reduce(nil) do |memo_e,component|
                  el = component.reduce(nil) do |memo_c,c|
                         (memo_c.nil?) ? c.to_s : memo_c + '|' + c.to_s
                       end
                  (memo_e.nil?) ? el : memo_e + ',' + el
                end
        '<' + inner + '>'
      end
    end
  end
end

