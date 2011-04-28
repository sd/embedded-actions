class TestController < ActionController::Base
  def inline_erb_action
    render :inline => params[:erb]
  end

  def dump_params
    render :text => "Params: #{params.keys.sort.collect {|name| "#{name}: #{params[name]}"}.join ", "}"
  end
  
  def action_with_respond_to
    respond_to do |format|
      format.html     { render :inline => "html content"     }
      format.embedded { render :inline => "embedded content" }
      format.all      { render :inline => "catch all" }
    end
  end

  def action_that_calls_action_with_respond_to
    render :inline => "<%= embed_action :action => 'action_with_respond_to' %>"
  end
  
  def mime_test_1
    respond_to do |format|
      format.html     { render }
      format.embedded { render }
      format.all      { render :inline => "format not found" }
    end
  end

  def mime_test_2
    respond_to do |format|
      format.html     { render }
      format.embedded { render }
      format.all      { render :inline => "format not found" }
    end
  end

  def mime_test_3
    respond_to do |format|
      format.html     { render }
      format.embedded { render }
      format.all      { render :inline => "format not found" }
    end
  end
end

