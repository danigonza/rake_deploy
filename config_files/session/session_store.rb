# Be sure to restart your server when you modify this file.

#Notegraphy::Application.config.session_store :cookie_store, key: '_notegraphy_session'

if `hostname`.match(/notegraphy/)
  Notegraphy::Application.config.session_store :active_record_store
  Notegraphy::Application.config.session_store :redis_store, :servers => {
      :host => "localhost",
      :port => 6379,
      :db => 0,
      :namespace => 'sessions'
  },
  :expires_in => 1.week
else
  Notegraphy::Application.config.session_store :active_record_store
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Notegraphy::Application.config.session_store :active_record_store
