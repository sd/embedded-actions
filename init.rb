require 'detect_rescue_action'
require 'embed_action'
require 'caches_embedded'

class ActionController::Base
  include ::ActionController::EmbeddedActions
  include ::ActionController::CachesEmbedded
end
