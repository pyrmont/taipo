require 'taipo/version'
require 'taipo/check'
require 'taipo/result'

# A library for checking the types of objects
#
# Taipo is primarily intended as a replacement for verbose, error-prone guard
# statements. With Taipo, a user can ensure that the objects they are working
# with conform to expectations.
#
# Taipo consists of two user-facing parts: {Taipo::Check} and {Taipo::Result}.
#
# * By including the module {Taipo::Check}, a user can call
#   {Taipo::Check#check} or {Taipo::Check#review} in their methods to
#   check the types of one or more given variables.
#
# * By including the module {Taipo::Result}, a user can call
#   {Taipo::Result::ClassMethods#result} in their class definitions to check the
#   return values of a given method.
#
# Taipo provides a rich syntax to express type definitions. This includes
# classes, collections, optionals and duck types. See
# {Taipo::Parser::Validater} for the full syntax.
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
