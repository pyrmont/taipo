require 'taipo/exceptions'
require 'taipo/parser'
require 'taipo/type_elements'
require 'taipo/type_element'
require 'taipo/utilities'

module Taipo

  # A dedicated namespace for methods meant to be included by the user
  #
  # @since 1.0.0
  module Check

    # Syntactic sugar to allow a user to write +check types,...+ and +review
    # types,...+
    #
    # The alias is written with underscores in order to support making aliasing
    # with the keyword +types+ optional (since it's possible the user wishes to
    # use this keyword for other purposes).
    #
    # @since 1.1.0
    # @api private
    alias __types__ binding

    # Check whether the given arguments match the given type definition in the
    # given context
    #
    # @param context [Binding] the context in which the arguments to be checked
    #   are defined
    # @param collect_invalids [Boolean] whether to raise an exception for, or
    #   collect, an argument that doesn't match its type definition
    # @param checks [Hash] the arguments to be checked written as +Symbol:
    #   String+ pairs with the Symbol being the name of the argument and the
    #   String being its type definition
    #
    # @return [Array] the arguments which don't match (ie. an empty array if
    #   all arguments match)
    #
    # @raise [::TypeError] if the context is not a Binding
    # @raise [Taipo::SyntaxError] if the type definitions in +checks+ are
    #   invalid
    # @raise [Taipo::TypeError] if the arguments in +checks+ don't match the
    #   given type definition
    #
    # @since 1.0.0
    #
    # @example
    #   require 'taipo'
    #
    #   class A
    #     include Taipo::Check
    #
    #     def foo(str)
    #       check types, str: 'String'
    #       puts str
    #     end
    #
    #     def bar(str)
    #       check types, str: 'Integer'
    #       puts str
    #     end
    #   end
    #
    #   a = A.new()
    #   a.foo('Hello world!')     #=> "Hello world!"
    #   a.bar('Goodbye world!')   #=> Taipo::TypeError
    def check(context, collect_invalids = false, **checks)
      msg = "The first argument to this method must be of type Binding."
      raise ::TypeError, msg unless context.is_a? Binding

      checks.reduce(Array.new) do |memo,(k,v)|
        arg = Taipo::Utilities.extract_variable(name: k, 
                                                object: self, 
                                                context: context)
        
        is_match = Taipo::Check.match? object: arg, definition: v

        unless collect_invalids || is_match
          Taipo::Check.throw_error object: arg, name: k, definition: v
        end

        (is_match) ? memo : memo.push(k)
      end
    end

    # Review whether the given arguments match the given type definition in the
    # given context
    #
    # This is a convenience method for calling {#check} with +collect_invalids+
    # set to true.
    #
    # @param context (see #check)
    # @param checks (see #check)
    #
    # @return (see #check)
    #
    # @raise (see #check)
    #
    # @since 1.0.0
    def review(context, **checks)
      self.check(context, true, checks)
    end

    # Check if an object matches a given type definition
    #
    # @param object [Object] the object to check
    # @param definition [String] the type definiton to check against
    #
    # @return [Boolean] the result
    #
    # @raise [::TypeError] if +definition+ is not a String
    # @raise [Taipo::SyntaxError] if the type definitions in +checks+ are
    #   invalid
    #
    # @since 1.5.0
    def self.match?(object:, definition:)
      msg = "The 'definition' argument must be of type String."
      raise ::TypeError, msg unless definition.is_a? String
      
      types = Taipo::Parser.parse definition
      types.any? { |t| t.match? object }
    end

    # Perform operations if this module is extended
    #
    # This is the callback called by Ruby when a module is included. In this
    # case, the callback will alias the method +__types__+ as +types+ if
    # {Taipo.alias?} returns true. {Taipo::@@alias} is reset to true at the end
    # of this method.
    #
    # @param extender [Class|Module] the class or module extending this module
    #
    # @since 1.1.0
    # @api private
    def self.extended(extender)
      extender.singleton_class.send(:alias_method, :types, :__types__) if
        Taipo.alias?
      Taipo.alias = true
    end

    # Perform operations if this module is included
    #
    # This is the callback called by Ruby when a module is included. In this
    # case, the callback will alias the method +__types__+ as +types+ if
    # {Taipo.alias?} returns true. {Taipo::@@alias} is reset to true at the end
    # of this method.
    #
    # @param includer [Class|Module] the class or module including this module
    #
    # @since 1.1.0
    # @api private
    def self.included(includer)
      includer.send(:alias_method, :types, :__types__) if Taipo.alias?
      Taipo.alias = true
    end

    # @since 1.5.0
    # @api private
    def self.throw_error(object:, name:, definition:)
      if Taipo::Utilities.instance_method? definition
        msg = "Object '#{name}' does not respond to #{definition}."
      elsif Taipo::Utilities.symbol? definition
        msg = "Object '#{name}' is not equal to #{definition}."
      elsif object.is_a? Enumerable
        type_def = Taipo::Utilities.object_to_type_def object
        msg = "Object '#{name}' is #{type_def} but expected #{definition}."
      else
        class_name = object.class.name
        msg = "Object '#{name}' is #{class_name} but expected #{definition}."
      end
      
      raise Taipo::TypeError, msg
    end
  end
end
