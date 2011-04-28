require File.expand_path(File.dirname(__FILE__) + "/rails/test/test_helper")

# Add 'lib' to ruby's library path and load the plugin libraries (code copied from Rails railties initializer's load_plugin)
#lib_path  = File.expand_path(File.dirname(__FILE__) + "/../lib")
#application_lib_index = $LOAD_PATH.index(File.join(RAILS_ROOT, "lib")) || 0  
#$LOAD_PATH.insert(application_lib_index + 1, lib_path)
#require File.expand_path(File.dirname(__FILE__) + "/../init")

# Re-raise errors caught by the controller.

# Our arguments for the memory store are set per action as a hash
class CacheOptionsTestController < ActionController::Base
  class << self
    attr_accessor :cache_store_test_value
  end
  
  caches_embedded :test_embedded, { :test_value => 300 } 
  def test_embedded
    render :text => "test embedded"
  end
  
  def test_action
    render :inline => "<%= embed_action :action => 'test_embedded' %>"
  end
  
  def rescue_action(e) raise e end; 
end

# We're hijacking write to verify that the options has is being passed
class CacheOptionsTestStore < ActiveSupport::Cache::MemoryStore
  def write(name, value, options = nil)
    CacheOptionsTestController.cache_store_test_value = options.is_a?(Hash) ? options[:test_value] : nil
    super
  end
end

class CachesOptionsTest < ActionController::TestCase
  def setup
    @controller = CacheOptionsTestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @original_cache_store = CacheOptionsTestController.cache_store
    CacheOptionsTestController.cache_store = CacheOptionsTestStore.new
    CacheOptionsTestController.cache_store_test_value = 0
  end
  def teardown
    CacheOptionsTestController.cache_store = @original_cache_store
  end
  
  def test_embedded_caching
    CacheOptionsTestController.cache_store_test_value = 0

    get :test_action
    assert_equal "test embedded", @response.body
    assert_equal 300, CacheOptionsTestController.cache_store_test_value 
  end
end

