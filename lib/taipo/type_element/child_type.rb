module Taipo
  class TypeElement

    # A collection of Taipo::TypeElement
    # @since 1.0.0
    # @api private
    class ChildType < Array

      # Initialize a new collection
      #
      # @param components [Array<Taipo::TypeElement>] the components that will make up the ChildType
      #
      # @since 1.0.0
      # @api private 
      def initialize(components = nil)
        components.each { |c| self.push c } unless components.nil?
      end
    end
  end
end

