require File.expand_path(File.dirname(__FILE__) + "/rails/test/test_helper")

# Add 'lib' to ruby's library path and load the plugin libraries (code copied from Rails railties initializer's load_plugin)
#lib_path  = File.expand_path(File.dirname(__FILE__) + "/../lib")
#application_lib_index = $LOAD_PATH.index(File.join(RAILS_ROOT, "lib")) || 0  
#$LOAD_PATH.insert(application_lib_index + 1, lib_path)
#require File.expand_path(File.dirname(__FILE__) + "/../init")

# Re-raise errors caught by the controller.
class CachesEmbeddedTestController < ActionController::Base
  class <<self 
    attr_accessor :test_value
    attr_accessor :another_value
  end

  caches_embedded :cached_action
  def cached_action
    @id = params[:id]
    @value = self.class.test_value || "N/A"
    
    render :text => "#{@value}#{" (id=#{@id})" if @id}"
  end
  
  def regular_action
    @id = params[:id]
    @value = self.class.test_value || "N/A"
    
    render :text => "#{@value}#{" (id=#{@id})" if @id}"
  end
  
  def embedded_actions
    render :inline => <<-END
      regular value is <%= embed_action :controller => "caches_embedded_test", :action => "regular_action" %>
      cached value is <%= embed_action :controller => "caches_embedded_test", :action => "cached_action" %>
    END
  end
  
  def call_uncached_controller
     render :inline => %Q{<%= embed_action :controller => "test_no_caching", :action => "test_action" %>}
  end  
  
  def call_namespaced_action
    render :inline => %Q{<%= embed_action :controller => "admin/namespaced", :action => "cached_action" %>}
  end
  
  def embedded_overrides
    render :inline => <<-END
      regular value is <%= embed_action :controller => "test", :action => "regular_action", :caching => true %>
      cached value is <%= embed_action :controller => "test", :action => "cached_action", :caching => false %>  
    END
  end

  caches_embedded :cached_variable_action, :options_for_name => Proc.new { {:value => CachesEmbeddedTestController.another_value}}
  def cached_variable_action
    @id = params[:id]
    @value = self.class.test_value || "N/A"
    
    render :text => "#{@value}#{" (id=#{@id})" if @id}"
  end

  def embedded_overrides
    render :inline => <<-END
      regular value is <%= embed_action :controller => "caches_embedded_test", :action => "regular_action", :caching => true %>
      cached value is <%= embed_action :controller => "caches_embedded_test", :action => "cached_action", :caching => false %>
    END
  end

  def embedded_variable_actions
    render :inline => <<-END
      regular value is <%= embed_action :controller => "caches_embedded_test", :action => "regular_action" %>
      cached value is <%= embed_action :controller => "caches_embedded_test", :action => "cached_variable_action" %>
    END
  end
  
  def forced_refresh
    render :inline => <<-END
      regular value is <%= embed_action :controller => "caches_embedded_test", :action => "regular_action" %>
      cached value is <%= embed_action :controller => "caches_embedded_test", :action => "cached_action", :refresh_cache => params[:refresh] %>
    END
  end
   
  def inline_erb_action
    render :inline => params[:erb]
  end

  # def rescue_action(e) raise e end
end

class InheritingController < CachesEmbeddedTestController
end

module Admin
  class NamespacedController < ActionController::Base
    class <<self 
      attr_accessor :test_value
    end
    
    caches_embedded :cached_action
    def cached_action
      render :text => "Namespace cache test. value: #{self.class.test_value}"
    end
  end
end

class TestNoCachingController < ActionController::Base
  class <<self 
    attr_accessor :test_value
  end

  def test_action
    render :text => "This should never cache. value: #{self.class.test_value}"
  end
end

class CachesEmbeddedTest < ActionController::TestCase
  def setup
    @controller = CachesEmbeddedTestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    FileUtils.rm_rf "#{RAILS_ROOT}/tmp/cache/views/test.host"
  end

  def test_embedded_caching
    CachesEmbeddedTestController.test_value = 1
    get :embedded_actions
    assert_equal "      regular value is 1\n      cached value is 1\n", @response.body

    CachesEmbeddedTestController.test_value = 2
    get :embedded_actions
    assert_equal "      regular value is 2\n      cached value is 1\n", @response.body
    
    @controller.expire_embedded :controller => "caches_embedded_test", :action => "cached_action"
    get :embedded_actions
    assert_equal "      regular value is 2\n      cached value is 2\n", @response.body
  end
  
  def test_should_not_return_from_cache_if_params_are_different
    CachesEmbeddedTestController.test_value = "test"
    get :cached_action, :id => 2
    assert_equal "test (id=2)", @response.body
    
    get :cached_action, :id => 3
    assert_equal "test (id=3)", @response.body
  end

  def test_ensure_caching_only_is_enabled_where_it_should_be
    TestNoCachingController.test_value = 1
    get :call_uncached_controller
    assert_equal "This should never cache. value: 1", @response.body
    
    TestNoCachingController.test_value = 2
    get :call_uncached_controller
    assert_equal "This should never cache. value: 2", @response.body
  end

  def test_should_cache_properly_with_namespaced_controllers
    Admin::NamespacedController.test_value = 1
    get :call_namespaced_action
    assert_equal "Namespace cache test. value: 1", @response.body
    
    Admin::NamespacedController.test_value = 2
    get :call_namespaced_action
    assert_equal "Namespace cache test. value: 1", @response.body
    
    @controller.expire_embedded :controller => "admin/namespaced", :action => "cached_action"
    get :call_namespaced_action
    assert_equal "Namespace cache test. value: 2", @response.body
  end

  def test_embedded_caching_overrides
    # This page uses explicit overrides to reverse which embedded actions are cached
    
    CachesEmbeddedTestController.test_value = 1
    get :embedded_overrides
    assert_equal "      regular value is 1\n      cached value is 1\n", @response.body, 'First call should not have been cached'

    CachesEmbeddedTestController.test_value = 2
    get :embedded_overrides
    assert_equal "      regular value is 1\n      cached value is 2\n", @response.body, "Second call should reflect cached value"
    
    @controller.expire_embedded :controller => "caches_embedded_test", :action => "regular_action"
    get :embedded_overrides
    assert_equal "      regular value is 2\n      cached value is 2\n", @response.body, "Expiration should have forced a refreshed value"
  end

  def test_embedded_caching_refresh
    # This page uses explicit overrides to force refreshing the cache
    
    CachesEmbeddedTestController.test_value = 1
    get :forced_refresh
    assert_equal "      regular value is 1\n      cached value is 1\n", @response.body, "First call should not have been cached"

    CachesEmbeddedTestController.test_value = 2
    get :forced_refresh
    assert_equal "      regular value is 2\n      cached value is 1\n", @response.body, "Second call should reflect the cached value"
    
    get :forced_refresh, :refresh => true
    assert_equal "      regular value is 2\n      cached value is 2\n", @response.body, "Call with refresh should reflect the new valu"

    CachesEmbeddedTestController.test_value = 3
    get :forced_refresh
    assert_equal "      regular value is 3\n      cached value is 2\n", @response.body, "Another call without refresh should reflect the cached value"
  end

  def test_caches_embedded_across_inheritance_tree
    @controller = InheritingController.new

    InheritingController.test_value = "foo"
    get :inline_erb_action, :erb => "<%= embed_action :action => 'cached_action' %>"
    assert_equal "foo", @response.body

    InheritingController.test_value = "bar"
    get :inline_erb_action, :erb => "<%= embed_action :action => 'cached_action' %>"
    assert_equal "foo", @response.body

    InheritingController.test_value = "bar"
    @controller.expire_embedded :controller => "inheriting", :action => "cached_action"
    get :inline_erb_action, :erb => "<%= embed_action :action => 'cached_action' %>"
    assert_equal "bar", @response.body
  end

  def test_caches_embedded_with_custom_options_for_cache_name
    CachesEmbeddedTestController.test_value = 1
    get :embedded_variable_actions
    assert_equal "      regular value is 1\n      cached value is 1\n", @response.body, 'First call should not have been cached'

    CachesEmbeddedTestController.test_value = 2
    get :embedded_variable_actions
    assert_equal "      regular value is 2\n      cached value is 1\n", @response.body, "Second call should reflect cached value"

    CachesEmbeddedTestController.another_value = 2
    get :embedded_variable_actions
    assert_equal "      regular value is 2\n      cached value is 2\n", @response.body, "Third call should reflect updated value since variable in cache name changed"
  end
end

