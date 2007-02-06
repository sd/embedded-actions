# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.1.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.frameworks -= [ :action_web_service, :action_mailer ]

  config.plugin_paths = ["#{RAILS_ROOT}/../../.."] # this should match the top level directory containing the 'components' plugin

  config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"
  config.action_controller.perform_caching             = true
end
