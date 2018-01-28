module Taipo
  class TypeElement

    # A collection of Taipo::TypeElement
    # @since 1.0.0
    # @api private
    class ChildType < Array

      # Initialize a new collection
      #
      # @note The +components+ argument is two-dimensional array because the
      #   element returned by an enumerator for a collection can consist of
      #   multiple elements (eg. a Hash, where it consists of two elements).
      #
      # @param components [Array<Array<Taipo::TypeElement>>] the components that
      #   will make up the ChildType
      #
      # @since 1.0.0
      # @api private
      def initialize(components = nil)
        components.each { |c| self.push c } unless components.nil?
      end

      # Return the String representation of this ChildType
      #
      # @since 1.1.0
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

