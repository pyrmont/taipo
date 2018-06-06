require 'test_helper'
require 'taipo'

class TaipoCheckTest < Minitest::Test
  context "Taipo::Check" do
    setup do
      Taipo.alias = true
      extend Taipo::Check
      @td = eval File.read('test/data/valid_defs.rb')
    end

    context "has an instance method #check that" do
      setup do
        @a = 'Test'
        @b = 1
        @arg_types = { :@a => 'String', :@b => 'Integer' }
      end

      should "return an empty array for valid instance variables" do
        assert_equal [], check(binding, @arg_types)
      end

      should "return an empty array for valid local variables" do
        @td.each do |t|
          t[:pass].each do |p|
            assert_equal [], check(binding, p: t[:def])
          end
        end
      end

      should "raise a TypeError if the first argument isn't of type Binding" do
        invalid_nonbindings = [ nil, Object.new, Array.new ]
        invalid_nonbindings.each do |i|
          assert_raises(TypeError) { check(i, {}) }
        end
      end

      should "raise a Taipo::TypeError if the arguments are of the wrong type" do
        @td.each do |t|
          t[:fail].each do |f|
            assert_raises(Taipo::TypeError) { check(binding, f: t[:def]) }
          end
        end
      end

      should "with the false flag, return array of arguments of wrong type" do
        @td.each do |t|
          t[:fail].each do |f|
            assert_equal [:f], check(binding, true, f: t[:def])
          end
        end
      end

      should "raise a Taipo::NameError if the arguments aren't defined" do
        invalid_names = { :@c => 'String' }
        assert_raises(Taipo::NameError) { check(binding, invalid_names) }
      end
    end

    context "has an instance method #review that" do
      setup do
        @a = 'Test'
        @b = 1
        @arg_types = { :@a => 'String', :@b => 'Integer' }
      end

      should "return an empty array for valid instance variables" do
        assert_equal [], review(binding, @arg_types)
      end

      should "return an empty array for valid local variables" do
        a = 'Test'
        b = 1
        arg_types = { a: 'String', b: 'Integer' }
        assert_equal [], review(binding, arg_types)
        a && b # Hack to avoid the unused variable warning.
      end

      should "return array of arguments of wrong type" do
        invalid_inputs = [
          [ [ :@a ], { :@a => 'Integer', :@b => 'Integer' } ],
          [ [ :@b ], { :@a => 'String', :@b => 'String' } ],
          [ [ :@a, :@b ], { :@a => 'Integer', :@b => 'String' } ]
        ]
        invalid_inputs.each do |i|
          assert_equal i[0], review(binding, i[1])
        end
      end
    end

    context "has an alias that" do
      setup do
        class FooAliased
          include Taipo::Check

          def bar(a)
            check types, a: 'Integer'
          end
        end

        class FooUnaliased
          Taipo.alias = false
          include Taipo::Check

          def bar(a)
            check types, a: 'Integer'
          end
        end
      end

      should "alias types if Taipo.alias? returns true" do
        foo = FooAliased.new
        assert Array.new, foo.bar(10)
      end

      should "not alias types if Taipo.alias? returns false" do
        foo = FooUnaliased.new
        assert_raises(::NameError) { foo.bar(10) }
      end

      should "reset Taipo.alias once included" do
        foo = FooUnaliased.new
        assert Taipo.alias?
      end
    end
  end
end
