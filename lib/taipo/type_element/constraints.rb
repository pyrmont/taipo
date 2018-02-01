require 'taipo/type_element/constraint'

module Taipo
  class TypeElement

    # A set of {Taipo::TypeElement::Constraint} objects
    #
    # @since 1.4.0
    # @api private
    class Constraints < Array

      # Initialize a new set of {Taipo::TypeElement::Constraint}
      #
      # @param els [Array<Taipo::TypeElement::Constraint>] the constraints
      #
      # @since 1.4.0
      # @api private
      def initialize(constraints = nil)
        constraints&.each { |c| self.push c }
      end

      # Return the String representation of this object
      #
      # @return [String] the representation as a String
      #
      # @since 1.4.0
      # @api private
      def to_s
        inner = self.reduce('') do |memo,c|
                  (memo == '') ? c.to_s : memo + ',' + c.to_s
                end
        '(' + inner + ')'
      end
    end
  end
end
