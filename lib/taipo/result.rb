require 'taipo/utilities'

module Taipo

  # A simple DSL for declaring type checks to run against the return values of
  # specified instance methods
  #
  # {Taipo::Result} works by:
  # 1. adding the {Taipo::Result::ClassMethods#result} method to the including
  #    class;
  # 2. prepending a module to the ancestor chain for the including class; and
  # 3. defining a method on the ancestor with the same name as a particular
  #    instance method on the class and using that method to intercept method
  #    calls and check the return type.
  #
  # Because of how {Taipo::Result} makes the +result+ keyword available to
  # classes, the documentation for this method is in
  # {Taipo::Result::ClassMethods}.
  #
  # @since 1.5.0
  module Result

    # Add the {Taipo::Result::ClassMethods#result} method to the class including
    # this module as well as prepend a module to the ancestor chain.
    #
    # @param base [Class] the class including this module
    #
    # @since 1.5.0
    # @api private
    def self.included(base)
      base.extend ClassMethods
      module_name = "#{base.name}Checker"
      checker = const_defined?(module_name) ? const_get(module_name) :
                                              const_set(module_name, Module.new)
      base.prepend checker
    end

    # A helper module for holding the DSL methods
    #
    # @since 1.5.0
    # @api private
    module ClassMethods

      # The DSL method used to declare a type check on the return value of a
      # method. The intention is that a user will declare the type of result
      # expected from a method by calling this method in the body of a class
      # definition.
      #
      # For purposes of readability, the convention is that
      # {Taipo::Result::ClassMethods#result} will be called near the beginning
      # of the class definition but this is not a requirement and the user is
      # free to call the method immediately before or after the relevant method
      # definition.
      #
      # @param method_name [Symbol] the name of the instance method
      # @param type [String] a type definition
      #
      # @since 1.5.0
      # @api public
      #
      # @example
      #   require 'taipo'
      #
      #   class A
      #     include Taipo::Result
      #
      #     result :foo, 'String'
      #     result :bar, 'Integer'
      #
      #     def foo(arg)
      #       arg.to_s
      #     end
      #
      #     def bar(arg)
      #       arg.to_s
      #     end
      #   end
      #
      #   a = A.new
      #   a.foo 'Hello world!'  #=> "Hello world!"
      #   a.bar 42              #=> Taipo::TypeError
      def result(method_name, type)
        checker = const_get "#{self.name}Checker"
        checker.class_eval do
          define_method(method_name) do |*args, &block|
            method_return_value = super(*args, &block)
            if Taipo::Utilities.match?(object: method_return_value,
                                       definition: type)
              method_return_value
            else
              Taipo::Utilities.throw_error(object: method_return_value,
                                           name: 'value',
                                           definition: type)
            end
          end
        end
      end
    end
  end
end
