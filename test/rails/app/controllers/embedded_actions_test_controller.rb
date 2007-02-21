class EmbeddedActionsTestController < ActionController::Base
  cattr_accessor :test_value

  caches_embedded :cached_action
  def cached_action
    @id = params[:id]
    @value = EmbeddedActionsTestController.test_value || "N/A"
    
    render :template => "embedded_actions_test/value", :layout => false
  end
  
  def regular_action
    @id = params[:id]
    @value = EmbeddedActionsTestController.test_value || "N/A"
    
    render :template => "embedded_actions_test/value", :layout => false
  end
  
  def page_with_embedded_actions
  end

  def page_with_embedded_actions_and_overrides
  end

  def page_with_forced_refresh
  end

end

