module Taipo 
  
  # @since 1.4.0
  # @api private
  module Refinements
    
    # @since 1.4.0
    # @api private
    refine String do
      
      # @since 1.4.0
      # @api private
      def bare_constraint?
        self[0] == ':' || self[0] == '#'
      end
    end
  end
end
