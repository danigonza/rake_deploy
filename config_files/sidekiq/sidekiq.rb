Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://localhost:6379/12', :namespace => 'bgjobs' }
  config.poll_interval = 5
end

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://localhost:6379/12', :namespace => 'bgjobs' }
end
