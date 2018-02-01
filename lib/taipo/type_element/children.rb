module Taipo
  class TypeElement

    # A collection of Taipo::TypeElement
    # @since 1.4.0
    # @api private
    class Children < Array

      def initialize(children = nil)
        children&.each { |c| self.push c }
      end

      # Return the String representation of this object
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

