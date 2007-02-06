class EmbededActionsTestController < ActionController::Base
  cattr_accessor :test_value

  caches_embeded :cached_action
  def cached_action
    @id = params[:id]
    @value = EmbededActionsTestController.test_value || "N/A"
    
    render :template => "embeded_actions_test/value", :layout => false
  end
  
  def regular_action
    @id = params[:id]
    @value = EmbededActionsTestController.test_value || "N/A"
    
    render :template => "embeded_actions_test/value", :layout => false
  end
  
  def page_with_embeded_actions
  end

  def page_with_embeded_actions_and_overrides
  end

end

