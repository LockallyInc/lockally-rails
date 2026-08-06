# frozen_string_literal: true

require_relative "lib/lockally/rails/version"

Gem::Specification.new do |s|
  s.name        = "lockally-rails"
  s.version     = Lockally::Rails::VERSION
  s.summary     = "Official Lockally ActionMailer adapter for Rails"
  s.description = "Send transactional email from Rails through Lockally by setting " \
                  "config.action_mailer.delivery_method = :lockally."
  s.authors     = ["Lockally"]
  s.email       = ["support@lockally.com"]
  s.homepage    = "https://github.com/lockallyinc/lockally-rails"
  s.license     = "MIT"
  s.metadata    = {
    "homepage_uri" => "https://lockally.com",
    "source_code_uri" => "https://github.com/lockallyinc/lockally-rails",
  }

  s.required_ruby_version = ">= 2.7"
  s.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  s.require_paths = ["lib"]

  s.add_runtime_dependency "lockally", ">= 0.1", "< 1"
  s.add_runtime_dependency "mail", ">= 2.7"
  s.add_runtime_dependency "railties", ">= 6.1"

  s.add_development_dependency "minitest", ">= 5.0"
  s.add_development_dependency "rake", ">= 13.0"
end
