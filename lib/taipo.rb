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
# definitions that can specify the type of the variable (including sum types)
# and the types of any elements it contains, all subject to a given constraints
# (see {Taipo::Parser::Validater} for the full syntax).
#
# As syntactic sugar, the {Taipo::Check} module also aliases +Kernel#binding+
# with the keyword +types+. This allows the user to call {Taipo::Check#check}
# and {Taipo::Check#review} by writing +check types, ...+ and
# +review types, ...+ respectively.
#
# @since 1.0.0
# @see https://github.com/pyrmont/taipo
module Taipo

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

  # Convert an array into a type definition for the types of the elements in the array
  #
  # @param arg [Array] the array of elements
  #
  # @return [String] a type definition of the types in the array
  #
  # @since 1.0.0
  # @api private
  def self.child_types_string(arg)
    child_types = Hash.new
    arg.each { |a| child_types[a.class.name] = true }
    '<' + child_types.keys.join('|') + '>'
  end
end
