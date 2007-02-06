ENV["RAILS_ENV"] = "test"
# To test the embeded_actions plugin, we use a minimal rails setup located in the 'test/rails' directory.
# The following line loads that rails app environment
require File.expand_path(File.dirname(__FILE__) + "/rails/config/environment")
require 'application'

require 'test/unit'  
require 'action_controller/test_process'
require 'breakpoint'

require 'test_help'

# Add 'lib' to ruby's library path and load the plugin libraries (code copied from Rails railties initializer's load_plugin)
#lib_path  = File.expand_path(File.dirname(__FILE__) + "/../lib")
#application_lib_index = $LOAD_PATH.index(File.join(RAILS_ROOT, "lib")) || 0  
#$LOAD_PATH.insert(application_lib_index + 1, lib_path)
#require File.expand_path(File.dirname(__FILE__) + "/../init")

# Re-raise errors caught by the controller.
class TestController; def rescue_action(e) raise e end; end

class CachesEmbededTest < Test::Unit::TestCase
  def setup
    @controller = EmbededActionsTestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    FileUtils.rm_rf "#{RAILS_ROOT}/tmp/cache/test.host"
  end

  def test_embeded_caching
    EmbededActionsTestController.test_value = 1
    get :page_with_embeded_actions
    assert_equal "regular value is 1\ncached value is 1", @response.body

    EmbededActionsTestController.test_value = 2
    get :page_with_embeded_actions
    assert_equal "regular value is 2\ncached value is 1", @response.body
    
    @controller.expire_embeded :controller => "embeded_actions_test", :action => "cached_action"
    get :page_with_embeded_actions
    assert_equal "regular value is 2\ncached value is 2", @response.body
  end

  def test_embeded_caching_overrides
    # This page uses explicit overrides to reverse which embeded actions are cached
    
    EmbededActionsTestController.test_value = 1
    get :page_with_embeded_actions_and_overrides
    assert_equal "regular value is 1\ncached value is 1", @response.body

    EmbededActionsTestController.test_value = 2
    get :page_with_embeded_actions_and_overrides
    assert_equal "regular value is 2\ncached value is 2", @response.body
    
    @controller.expire_embeded :controller => "embeded_actions_test", :action => "regular_action"
    get :page_with_embeded_actions_and_overrides
    assert_equal "regular value is 2\ncached value is 2", @response.body
  end
end
