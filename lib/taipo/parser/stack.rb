require 'taipo/type_elements'
require 'taipo/type_element'
require 'taipo/type_element/children'
require 'taipo/type_element/constraints'
require 'taipo/type_element/constraint'

module Taipo
  module Parser
    class Stack < Array

      def initialize
        self.push Taipo::TypeElements.new
      end

      def result
        msg = "Something went wrong. There should only be one element left."
        raise msg if self.size != 1        
        self.first
      end

      def add_children
        self.push Taipo::TypeElement::Children.new
        self.push Taipo::TypeElements.new
      end

      def remove_children
        child = self.pop
        self.last.push child
        self.pop
      end

      def add_child
        child = self.pop
        self.last.push child
        self.push Taipo::TypeElements.new
      end

      def add_constraints
        self.push Taipo::TypeElement::Constraints.new
      end

      def remove_constraints
        self.pop
      end

      def add_constraint(constraint)
        self.last.add constraint
        self
      end

      def add_element(name:)
        self.last.add Taipo::TypeElement.new(name: name)
        self
      end

      def update_element(method, arg)
        self.last.last.send method, arg
        self
      end

      def delete_element
        self.last.pop
        self
      end
    end
  end
end
