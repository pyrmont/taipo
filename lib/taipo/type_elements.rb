require 'taipo/type_element'

module Taipo

  # A set of {Taipo::TypeElement} objects
  #
  # @since 1.4.0
  # @api private
  class TypeElements < Array

    # Initialize a new set of {Taipo::TypeElement}
    #
    # @param els [Array<Taipo::TypeElement>] the elements
    #
    # @since 1.4.0
    # @api private
    def initialize(els = nil)
      els&.each { |el| self.push el }
    end

    # Return the String representation of this object
    #
    # @return [String] the representation as a String
    #
    # @since 1.4.0
    # @api private
    def to_s
      self.reduce('') do |memo,el|
        (memo == '') ? el.to_s : memo + '|' + el.to_s
      end
    end
  end
end
