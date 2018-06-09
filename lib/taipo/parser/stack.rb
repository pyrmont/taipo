require 'taipo/type_elements'
require 'taipo/type_element'
require 'taipo/type_element/children'
require 'taipo/type_element/constraints'
require 'taipo/type_element/constraint'

module Taipo
  module Parser

    # A stack of parsed or partially parsed elements
    #
    # @since 1.4.0
    # @api private
    class Stack < Array

      # Initialize the stack
      #
      # @since 1.4.0
      # @api private
      def initialize
        self.push Taipo::TypeElements.new
      end

      # Return the resulting {Taipo::TypeElements} object
      #
      # @note This should not be called until parsing is complete.
      #
      # @return [Taipo::TypeElements] the parsed object representing the
      #   relevant type definition
      #
      # @raise [RuntimeError] if there is more than one element in the stack
      #
      # @since 1.4.0
      # @api private
      def result
        msg = "Something went wrong. There should only be one element left."
        raise RuntimeError, msg if self.size != 1
        self.first
      end

      # Add a {Taipo::TypeElement::Children} object to the top of the stack
      #
      # @note Due to the way {Taipo::Parser} is implemented, this method will
      #   also add an empty {Taipo::TypeElements} object to the stack. This
      #   represents the first (and possibly only) component of the collection.
      #
      # @return [Taipo::Parser::Stack] the updated stack
      #
      # @since 1.4.0
      # @api private
      def add_children
        self.push Taipo::TypeElement::Children.new
        self.push Taipo::TypeElements.new
      end

      # Remove a {Taipo::TypeElement::Children} object from the top of the stack
      #
      # @note Due to the way {Taipo::Parser} is implemented, this method first
      #   removes the child that is at the top of the stack, adds that to the
      #   set of children and then returns the children.
      #
      # @return [Taipo::TypeElement::Children] the children
      #
      # @since 1.4.0
      # @api private
      def remove_children
        child = self.pop
        self.last.push child
        self.pop
      end

      # Add a {Taipo::TypeElements} object to the top of the stack
      #
      # @note Due to the way {Taipo::Parser} is implemented, this method first
      #   removes the child that is at the top of the stack, adds that to the
      #   set of children and then add a new child.
      #
      # @return [Taipo::Parser::Stack] the updated stack
      #
      # @since 1.4.0
      # @api private
      def add_child
        child = self.pop
        self.last.push child
        self.push Taipo::TypeElements.new
      end

      # Add a {Taipo::TypeElement::Constraints} object to the top of the stack
      #
      # @return [Taipo::Parser::Stack] the updated stack
      #
      # @since 1.4.0
      # @api private
      def add_constraints
        self.push Taipo::TypeElement::Constraints.new
      end

      # Remove a {Taipo::TypeElement::Constraints} object from the top of the
      # stack
      #
      # @return [Taipo::TypeElement::Constraints] the constraints
      #
      # @since 1.4.0
      # @api private
      def remove_constraints
        self.pop
      end

      # Add a {Taipo::TypeElement::Constraint} object to the top of the stack
      #
      # @return [Taipo::Parser::Stack] the updated stack
      #
      # @since 1.4.0
      # @api private
      def add_constraint(name:, value:)
        self.last.push Taipo::TypeElement::Constraint.new(name: name,
                                                          value: value)
        self
      end

      # Add a {Taipo::TypeElement} object to the top of the stack
      #
      # @return [Taipo::Parser::Stack] the updated stack
      #
      # @since 1.4.0
      # @api private
      def add_element(name:)
        self.last.push Taipo::TypeElement.new(name: name)
        self
      end

      # Update the {Taipo::TypeElement} object at the top of the stack
      #
      # @return [Taipo::Parser::Stack] the updated stack
      #
      # @since 1.4.0
      # @api private
      def update_element(method, arg)
        self.last.last.send method, arg
        self
      end
    end
  end
end
