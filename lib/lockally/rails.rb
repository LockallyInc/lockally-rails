# frozen_string_literal: true

require "lockally"
require "lockally/rails/version"
require "lockally/rails/delivery_method"
# Load the railtie only when running inside Rails (so the delivery method can also
# be used standalone, e.g. in tests or non-Rails apps).
require "lockally/rails/railtie" if defined?(::Rails::Railtie)

module Lockally
  # ActionMailer adapter for Lockally. See Lockally::Rails::DeliveryMethod.
  module Rails
  end
end
