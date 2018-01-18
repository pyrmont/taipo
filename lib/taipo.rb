require 'taipo/version'
require 'taipo/check'
require 'taipo/parser'

# A library for checking the types of objects
# 
# @since 1.0.0
# @see https://github.com/pyrmont/shakushi
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
