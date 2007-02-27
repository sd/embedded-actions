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
                     "<%= embed_action :action => 'dump_params' %>",
                     "embed_action should accept implicit controller"

    assert_embed_erb "Params: action: dump_params, controller: test, id: \n", 
                     "<%= embed_action :controller => 'test', :action => 'dump_params' %>",
                     "embed_action should accept explicit controller"
                     
    assert_embed_erb "Params: action: dump_params, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id2' %>",
                     "embed_action should pass the id"
                     
    assert_embed_erb "Params: action: dump_params, color: blue, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :params => {:color => 'blue'} %>",
                     "embed_action should pass params as expected"
                     
    assert_embed_erb "Params: action: dump_params, color: blue, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :color => 'blue' %>",
                     "embed_action should merge into params anything that's not standard"
                     
    assert_embed_erb "Params: action: dump_params, color: red, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :color => 'blue', :params => {:color => 'red'} %>",
                     "embed_action should override with the contents of params"

    assert_embed_erb "Params: action: dump_params, color: red, controller: test, id: the id\n", 
                     "<%= embed_action :action => 'dump_params', :id => 'the id', :color => 'blue', :params => {'color' => 'red'} %>",
                     "embed_action should allow indifferent access"
  end
  
  def assert_embed_erb(result, erb, msg = nil)
    TestController.send(:define_method, :test_action, Proc.new do
      render :inline => erb
    end)
    
    get :test_action
    assert_equal result, @response.body, msg
  end

end
