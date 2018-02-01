require 'test_helper'
require 'taipo'

class TaipoTypeElementTest < Minitest::Test
  context "Taipo::TypeElement" do
    context "has an instance method #initialize that" do
      setup do
        @valid_name = 'Array'
      end

      should "initialise with a valid class name" do
        te = Taipo::TypeElement.new(name: @valid_name)
        assert_kind_of Taipo::TypeElement, te
      end

      should "initialise with a valid class name and child type" do
        component = Taipo::TypeElement.new(name: 'Integer')
        ct = Taipo::TypeElement::Children.new([component])
        te = Taipo::TypeElement.new(name: @valid_name, children: ct)
        assert_kind_of Taipo::TypeElement, te
      end

      should "initialise with a valid class name, child type and constraints" do
        te = Taipo::TypeElement.new(name: 'Integer')
        child = Taipo::TypeElements.new([te])
        children = Taipo::TypeElement::Children.new([child])
        constraint = Taipo::TypeElement::Constraint.new(name: 'min',
                                                        value: '0')
        constraints = Taipo::TypeElement::Constraints.new([constraint])
        te = Taipo::TypeElement.new(name: @valid_name,
                                    children: children,
                                    constraints: constraints)
        assert_kind_of Taipo::TypeElement, te
      end

      should "raise an ArgumentError if argument 'name' is an empty string" do
        invalid_name = ''
        assert_raises(ArgumentError) do
          Taipo::TypeElement.new(name: invalid_name)
        end
      end

      should "raise an ArgumentError if argument 'children' is empty" do
        invalid_children = Taipo::TypeElement::Children.new
        assert_raises(ArgumentError) do
          Taipo::TypeElement.new(name: @valid_name,
                                 children: invalid_children)
        end
      end

      should "raise an ArgumentError if argument 'constraints' is empty" do
        invalid_constraints = Taipo::TypeElement::Constraints.new
        assert_raises(ArgumentError) do
          Taipo::TypeElement.new(name: @valid_name,
                                 constraints: invalid_constraints)
        end
      end

      should "raise a TypeError if arguments are incorrectly typed" do
        invalid_names = [ nil, Object.new, Array.new ]
        invalid_names.each do |i|
          assert_raises(TypeError) { Taipo::TypeElement.new(name: i) }
        end

        invalid_children = [ Object.new, String.new ]
        invalid_children.each do |i|
          assert_raises(TypeError) do
            Taipo::TypeElement.new(name: @valid_name, children: i)
          end
        end

        invalid_constraints = [ Object.new, String.new ]
        invalid_constraints.each do |i|
          assert_raises(TypeError) do
            Taipo::TypeElement.new(name: @valid_name, constraints: i)
          end
        end
      end
    end

    context "has an instance method #== that" do
      setup do
        @class_name = 'Integer'
        @te = Taipo::TypeElement.new(name: @class_name)
      end

      should "return true for a valid matching input" do
        same_comp = Taipo::TypeElement.new(name: @class_name)
        assert (@te == same_comp)
      end

      should "return false for a valid non-matching input" do
        other_class_name = 'Hash'
        diff_comp = Taipo::TypeElement.new(name: other_class_name)
        refute (@te == diff_comp)
      end

      should "raise a TypeError when comparator is wrong type" do
        invalid_comparisons = [ nil, Object.new, Array.new ]
        invalid_comparisons.each do |i|
          assert_raises(TypeError) { @te == i }
        end
      end
    end

    context "has an instance method #constraint= that" do
      setup do
        @te = Taipo::TypeElement.new(name: 'String')
      end

      should "set the constraints for valid input" do
        csts = Taipo::TypeElement::Constraints.new(
                 [ Taipo::TypeElement::Constraint.new(name: 'min', value: 1),
                   Taipo::TypeElement::Constraint.new(name: 'max', value: 5) ]
               )
        @te.constraints = csts
        assert (@te.constraints == csts)
      end

      should "raise a TypeError when the argument is not an Array" do
        invalid_comparisons = [ nil, Object.new, Hash.new ]
        invalid_comparisons.each do |i|
          assert_raises(TypeError) { @te.constraints = i }
        end
      end

      should "raise a Taipo::SyntaxError when there duplicate constraints" do
        csts = Taipo::TypeElement::Constraints.new(
                 [ Taipo::TypeElement::Constraint.new(name: 'min', value: 1),
                   Taipo::TypeElement::Constraint.new(name: 'min', value: 5) ]
               )
        assert_raises(Taipo::SyntaxError) { @te.constraints = csts }
      end
    end

    context "has an instance method #match? that" do
      setup do
        csts = Taipo::TypeElement::Constraints.new(
                  [ Taipo::TypeElement::Constraint.new(name: 'min', value: 1),
                    Taipo::TypeElement::Constraint.new(name: 'max', value: 5) ]
                )

        @te_p = Taipo::TypeElement.new name: 'Integer'

        tes = Taipo::TypeElements.new [@te_p]

        @te_c = Taipo::TypeElement.new(
                  name: 'Array',
                  children: Taipo::TypeElement::Children.new([tes])
                )

        @te_p_with_c = @te_p.dup
        @te_p_with_c.constraints = csts

        @te_c_with_c = @te_c.dup
        @te_c_with_c.constraints = csts
      end

      should "return true for a match" do
        assert @te_p.match?(1)
        assert @te_c.match?([1])
        assert @te_p_with_c.match?(1)
        assert @te_c_with_c.match?([1])
      end

      should "return false for a failed match" do
        refute @te_p.match?('1')
        refute @te_c.match?({a: 1})
        refute @te_p_with_c.match?(0)
        refute @te_c_with_c.match?([1, 2, 3, 4, 5, 6])
      end
    end

    context "has an instance method #to_s that" do
      setup do
        valid_data = eval File.read('test/data/valid_defs.rb')
        @valid_defs = valid_data.definitions
      end

      should "return the String representation" do
        @valid_defs.each do |v|
          tes = Taipo::Parser.parse v
          assert_equal(TaipoTestHelper.prepare_for_comparison(v), tes.to_s)
        end
      end
    end
  end
end
