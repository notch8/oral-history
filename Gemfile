source "https://rubygems.org"

gem "rails", "~> 7.2.1", ">= 7.2.1.1"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ jruby ]
gem "bootsnap", require: false
gem "blacklight", '8.6.0'
gem "twitter-typeahead-rails", "0.11.1.pre.corejavascript"
gem "jquery-rails"
gem 'faraday', '< 2.0'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "web-console"
  gem "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails", '~> 3.8'
  gem "spring"
  gem "spring-watcher-listen", '~> 2.0.0'
end

# Original gems
gem "delayed_job_web"
gem "blacklight-marc", '8.1.4'
gem "blacklight_dynamic_sitemap"
gem "byebug", platforms: [:mri, :mingw, :x64_mingw], group: [:development, :test]
gem "coffee-rails", '~> 4.2'
gem "daemons"
gem "delayed_job_active_record", '~> 4.1.4'
gem "devise", '~> 4.9'
gem "devise-guests", '~> 0.6'
gem "font-awesome-rails"
gem "json-waveform"
gem "hashdiff", '~> 1.0.1'
gem "language_list"
gem "libxml-ruby"
gem "listen", '~> 3.3', group: [:development]
gem "mods"
gem "negative_captcha"
gem "oai", '>= 1.1.0'
gem "progress_bar"
gem "progress_job"
gem "rollbar"
gem "ruby-audio", '~> 1.6.0'
gem "sass-rails", '>= 6'
gem "sentry-raven"
gem "tzinfo", '~> 2.0', '>= 2.0.6'
gem "uglifier", '>= 1.3.0'
gem "turbolinks", '~> 5'
gem "view_component", '~> 2.74'
gem "whenever", require: false

# Webpacker is removed in Rails 7, replaced by jsbundling-rails and importmap
# However, keeping webpacker for backward compatibility (if needed)
# gem "webpacker", '~> 3.1.0'
# gem "webpacker-react", "~> 0.3.2"

group :development, :test do
  gem "solr_wrapper", ">= 0.3"
end
gem "rsolr", ">= 1.0", "< 3"
gem "bootstrap", "~> 5.3"
gem "sassc-rails", "~> 2.1"
