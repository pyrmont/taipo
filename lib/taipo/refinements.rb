module Taipo

  # Refinements on core classes used in Taipo
  #
  # @since 1.4.0
  # @api private
  module Refinements

    # Refinements to String
    #
    # @since 1.4.0
    # @api private
    refine String do

      # Check if the string represents a bare constraint
      #
      # Taipo allows certain bare constraints to be written in type
      # definitions. A bare constraint can be either an instance method
      # or a symbol.
      #
      # @return [Boolean] the result
      #
      # @since 1.4.0
      # @api private
      def bare_constraint?
        self[0] == ':' || self[0] == '#'
      end
    end
  end
end
