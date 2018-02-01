require 'taipo/type_element'

module Taipo
  # @since 1.4.0
  # @api private
  class TypeElements < Array
    def initialize(els = nil)
      els&.each { |el| self.push el }
    end

    # @since 1.4.0
    # @api private
    def add(el)
      self.push el
    end

    def to_s
      self.reduce('') do |memo,el|
        (memo == '') ? el.to_s : memo + '|' + el.to_s
      end
    end
  end
end
