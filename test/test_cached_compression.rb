require File.expand_path(File.dirname(__FILE__) + "/rails/test/test_helper")

class CompressionTestController < ActionController::Base
  class << self
    attr_accessor :compression_test_value

    def lorem
      "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    end
  end
  
  caches_embedded :compressed_embedded, :compress => true
  def compressed_embedded
    render :text => CompressionTestController.lorem
  end
  
  def action_with_compressed_embedded
     render :inline => "<%= embed_action :action => 'compressed_embedded' %>"
  end

  def rescue_action(e) raise e end; 
end

# We're hijacking write to verify that the options has is being passed
class CompressionTestStore < ActiveSupport::Cache::MemoryStore
  
  def write(name, value, options=nil)
    CompressionTestController.compression_test_value = value
    super
  end
end

class CachedCompressionTest < ActionController::TestCase
  def setup
    @controller = CompressionTestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    FileUtils.rm_rf "#{RAILS_ROOT}/tmp/cache/views/test.host"

    @original_cache_store = CompressionTestController.cache_store
    
    CompressionTestController.cache_store = CompressionTestStore.new
  end
  
  def teardown
    CompressionTestController.cache_store = @original_cache_store
  end

  def test_compressed_caching
    get :action_with_compressed_embedded
    assert_equal CompressionTestController.lorem, @response.body, "should have included embedded component"
    assert CompressionTestController.compression_test_value.size < CompressionTestController.lorem.size, "should have compressed"
    assert_equal CompressionTestController.lorem, Zlib::Inflate.inflate(CompressionTestController.compression_test_value)
  end
end

