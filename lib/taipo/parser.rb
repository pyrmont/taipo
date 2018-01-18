require 'taipo/exceptions'
require 'taipo/parser/validater'
require 'taipo/type_element'

module Taipo

  # A parser of Taipo type definitions
  # @since 1.0.0
  module Parser

    # Return an array of Taipo::TypeElements based on +str+
    #
    # @param str [String] a type definition
    #
    # @return [Array<Taipo:TypeElement>] the result
    #
    # @raise [::TypeError] if +str+ is not a String
    # @raise [Taipo::SyntaxError] if +str+ is not a valid type definition
    #
    # @since 1.0.0
    def self.parse(str)
      Taipo::Parser::Validater.validate str

      content = ''
      is_fallthrough = false
      fallthroughs = [ '/', '"' ]
      closing_symbol = ''
      stack = Array.new
      elements = Array.new
      stack.push elements

      str.each_char do |c|
        c = '+' + c if is_fallthrough

        case c
        when '|'
          next if content.empty? # Previous character must have been '>' or ')'.
          el = Taipo::TypeElement.new name: content
          content = ''
          elements = stack.pop
          elements.push el
          stack.push elements
        when '<'
          el = Taipo::TypeElement.new name: content
          content = ''
          stack.push el
          child_type = Taipo::TypeElement::ChildType.new
          stack.push child_type
          first_component = Array.new
          stack.push first_component
        when '>'
          if content.empty? # Previous character must have been '>' or ')'.
            last_component = stack.pop
          else
            el = Taipo::TypeElement.new name: content.strip
            content = ''
            last_component = stack.pop
            last_component.push el
          end
          child_type = stack.pop
          child_type.push last_component
          parent_el = stack.pop
          parent_el.child_type = child_type
          elements = stack.pop
          elements.push parent_el
          stack.push elements
        when '('
          if content.empty? # Previous character must have been '>'.
            elements = stack.pop
            el = elements.pop
            stack.push elements
          else
            el = Taipo::TypeElement.new name: content
            content = ''
          end
          stack.push el
          cst_collection = Array.new
          stack.push cst_collection
        when '#'
          if bare_method_constraint? stack
            content = content + '#'
          else
            cst = Taipo::TypeElement::Constraint.new
            content = ''
            cst_collection = stack.pop
            cst_collection.push cst
            stack.push cst_collection
          end
        when ':'
          cst = Taipo::TypeElement::Constraint.new name: content.strip
          content = ''
          cst_collection = stack.pop
          cst_collection.push cst
          stack.push cst_collection
        when ',' # We could be inside a collection or a set of constraints
          if inside_collection? stack
            previous_component = stack.pop
            el = Taipo::TypeElement.new name: content.strip
            content = ''
            previous_component.push el
            child_type = stack.pop
            child_type.push previous_component
            stack.push child_type
            next_component = Array.new
            stack.push next_component
          else
            cst_collection = stack.pop
            cst = cst_collection.pop
            cst.value = content.strip
            content = ''
            cst_collection.push cst
            stack.push cst_collection
          end
        when ')'
          cst_collection = stack.pop
          cst = cst_collection.pop
          cst.value = content.strip
          content = ''
          cst_collection.push cst
          el = stack.pop
          el.constraints = cst_collection
          elements = stack.pop
          elements.push el
          stack.push elements
        else
          if is_fallthrough
            c = c[1]
            is_fallthrough = false if c == closing_symbol
          elsif fallthroughs.any? { |f| f == c }
            is_fallthrough = true
            closing_symbol = c
          end
          content = content + c
        end
      end

      unless content.empty?
        el = Taipo::TypeElement.new name: content
        elements = stack.pop
        elements.push el
        stack.push elements
      end

      stack.pop
    end

    # Check if the parser is inside a collection
    #
    # @param stack [Array] the stack of parsed elements
    #
    # @return [Boolean] the result
    #
    # @since 1.0.0
    # @api private
    def self.inside_collection?(stack)
      stack[-2]&.class == Taipo::TypeElement::ChildType
    end

    # Check if this constraint is only a method
    #
    # @param stack [Array] the stack of parsed elements
    #
    # @return [Boolean] the result
    #
    # @since 1.0.0
    # @api private
    def self.bare_method_constraint?(stack)
      stack[-2]&.class != Taipo::TypeElement
    end
  end
end
