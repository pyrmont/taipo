require 'taipo/exceptions'
require 'taipo/type_element/child_type'
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

    # The child type collection for this element
    #
    # @since 1.0.0
    # @api private
    attr_accessor :child_type

    # The constraint collection for this element
    #
    # @since 1.0.0
    # @api private
    attr_reader :constraints

    # Initialize a new type element
    #
    # @param name [String] the name of this type
    # @param child_type [Taipo::TypeElement::ChildType|NilClass] the child type
    #   collection for this element
    # @param constraints [Array<Taipo::TypeElement::Constraints>|NilClass] an
    #   array of constraints for this element
    #
    # @raise [::TypeError] if +name+, +child_type+ or +constraints+ was of the
    #   wrong type
    # @raise [::ArgumentError] if +name+, +child_type+ or +constraints+ was
    #   blank or empty, or +child_type+ or +constraints+ was non-nil and this
    #   is a duck type (ie. a method the type responds to)
    #
    # @since 1.0.0
    # @api private
    def initialize(name:, child_type: nil, constraints: nil)
      msg = 'Argument name was not a String.'
      raise ::TypeError, msg unless name.is_a? String
      msg = 'Argument name was an empty string.'
      raise ::ArgumentError, msg if name.empty?
      msg = 'Argument child_type was not Taipo::TypeElement::ChildType.'
      raise ::TypeError, msg unless (
                             child_type.nil? ||
                             child_type.is_a?(Taipo::TypeElement::ChildType)
                           )
      msg = 'Argument child_type was empty.'
      raise ::ArgumentError, msg if child_type&.empty?
      msg = 'Argument constraints was not an Array.'
      raise ::TypeError, msg unless (constraints.nil? || constraints.is_a?(Array))
      msg = 'Argument constraints was empty.'
      raise ::ArgumentError, msg if constraints&.empty?

      if Taipo.instance_method? name
        msg = 'Argument child_type should have been nil.'
        raise ::ArgumentError, msg unless child_type.nil?
        msg = 'Argument constraints should have been nil.'
        raise ::ArgumentError, msg unless constraints.nil?

        constraints = [
          Taipo::TypeElement::Constraint.new(name: nil, value: name[1..-1])
        ]
        name = 'Object'
      end
      @name = name
      @child_type = child_type
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

      @name == comp.name && @child_type == comp.child_type
    end

    # Set the element's constraints to +csts+
    #
    # @param csts [Array<Taipo::TypeElement::Constraint] the constraints
    #
    # @raise [::TypeError] if +csts+ was not an Array
    # @raise [Taipo::SyntaxError] if there are constraints with the same name
    #
    # @since 1.0.0
    # @api private
    def constraints=(csts)
      msg = 'Argument csts was not an Array.'
      raise ::TypeError, msg unless csts.is_a? Array

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
      match_class?(arg) && match_constraints?(arg) && match_child_type?(arg)
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
      if @name == 'Boolean'
        arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
      else
        msg = "Class to match #{@name} is not defined"
        raise Taipo::SyntaxError, msg unless Object.const_defined?(@name)
        arg.is_a? Object.const_get(@name)
      end
    end

    # Check if the class of the argument's child type matches
    #
    # @param arg [Object] the argument to compare
    #
    # @return [Boolean] the result
    #
    # @since 1.0.0
    # @api private
    def match_child_type?(arg)
      self_childless = @child_type.nil?
      arg_childless = !arg.is_a?(Enumerable) || arg.count == 0
      return true if self_childless
      return false if !self_childless && arg_childless

      arg.all? do |a|
        if a.is_a?(Array) # The elements of this collection have components
          a.each.with_index.reduce(nil) do |memo,(component,index)|
            result = @child_type[index].any? { |c| c.match? component }
            (memo.nil?) ? result : memo && result
          end
        else # The elements of this collection have no components
          @child_type.first.any? { |c| c.match? a }
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

      @constraints.all? do |c|
        c.constrain?(arg)
      end
    end
  end
end
