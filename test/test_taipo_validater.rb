require 'yaml'
require 'test_helper'
require 'taipo'

class TaipoValidaterTest < Minitest::Test
  context "Taipo::Validater" do
    setup do
      @Validater = Taipo::Parser::Validater
      @valid_inputs = YAML.load_file 'test/data/valid_type_strings.yml'
    end

    context "has a module method .validate that" do
      setup do
        @invalid_strings = YAML.load_file 'test/data/invalid_type_strings.yml'
        @invalid_nonstrings = [ nil, Object.new, Array.new ]
      end

      should "return nil for valid inputs" do
        @valid_inputs.each do |v|
          assert_nil @Validater.validate(v)
        end
      end

      should "raise a Taipo::TypeError for non-string parameters" do
        @invalid_nonstrings.each do |i|
          assert_raises(::TypeError) { @Validater.validate(i) }
        end
      end

      should "raise a Taipo::SyntaxError for invalid strings" do
        @invalid_strings.each do |i|
          assert_raises(Taipo::SyntaxError) { @Validater.validate(i) }
          # error = assert_raises(SyntaxError) { @Parser.validate(i) }
          # puts error.message
        end
      end
    end
  end
end
