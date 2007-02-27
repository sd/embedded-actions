ENV["RAILS_ENV"] = "test"
# To test the embedded_actions plugin, we use a minimal rails setup located in the 'test/rails' directory.
# The following line loads that rails app environment
require File.expand_path(File.dirname(__FILE__) + "/rails/config/environment")
require 'application'
require 'test_controller'

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

class EmbeddedActionTest < Test::Unit::TestCase
  def setup
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    FileUtils.rm_rf "#{RAILS_ROOT}/tmp/cache/test.host"
  end

  def test_embed_action
    assert_embed_erb "Params: action: dump_params, controller: test, id: \n", 
                     "<%= embed_action :action => 'dump_params' %>"
    assert_embed_erb "Params: action: dump_params, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id' %>"
    assert_embed_erb "Params: action: dump_params, color: blue, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :params => {:color => 'blue'} %>"
    assert_embed_erb "Params: action: dump_params, color: blue, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :color => 'blue' %>"
    assert_embed_erb "Params: action: dump_params, color: red, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :color => 'blue', :params => {:color => 'red'} %>"
    assert_embed_erb "Params: action: dump_params, color: red, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :color => 'blue', :params => {'color' => 'red'} %>"
  end
  
  def assert_embed_erb(result, erb)
    TestController.send(:define_method, :test_action, Proc.new do
      render :inline => erb
    end)
    
    get :test_action
    assert_equal result, @response.body
  end

end
