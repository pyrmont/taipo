require 'taipo/exceptions'
require 'taipo/type_elements'
require 'taipo/type_element/children'
require 'taipo/type_element/constraints'
require 'taipo/type_element/constraint'

module Taipo

  # An element representing a type (including children and constraints)
  #
  # @since 1.0.0
  # @api private
  class TypeElement

    # The name of the element
    #
    # @since 1.0.0
    # @api private
    attr_accessor :name

    # The children for this element
    #
    # @since 1.4.0
    # @api private
    attr_accessor :children

    # The constraints for this element
    #
    # @since 1.0.0
    # @api private
    attr_reader :constraints

    # Initialize a new type element
    #
    # @param name [String] the name of this type
    # @param children [Taipo::TypeElement::Children|NilClass] the children for
    #   this type
    # @param constraints [Array<Taipo::TypeElement::Constraints>|NilClass] the
    #   constraints for this type
    #
    # @raise [::TypeError] if +name+, +children+ or +constraints+ was of the
    #   wrong type
    # @raise [::ArgumentError] if +name+, +children+ or +constraints+ was
    #   blank/empty
    #
    # @since 1.0.0
    # @api private
    def initialize(name:, children: nil, constraints: nil)
      msg = 'Argument name was not a String.'
      raise ::TypeError, msg unless name.is_a? String
      msg = 'Argument name was an empty string.'
      raise ::ArgumentError if name.empty?

      msg = 'Argument children was not a Taipo::TypeElement::Children.'
      raise ::TypeError unless children.nil? ||
        children.is_a?(Taipo::TypeElement::Children)
      msg = 'Argument children was empty.'
      raise ::ArgumentError if !children.nil? && children.empty?

      msg = 'Argument constraints was not a Taipo::TypeElement::Constraints.'
      raise ::TypeError unless constraints.nil? ||
        constraints.is_a?(Taipo::TypeElement::Constraints)
      msg = 'Argument constraints was empty.'
      raise ::ArgumentError if !constraints.nil? && constraints.empty?

      @name = name
      @children = children
      @constraints = constraints
    end

    # Compare the element with +comp+
    #
    # @param comp [Taipo::TypeElement] the comparison
    #
    # @return [Boolean] the result
    #
    # @raise [::TypeError] if +comp+ is of the wrong type
    #
    # @since 1.0.0
    # @api private
    def ==(comp)
      msg = 'Object to be compared must be of type Taipo::TypeElement.'
      raise ::TypeError, msg unless comp.is_a? Taipo::TypeElement

      @name == comp.name && @children == comp.children
    end

    # Set the element's constraints to +csts+
    #
    # @param csts [Taipo::TypeElement::Constraints] the constraints
    #
    # @raise [::TypeError] if +csts+ was not a Taipo::TypeElement::Constraints
    # @raise [Taipo::SyntaxError] if there are constraints with the same name
    #
    # @since 1.0.0
    # @api private
    def constraints=(csts)
      msg = 'Argument csts was not a Taipo::TypeElement::Constraints.'
      raise ::TypeError, msg unless csts.is_a? Taipo::TypeElement::Constraints

      names = Hash.new
      csts.each do |c|
        msg = 'Contraints must have unique names.'
        raise Taipo::SyntaxError, msg if names.key?(c.name)
        if c.name == Taipo::TypeElement::Constraint::METHOD
          names['#' + c.value] = true
        else
          names[c.name] = true
        end
      end
      @constraints = csts
    end

    # Check if the argument matches the element
    #
    # @param arg [Object] the argument to compare
    #
    # @return [Boolean] the result
    #
    # @raise [Taipo::SyntaxError] if the element's +name+ is not defined (see
    #   {#match_class?})
    #
    # @since 1.0.0
    # @api private
    def match?(arg)
      return true if optional? && arg.nil?

      match_class?(arg) && match_constraints?(arg) && match_children?(arg)
    end

    # Check if the class of the argument itself matches this element
    #
    # @param arg [Object] the argument to compare
    #
    # @return [Boolean] the result
    #
    # @raise [Taipo::SyntaxError] if the element's +name+ is not defined
    #
    # @since 1.0.0
    # @api private
    def match_class?(arg)
      actual_name = (optional?) ? @name[0..-2] : @name
      if actual_name == 'Boolean'
        arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
      else
        msg = "Class to match #{actual_name} is not defined"
        raise Taipo::SyntaxError, msg unless Object.const_defined?(actual_name)
        arg.is_a? Object.const_get(actual_name)
      end
    end

    # Check if the class of the argument's children match
    #
    # @param arg [Object] the argument to compare
    #
    # @return [Boolean] the result
    #
    # @since 1.4.0
    # @api private
    def match_children?(arg)
      self_childless = @children.nil?
      arg_childless = !arg.is_a?(Enumerable) || arg.count == 0
      return true if self_childless
      return false if !self_childless && arg_childless

      arg.all? do |a|
        if !arg.is_a?(Array) && a.is_a?(Array)
          a.each.with_index.reduce(nil) do |memo,(component,index)|
            result = @children[index].any? { |c| c.match? component }
            (memo.nil?) ? result : memo && result
          end
        else # The elements of this collection have no components
          @children.first.any? { |c| c.match? a }
        end
      end
    end

    # Check if the argument fits within the constraints
    #
    # @param arg [Object] the argument to compare
    #
    # @return [Boolean] the result
    #
    # @since 1.0.0
    # @api private
    def match_constraints?(arg)
      return true if @constraints.nil?

      @constraints.all? { |c| c.constrain?(arg) }
    end

    # Check whether this element is an optional
    #
    # An optional type is a variation on a normal type that also matches +nil+.
    # Taipo borrows the syntax used in some other languages of denoting
    # optional types by appending a question mark to the end of the class name.
    #
    # @note This merely checks whether {Taipo::TypeElement#name} ends in a
    #   question mark.
    #
    # @return [Boolean] the result
    #
    # @since 1.3.0
    # @api private
    def optional?
      @name[-1] == '?'
    end

    # Return the String representation of this TypeElement
    #
    # @return [String] the representation as a String
    #
    # @since 1.1.0
    # @api private
    def to_s
      name_str = @name
      children_str = (@children.nil?) ? '' : @children.to_s
      constraints_str = (@constraints.nil?) ? '' : @constraints.to_s
      name_str + children_str + constraints_str
    end
  end
end
