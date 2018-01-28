require 'yaml'
require 'test_helper'
require 'taipo'

class TaipoParserTest < Minitest::Test
  context "Taipo::Parser" do
    setup do
      @Parser = Taipo::Parser
      # @valid_inputs = YAML.load_file 'test/data/valid_type_strings.yml'
      valid_data= eval File.read('test/data/valid_defs.rb')
      @valid_inputs = valid_data.definitions
    end

    context "has a module method .parse that" do
      setup do
        # @invalid_strings = ['String(len: 5, len: 5)']
        invalid_data= eval File.read('test/data/invalid_defs.rb')
        @invalid_strings = invalid_data.definitions.select do |d|
                             d.is_a? String
                           end
      end

      should "return an array of Taipo::TypeElement for valid inputs" do
        @valid_inputs.each do |v|
          assert_equal TaipoParserTest.reverse_parse(@Parser.parse(v)),
                       TaipoTestHelper.prepare_for_comparison(v)
        end
      end

      should "raise a Taipo::SyntaxError for invalid strings" do
        @invalid_strings.each do |i|
          assert_raises(Taipo::SyntaxError) { @Parser.parse(i) }
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
end
