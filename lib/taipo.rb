require 'taipo/version'
require 'taipo/check'
require 'taipo/parser'

# A library for checking the types of objects
#
# Taipo is primarily intended as a replacement for cumbersome, error-prone
# guard statements a user can put in their code to ensure that the variables
# they are handling conform to expectations.
#
# By including the module {Taipo::Check}, a user can call the
# {Taipo::Check#check} or {Taipo::Check#review} methods in their classes
# whenever a guard statement is necessary. Expectations are written as type
# definitions. A type definition contains the name of the type and the type
# definitions of any elements it contains (if it is enumerable). Optional
# constraints may be specified and sum types are also possible. See
# {Taipo::Parser::Validater} for the full syntax.
#
# Taipo works by:
# 1. extracting the values of the arguments to be checked from a Binding;
# 2. transforming the type definitions provided as Strings into an array of
#    {Taipo::TypeElement} instances; and
# 3. checking whether the argument's value matches any of the instances of
#    {Taipo::TypeElement} in the array.
#
# As syntactic sugar, the {Taipo::Check} module will by default alias
# +Kernel#binding+ with the keyword +types+. This allows the user to call
# {Taipo::Check#check} by writing +check types+ (with a similar syntax for
# {Taipo::Check#review}). If the user does not want to alias, they can set
# {Taipo.alias=} to +false+ before including or extending {Taipo::Check}.
#
# @since 1.0.0
# @see https://github.com/pyrmont/taipo
module Taipo

  # The setting for whether +Kernel#binding+ should be aliased with the keyword
  # +types+.
  #
  # @since 1.1.0
  # @api private
  @@alias = true

  # Set whether +Kernel#binding+ should be aliased with the keyword +types+.
  #
  # @param v [Boolean] Whether to alias
  #
  # @since 1.1.0
  # @api private
  def self.alias=(v)
    msg = "The argument to this method must be a Boolean."
    raise ::TypeError, msg unless v.is_a?(TrueClass) || v.is_a?(FalseClass)

    @@alias = v
  end

  # Check whether +Kernel#binding+ should be aliased with the keyword +types+.
  #
  # @return [Boolean] the result
  #
  # @since 1.1.0
  # @api private
  def self.alias?
    @@alias
  end

  # Check if a string is the name of an instance method
  #
  # @note All this does is check whether the given string begins with a hash
  #   symbol.
  #
  # @param str [String] the method name to check
  #
  # @return [Boolean] the result
  #
  # @since 1.0.0
  # @api private
  def self.instance_method?(str)
    str[0] == '#'
  end

  # Return the type definition for an object
  #
  # @note This assume that each element returned by Enumerator#each has the same
  #   number of components.
  #
  # @param arg [Object] the object
  #
  # @return [String] a type definition of the object
  #
  # @since 1.1.0
  # @api private
  def self.object_to_type_def(obj)
    return obj.class.name unless obj.is_a? Enumerable

    if obj.is_a? Array
      element_types = Hash.new
      obj.each { |o| element_types[self.object_to_type_def(o)] = true }
      if element_types.empty?
        obj.class.name
      else
        obj.class.name + '<' + element_types.keys.join('|') + '>'
      end
    else
      element_types = Array.new
      obj.each.with_index do |element,index_e|
        element.each.with_index do |component,index_c|
          element_types[index_c] = Hash.new if index_e == 0
          c_type = self.object_to_type_def(component)
          element_types[index_c][c_type] = true
        end
      end
      inner = element_types.reduce('') do |memo,e|
        e_type = e.keys.join('|')
        (memo == '') ? e_type : memo + ',' + e_type
      end
      if element_types.empty?
        obj.class.name
      else
        obj.class.name + '<' + inner + '>'
      end
    end
  end

  # Return a String representation of an array of {Taipo::TypeElement}
  #
  # @param arg [Array<Taipo::TypeElement>] the array of {Taipo::TypeElement}
  #
  # @return [String] the String representation
  #
  # @since 1.1.0
  # @api private
  def self.types_to_s(types)
    types.reduce('') do |memo,t|
      (memo == '') ? t.to_s : memo + '|' + t.to_s
    end
  end
end