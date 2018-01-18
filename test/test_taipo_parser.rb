require 'yaml'
require 'test_helper'
require 'taipo'

class TaipoParserTest < Minitest::Test
  context "Taipo::Parser" do
    setup do
      @Parser = Taipo::Parser
      @valid_inputs = YAML.load_file 'test/data/valid_type_strings.yml'
    end

    context "has a module method .parse that" do
      setup do
        @invalid_strings = ['String(len: 5, len: 5)']
      end

      should "return an array of Taipo::TypeElement for valid inputs" do
        @valid_inputs.each do |v|
          assert_equal TaipoParserTest.reverse_parse(@Parser.parse(v)),
                       TaipoParserTest.prepare_for_comparison(v)

        end
      end

      should "raise a Taipo::SyntaxError for invalid strings" do
        @invalid_strings.each do |i|
          assert_raises(Taipo::SyntaxError) { @Parser.parse(i) }
          # error = assert_raises(SyntaxError) { @Parser.parse(i) }
          # puts error.message
        end
      end
    end
  end

  def self.reverse_parse(array)
    array.reduce(nil) do |memo, a|
      memo = (memo.nil?) ? '' : memo + '|'
      memo += a.name
      memo += self.reverse_parse_child a.child_type
      memo += self.reverse_parse_constraints a.constraints
    end
  end

  def self.reverse_parse_child(child)
    return '' if child.nil?
    inner = child.reduce(nil) do |memo, c|
              memo = (memo.nil?) ? '' : memo + ','
              memo + self.reverse_parse(c)
            end
    '<' + inner + '>'
  end

  def self.reverse_parse_constraints(constraints)
    return '' if constraints.nil?
    inner = constraints.reduce(nil) do |memo, c|
              (memo.nil?) ? c.to_s : memo + ',' + c.to_s
            end
    '(' + inner + ')'
  end

  def self.prepare_for_comparison(str)
    str = self.remove_white_space str
    str = self.add_implicit_objects str
  end

  def self.add_implicit_objects(str)
    result = ''
    paren = :outside
    const = :inactive
    str.each_char do |c|
      case c
      when '('
        paren = :inside
      when ')'
        paren = :outside
      when '#'
        if paren == :outside
          c = 'Object(' + c
          const = :active
        end
      when '|', '>'
        if const == :active
          c = ')' + c
          const = :inactive
        end
      end
      result += c
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
end