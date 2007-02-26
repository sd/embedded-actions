class TestController < ActionController::Base
  cattr_accessor :test_value

  caches_embedded :cached_action
  def cached_action
    @id = params[:id]
    @value = TestController.test_value || "N/A"
    
    render :template => "test/value", :layout => false
  end
  
  def regular_action
    @id = params[:id]
    @value = TestController.test_value || "N/A"
    
    render :template => "test/value", :layout => false
  end
  
  def embedded_actions
  end

  def embedded_with_overrides
  end

  def forced_refresh
  end
  
  def dump_params
  end
end

