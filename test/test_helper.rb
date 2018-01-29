require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'

# Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
Minitest::Reporters.use!

module TaipoTestHelper
  def self.prepare_for_comparison(str)
    str = self.remove_white_space str
    str = self.add_implicit_objects str
  end

  def self.add_implicit_objects(str)
    result = ''
    previous = ''
    paren = :outside
    const = :inactive
    str.each_char do |c|
      case c
      when '('
        paren = :inside
        c = 'Object(' if previous.empty? || previous == '|' || previous == '<'  
      when ')'
        paren = :outside
      when '#'
        if paren == :outside
          c = 'Object(' + c
          const = :active
        end
      when ':'
        if paren == :outside
          c = 'Object(val:' + c
          const = :active
        end
      when '|', '>'
        if const == :active
          c = ')' + c
          const = :inactive
        end
      end
      result += c
      previous = c
    end
    result = (const == :active) ? result + ')' : result
  end

  def self.remove_white_space(str)
    result = ''
    is_skip = false
    skips = [ '/', '"' ]
    closing_symbol = ''
    str.each_char do |c|
      if is_skip
        is_skip = false if c == closing_symbol
      else
        c = '' if c == ' '
        if skips.any? { |s| s == c }
          closing_symbol = c
          is_skip = true
        end
      end
      result += c
    end
    result
  end

  class TestData < Array
    def add(type_def, pass: [], fail: [])
      self.push({ :def => type_def, :pass => pass, :fail => fail })
    end

    def definitions()
      self.reduce([]) do |memo,el|
        memo.push el[:def]
      end
    end
  end
end
