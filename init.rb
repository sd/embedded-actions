require 'embedded_actions/detect_rescue_action'
require 'embedded_actions/embed_action'
require 'embedded_actions/caches_embedded'

class ActionController::Base
  include ::ActionController::EmbeddedActions
  include ::ActionController::CachesEmbedded
end
