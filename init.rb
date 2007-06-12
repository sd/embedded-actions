require 'embedded_actions/detect_rescue_action'
require 'embedded_actions/embed_action'
require 'embedded_actions/caches_embedded'

class ActionController::Base
  include ::ActionController::EmbeddedActions
  include ::ActionController::CachesEmbedded
end

Mime::Type.register "application/x-embedded_action", :embedded
Mime::Type.register "application/x-embeded_action",  :embeded
Mime::Type.register "application/x-embed_action",    :embed
