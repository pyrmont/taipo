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
  # Note that this will be reset to true whenever {Taipo::Check} is extended or
  # included.
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
end
