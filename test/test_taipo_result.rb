require 'test_helper'
require 'taipo'

class TaipoResultTest < Minitest::Test
  context "Taipo::Result" do
    context "has a class method .result that" do
      setup do
        @klass = Class.new do
                   include Taipo::Result
                 end
        @object = @klass.new
      end

      should "return the String 'Test' for a method with no arguments" do
        @klass.result :method1, 'String'
        @klass.class_eval { define_method(:method1) { 'Test' } }
        object = @klass.new
        assert_equal 'Test', object.method1
      end

      should "return the String 'Test' for a method with arguments" do
        @klass.result :method2, 'String'
        @klass.class_eval { define_method(:method2) { |a, b| 'Test' } }
        object = @klass.new
        assert_equal 'Test', object.method2(1, 2)
      end

      should "raise an error if the method return value is of wrong type" do
        @klass.result :method3, 'Integer'
        @klass.class_eval { define_method(:method3) { 'Test' } }
        object = @klass.new
        assert_raises(Taipo::TypeError) { object.method3 }
      end

      should "raise an error if no arguments are provided when required" do
        @klass.result :method4, 'String'
        @klass.class_eval { define_method(:method4) { |a| 'Test' } }
        object = @klass.new
        assert_raises(ArgumentError) { object.method4 }
      end

      should "raise an error if the wrong number of arguments are provided" do
        @klass.result :method5, 'String'
        @klass.class_eval { define_method(:method5) { |a| 'Test' } }
        object = @klass.new
        assert_raises(ArgumentError) { object.method5(1, 2) }
      end

      should "raise an error if required keyword arguments are not provided" do
        @klass.result :method6, 'String'
        @klass.class_eval { define_method(:method6) { |a:| 'Test' } }
        object = @klass.new
        assert_raises(ArgumentError) { object.method6(1) }
      end
    end
  end
end
