require 'taipo/cache'
require 'taipo/exceptions'
require 'taipo/parser'
require 'taipo/type_element'

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
        arg = if k[0] == '@' && self.instance_variable_defined?(k)
                self.instance_variable_get k
              elsif k[0] != '@' && context.local_variable_defined?(k)
                context.local_variable_get k
              else
                msg = "Argument '#{k}' is not defined."
                raise Taipo::NameError, msg
              end

        types = if hit = Taipo::Cache[v]
                  hit
                else
                  Taipo::Cache[v] = Taipo::Parser.parse v
                end

        is_match = types.any? { |t| t.match? arg }

        unless collect_invalids || is_match
          if Taipo::instance_method? v
            msg = "Object '#{k}' does not respond to #{v}."
          elsif Taipo::symbol? v
            msg = "Object '#{k}' is not equal to #{v}."
          elsif arg.is_a? Enumerable
            type_def = Taipo.object_to_type_def arg
            msg = "Object '#{k}' is #{type_def} but expected #{v}."
          else
            msg = "Object '#{k}' is #{arg.class.name} but expected #{v}."
          end
          raise Taipo::TypeError, msg
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

    # Perform operations if this module is extended
    #
    # This is the callback called by Ruby when a module is included. In this
    # case, the callback will alias the method +__types__+ as +types+ if
    # {Taipo.alias?} returns true. {Taipo.alias} is reset to true at the end of
    # this method.
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
    # {Taipo.alias?} returns true. {Taipo.alias} is reset to true at the end of
    # this method.
    #
    # @param includer [Class|Module] the class or module including this module
    #
    # @since 1.1.0
    # @api private
    def self.included(includer)
      includer.send(:alias_method, :types, :__types__) if Taipo.alias?
      Taipo.alias = true
    end
  end
end
