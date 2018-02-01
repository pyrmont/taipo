require 'taipo/type_element/constraint'

module Taipo
  class TypeElement
    # @since 1.4.0
    # @api private
    class Constraints < Array
      def initialize(constraints = nil)
        constraints&.each { |c| self.push c }
      end

      # @since 1.4.0
      # @api private
      def add(el)
        self.push el
      end

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
