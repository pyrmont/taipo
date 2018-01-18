require 'test_helper'
require 'taipo'

class TaipoCacheTest < Minitest::Test
  context "Taipo:Cache" do
    setup do
      @Cache = Taipo::Cache
    end

    teardown do
      @Cache.reset
    end

    context "has a cache that" do
      setup do
        @value = Object.new
        @Cache['Test'] = @value
      end

      teardown do
        @Cache.reset
      end

      should "persist" do
        obj_1 = InstancedObject.new
        obj_2 = InstancedObject.new
        assert_equal @value, obj_1.get('Test')
        assert_equal @value, obj_2.get('Test')
      end

      should "reset" do
        obj = InstancedObject.new
        assert_equal @value, obj.get('Test')
        @Cache.reset
        refute_equal @value, obj.get('Test')
      end
    end

    context "has a module method .[] that" do
      should "retrieve an item from the cache" do
        value = Object.new
        @Cache['Test'] = value
        assert_equal value, @Cache['Test']
      end
    end

    context "has a module method .[]= that" do
      should "set the cache" do
        assert_nil @Cache['Test']
        @Cache['Test'] = Object.new
        refute_nil @Cache['Test']
      end
    end
  end

  class InstancedObject
    def get(key)
      Taipo::Cache[key]
    end
  end
end