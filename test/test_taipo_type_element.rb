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
        ct = Taipo::TypeElement::ChildType.new([component])
        te = Taipo::TypeElement.new(name: @valid_name, child_type: ct)
        assert_kind_of Taipo::TypeElement, te
      end

      should "initialise with a valid class name, child type and constraints" do
        component = Taipo::TypeElement.new(name: 'Integer')
        child_type = Taipo::TypeElement::ChildType.new([component])
        constraint = Taipo::TypeElement::Constraint.new(name: 'min',
                                                            value: '0')
        te = Taipo::TypeElement.new(name: @valid_name,
                                    child_type: child_type,
                                    constraints: [constraint])
        assert_kind_of Taipo::TypeElement, te
      end

      should "raise an ArgumentError if argument 'name' is an empty string" do
        invalid_name = ''
        assert_raises(ArgumentError) do
          Taipo::TypeElement.new(name: invalid_name)
        end
      end

      should "raise an ArgumentError if argument 'child_type' is empty" do
        invalid_child_type = Taipo::TypeElement::ChildType.new
        assert_raises(ArgumentError) do
          Taipo::TypeElement.new(name: @valid_name,
                                 child_type: invalid_child_type)
        end
      end

      should "raise an ArgumentError if argument 'constraints' is empty" do
        invalid_constraints = []
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

        invalid_child_types = [ Object.new, String.new ]
        invalid_child_types.each do |i|
          assert_raises(TypeError) do
            Taipo::TypeElement.new(name: @valid_name, child_type: i)
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
        csts = [ Taipo::TypeElement::Constraint.new(name: 'min', value: 1),
                 Taipo::TypeElement::Constraint.new(name: 'max', value: 5) ]
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
        csts = [ Taipo::TypeElement::Constraint.new(name: 'min', value: 1),
                 Taipo::TypeElement::Constraint.new(name: 'min', value: 5) ]
        assert_raises(Taipo::SyntaxError) { @te.constraints = csts }
      end
    end

    context "has an instance method #match? that" do
      setup do
        type_defs = YAML.load_file 'test/data/valid_type_defs.yml'
        @types = TaipoTestHelper.create_types type_defs
      end

      should "return true for a match" do
        valid_args = YAML.load_file 'test/data/valid_args.yml'
        valid_args.each.with_index do |v,index|
          assert (@types[index].any? { |t| t.match?(v) == true } )
        end
      end

      should "return false for a failed match" do
        invalid_args = YAML.load_file 'test/data/invalid_args.yml'
        invalid_args.each.with_index do |i,index|
          assert (@types[index].any? { |t| t.match?(i) == false } )
        end
      end
    end
  end
end