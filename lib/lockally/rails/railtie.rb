# frozen_string_literal: true

require "rails/railtie"
require "lockally/rails/delivery_method"

module Lockally
  module Rails
    # Registers the `:lockally` ActionMailer delivery method when Rails boots.
    class Railtie < ::Rails::Railtie
      initializer "lockally.add_delivery_method" do
        ActiveSupport.on_load(:action_mailer) do
          add_delivery_method(:lockally, Lockally::Rails::DeliveryMethod)
        end
      end
    end
  end
end
