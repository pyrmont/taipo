require 'yaml'
require 'test_helper'
require 'taipo'

class TaipoValidaterTest < Minitest::Test
  context "Taipo::Validater" do
    setup do
      @Validater = Taipo::Parser::Validater
    end

    context "has a module method .validate that" do
      setup do
        valid_data = eval File.read('test/data/valid_defs.rb')
        @valid_inputs = valid_data.definitions
        invalid_data = eval File.read('test/data/invalid_defs.rb')
        @invalid_strings = invalid_data.definitions.select do |d| 
                             d.is_a? String
                           end
        @invalid_nonstrings = invalid_data.definitions.select do |d|
                                !d.is_a? String
                              end
      end

      should "return nil for valid inputs" do
        @valid_inputs.each do |v|
          assert_nil @Validater.validate(v)
        end
      end

      should "raise a ::TypeError for non-string parameters" do
        @invalid_nonstrings.each do |i|
          assert_raises(::TypeError) { @Validater.validate(i) }
        end
      end

      should "raise a Taipo::SyntaxError for invalid strings" do
        @invalid_strings.each do |i|
          assert_raises(Taipo::SyntaxError) { @Validater.validate(i) }
        end
      end
    end
  end
end
