require 'taipo/exceptions'
require 'taipo/parser/stack'
require 'taipo/parser/validater'
require 'taipo/refinements'
require 'taipo/type_elements'
require 'taipo/type_element'
require 'taipo/type_element/children'
require 'taipo/type_element/constraints'
require 'taipo/type_element/constraint'

module Taipo

  # A parser of Taipo type definitions
  # @since 1.0.0
  module Parser

    using Taipo::Refinements

    # Return a Taipo::TypeElements object based on +str+
    #
    # @param str [String] a type definition
    #
    # @return [Taipo:TypeElements] the result
    #
    # @raise [::TypeError] if +str+ is not a String
    # @raise [Taipo::SyntaxError] if +str+ is not a valid type definition
    #
    # @since 1.0.0
    def self.parse(str)
      Taipo::Parser::Validater.validate str
      
      stack = Taipo::Parser::Stack.new
      i = 0
      subject = :implied
      chars = str.chars
      content = ''
      
      while (i < chars.size)
        reset = true
  
        case chars[i]
        when ' '
          i += 1
          next
        when '|'
          stack = process_sum stack, name: content
          subject = :implied
        when '<'
          stack = process_collection :open, stack, name: content
          subject = :implied
        when '>'
          stack = process_collection :close, stack, name: content
          subject = :made
        when ','
          stack = process_component stack, name: content
          subject = :implied
        when '('
          stack = process_subject stack, name: content, subject: subject
          stack, i = process_constraints stack, chars: chars, index: i+1
        else
          reset = false
          subject = :unmade
        end

        content = (reset) ? '' : content + chars[i]
        i += 1
      end

      stack = process_end stack, name: content
      stack.result
    end

    # @since 1.4.0
    # @api private
    def self.parse_constraint(str)
      str.strip!
      in_name = nil
      name = ''
      content = ''
      str.each_char do |c|
        if c == '#' && in_name.nil?
          name = Taipo::TypeElement::Constraint::METHOD
          in_name = false
        elsif c == ':' && in_name.nil?
          name = 'val'
          content = content + c
          in_name = false
        elsif c == ':' && in_name
          name = content
          content = ''
          in_name = false
        else
          content = content + c
          in_name = true if in_name.nil?
        end
      end
      value = content.strip
      return name, value
    end

    # @since 1.4.0
    # @api private
    def self.process_name(stack, name:)
      if name.bare_constraint?
        chars = "(#{name})".chars
        stack = process_subject stack, name: '', subject: :implied
        stack, i = process_constraints stack, chars: chars, index: 1 
        stack
      else
        stack.add_element name: name
      end
    end

    # @since 1.4.0
    # @api private
    def self.process_sum(stack, name:)
      return stack if name.empty?
      
      process_name stack, name: name
    end

    # @since 1.4.0
    # @api private
    def self.process_collection(direction, stack, name:)
      case direction
      when :open
        stack = process_name stack, name: name
        stack.add_children
      when :close
        stack = process_name stack, name: name unless name.empty?
        children = stack.remove_children
        stack.update_element :children=, children
      end
    end

    # @since 1.4.0
    # @api private
    def self.process_component(stack, name:)
      stack = process_name stack, name: name
      stack.add_child
    end

    # @since 1.4.0
    # @api private
    def self.process_subject(stack, name:, subject:)
      case subject
      when :made
        stack
      when :unmade
        process_name stack, name: name
      when :implied
        process_name stack, name: 'Object'
      end
    end

    # @since 1.4.0
    # @api private
    def self.process_constraints(stack, chars:, index:)
      stack.add_constraints

      inside = { ss: false, ds: false, re: false, esc: false }
      content = ''

      while (index < chars.size)
        skip, inside = escape?(chars[index], inside)
        if skip
          content = content + chars[index]
          index += 1
          next
        end

        case chars[index]
        when ')'
          stack = process_constraint stack, raw: content
          break
        when ','
          stack = process_constraint stack, raw: content
          content = ''
        else
          content = content + chars[index]
        end

        index += 1
      end

      constraints = stack.remove_constraints
      stack.update_element :constraints=, constraints

      return stack, index
    end

    # @since 1.4.0
    # @api private
    def self.process_constraint(stack, raw:)
      n, v = parse_constraint raw
      stack.add_constraint Taipo::TypeElement::Constraint.new(name: n, value: v)
    end

    # @since 1.4.0
    # @api private
    def self.process_end(stack, name:)
      return stack if name.empty?

      process_name stack, name: name
    end

    # @since 1.4.0
    # @api private
    def self.escape?(c, states)
      if states[:esc]
        states[:esc] = false
        return skip, states
      end
      
      skip = true
      
      case c
      when "'"
        states[:ss] = !states[:ss] unless states[:re] || states[:ds]
      when '"'
        states[:ds] = !states[:ds] unless states[:re] || states[:ss]
      when '/'
        states[:re] = !states[:re] unless states[:ss] || states[:ds]
      when '\\'
        states[:esc] = true
      else
        skip = false
      end

     return skip, states
    end
  end
end
