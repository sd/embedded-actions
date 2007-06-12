require File.expand_path(File.dirname(__FILE__) + "/rails/test/test_helper")

# Add 'lib' to ruby's library path and load the plugin libraries (code copied from Rails railties initializer's load_plugin)
#lib_path  = File.expand_path(File.dirname(__FILE__) + "/../lib")
#application_lib_index = $LOAD_PATH.index(File.join(RAILS_ROOT, "lib")) || 0  
#$LOAD_PATH.insert(application_lib_index + 1, lib_path)
#require File.expand_path(File.dirname(__FILE__) + "/../init")

# Re-raise errors caught by the controller.
class TestController; def rescue_action(e) raise e end; end

class RespondsToTest < Test::Unit::TestCase
  def setup
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_responds_to_embedded
    TestController.class_eval do
      def action_with_respond_to
        respond_to do |format|
          format.html     { render :inline => "html content"     }
          format.embedded { render :inline => "embedded content" }
          format.all      { render :inline => "catch all" }
        end
      end
    end
    
    assert_embed_erb "embedded content", 
                     "<%= embed_action :action => 'action_with_respond_to' %>",
                     "should respond with embedded content"
    assert_equal "text/html", @response.content_type

    get :action_with_respond_to
    assert_equal "html content", @response.body, "should respond with html content"
    assert_equal "text/html", @response.content_type
  end
end
