module Taipo

  # A cache of {Taipo::TypeElement} objects created from parsed type definitions
  #
  # @since 1.0.0
  # @api private
  module Cache

    # The hash that acts as the cache
    #
    # @since 1.0.0
    # @api private
    @@Cache = {}

    # Retrieve the {Taipo::TypeElement} object described by the type definition
    # from the cache
    #
    # @param k [String] the type definition
    #
    # @return [Taipo::TypeElement] if the type definition has been saved
    # @return [NilClass] if the type definition has not been saved
    #
    # @since 1.0.0
    # @api private
    def self.[](k)
      @@Cache[k]
    end

    # Save the {Taipo::TypeElement} object described by the type definition in
    # the cache
    #
    # @param k [String] the type definition
    # @param v [Taipo::TypeElement] the object to be saved
    #
    # @return [Taipo::TypeElement] the object to be saved
    #
    # @since 1.0.0
    # @api private
    def self.[]=(k,v)
      @@Cache[k] = v
    end

    # Reset the cache
    #
    # @since 1.0.0
    # @api private
    def self.reset()
      @@Cache = {}
      return nil
    end
  end
end
