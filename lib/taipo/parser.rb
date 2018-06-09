require 'taipo/cache'
require 'taipo/parser/stack'
require 'taipo/parser/validater'
require 'taipo/refinements'

module Taipo

  # A parser of Taipo type definitions
  #
  # @since 1.0.0
  module Parser

    using Taipo::Refinements

    # Return a Taipo::TypeElements object based on +str+
    #
    # This method acts as a wrapping method to {Taipo::Parser.parse_definition}.
    # It first checks if the type definition has already been parsed and is in
    # Taipo's cache.
    #
    # @param str [String] a type definition
    #
    # @return [Taipo::TypeElements] the result
    #
    # @raise [::TypeError] if +str+ is not a String
    # @raise [Taipo::SyntaxError] if +str+ is not a valid type definition
    #
    # @since 1.0.0
    def self.parse(str)
      if hit = Taipo::Cache[str]
        hit
      else
        Taipo::Cache[str] = Taipo::Parser.parse_definition str
      end
    end

    # Check whether the character should be skipped
    #
    # This method determines whether a particular character +c+ should be
    # skipped based on +states+. It also updates +states+.
    #
    # @param c [String] the character to check
    # @param states [Hash<Symbol,Boolean>] a state machine
    #
    # @return [Boolean,Hash<Symbol,Boolean>] the result and the updated state
    #   machine
    #
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

    # Parse the constraint expressed as a string
    #
    # @note If the constraint is in the form of an instance method (eg. #foo)
    #   this method uses {Taipo::TypeElement::Constraint::METHOD} as the name
    #   returned.
    #
    # @param str [String] the constraint expressed as a string
    #
    # @return [String,String] the name and the value
    #
    # @since 1.4.0
    # @api private
    def self.parse_constraint(str)
      str.strip!
      in_name = nil
      name = ''
      content = ''
      str.each_char do |c|
        if c == '#' && in_name.nil?
          name = '#'
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

    # Return a Taipo::TypeElements object based on +str+
    #
    # @param str (see {Taipo::Parser.parse})
    #
    # @return (see {Taipo::Parser.parse})
    #
    # @raise (see {Taipo::Parser.parse})
    #
    # @since 1.5.0
    # @api private
    def self.parse_definition(str)
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

    # Process a collection
    #
    # This method either adds or updates a collection on +stack+ depending on
    # +direction+. If +direction+ is +:open+, this adds a
    # {Taipo::TypeElement} to +stack+ representing the class of the collection.
    # If +direction+ is +:close+, this adds a {Taipo::TypeElement} to +stack+
    # representing the class of the final component of the collection.
    #
    # @param direction [Symbol] Either +:open+ or +:close+ depending on whether
    #   this has been called because the parser reached a +<+ character or a
    #   +>+ character
    # @param stack [Taipo::Parser::Stack] the stack
    # @param name [String] the name of the class of the {Taipo::TypeElement} to
    #   add to +stack+
    #
    # @return [Taipo::Parser::Stack] the updated stack
    #
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

    # Process a component
    #
    # This method adds a {Taipo::TypeElement} to +stack+ representing a
    # component of a collection.
    #
    # @param stack [Taipo::Parser::Stack] the stack
    # @param name [String] the name of the class of the {Taipo::TypeElement} to
    #   add to +stack+
    #
    # @return [Taipo::Parser::Stack] the updated stack
    #
    # @since 1.4.0
    # @api private
    def self.process_component(stack, name:)
      stack = process_name stack, name: name
      stack.add_child
    end

    # Process a constraint
    #
    # This method adds a {Taipo::TypeElement::Constraint} to the last element in
    # +stack+.
    #
    # @param stack [Taipo::Parser::Stack] the stack
    # @param raw [String] the constraint expressed as a string
    #
    # @return [Taipo::Parser::Stack] the updated stack
    #
    # @since 1.4.0
    # @api private
    def self.process_constraint(stack, raw:)
      n, v = parse_constraint raw
      stack.add_constraint name: n, value: v
    end

    # Process a series of constraints
    #
    # This method adds a {Taipo::TypeElement::Constraints} to the last element
    # in +stack+. Because it parses +chars+, it also returns an updated +index+.
    #
    # @param stack [Taipo::Parser::Stack] the stack
    # @param chars [Array<String>] a character array
    # @param index [Integer] the index of +chars+ at which to begin parsing
    #
    # @return [Taipo::Parser::Stack,Integer] the updated stack and the updated
    #   index
    #
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

    # Process the end of the type definition
    #
    # The design of {Taipo::Parser.parse} means that at the end of the loop, an
    # element may remain to be added. This method add any remaining element to
    # +stack+.
    #
    # @param stack [Taipo::Parser::Stack] the stack
    # @param name [String] the name of the class of the {Taipo::TypeElement} to
    #   add to +stack+
    #
    # @return [Taipo::Parser::Stack] the updated stack
    #
    # @since 1.4.0
    # @api private
    def self.process_end(stack, name:)
      return stack if name.empty?

      process_name stack, name: name
    end

    # Process the name of a {Taipo::TypeElement}
    #
    # This method adds a {Taipo::TypeElement} to +stack+ with the name +name+.
    #
    # @note Taipo allows certain bare constraints to be written in type
    #   definitions. If +name+ is a bare constraint (either an instance method
    #   or a symbol), this method adds a {Taipo::TypeElement} representing the
    #   Object class with the relevant constraint.
    #
    # @param stack [Taipo::Parser::Stack] the stack
    # @param name [String] the name of the class of the {Taipo::TypeElement} to
    #   add to +stack+
    #
    # @return [Taipo::Parser::Stack] the updated stack
    #
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

    # Process the subject of a series of constraints
    #
    # Taipo allows for a type definition to specify a series of constraints
    # that constrain the particular type (the subject). This method adds a
    # {Taipo::TypeElement} to +stack+ depending on the value of +subject+.
    #
    # @param stack [Taipo::Parser::Stack] the stack
    # @param name [String] the name of the class of the {Taipo::TypeElement} to
    #   add to +stack+
    # @param subject [Symbol] whether the subject is :made, :unmade or :implied
    #
    # @return [Taipo::Parser::Stack] the updated stack
    #
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

    # Process a sum of types
    #
    # This method adds a {Taipo::TypeElement} to +stack+ representing the former
    # of the types in the sum.
    #
    # @param stack [Taipo::Parser::Stack] the stack
    # @param name [String] the name of the class of the {Taipo::TypeElement} to
    #   add to +stack+
    #
    # @return [Taipo::Parser::Stack] the updated stack
    #
    # @since 1.4.0
    # @api private
    def self.process_sum(stack, name:)
      return stack if name.empty?

      process_name stack, name: name
    end
  end
end
