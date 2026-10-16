# frozen_string_literal: true

require "base64"
require "securerandom"
require "lockally"

module Lockally
  module Rails
    # ActionMailer delivery method that sends through the Lockally API (POST /v1/send).
    #
    # Registered as `:lockally` by the railtie, so:
    #
    #   config.action_mailer.delivery_method = :lockally
    #   config.action_mailer.lockally_settings = { api_key: ENV["LOCKALLY_API_KEY"] }
    #
    # routes every ActionMailer `deliver`/`deliver_later` through Lockally.
    class DeliveryMethod
      attr_reader :settings

      def initialize(settings = {})
        @settings = settings || {}
        @send_api = settings[:send_api] # injectable for tests
      end

      # ActionMailer calls this with a Mail::Message.
      def deliver!(mail)
        send_api.v1_send_post(idempotency_key, build_request(mail))
      end

      # Map a Mail::Message onto the Lockally send request. Public for unit testing.
      def build_request(mail)
        ::Lockally::V1SendPostRequest.new(build_payload(mail))
      end

      def build_payload(mail)
        payload = {
          from: Array(mail.from).first,
          to: Array(mail.to),
        }
        payload[:cc] = Array(mail.cc) if mail.cc
        payload[:bcc] = Array(mail.bcc) if mail.bcc
        payload[:subject] = mail.subject if mail.subject

        text, html = bodies(mail)
        payload[:text] = text if text
        payload[:html] = html if html

        headers = custom_headers(mail)
        payload[:headers] = headers unless headers.empty?

        attachments = mail.attachments.map do |part|
          ::Lockally::V1SendPostRequestAttachmentsInner.new(
            filename: part.filename || "attachment",
            content_type: part.mime_type || "application/octet-stream",
            content_base64: Base64.strict_encode64(part.body.decoded),
          )
        end
        payload[:attachments] = attachments unless attachments.empty?

        payload
      end

      private

      # Returns [text, html]. Handles multipart and single-part messages.
      def bodies(mail)
        if mail.multipart?
          text = mail.text_part&.body&.decoded
          html = mail.html_part&.body&.decoded
          [text, html]
        elsif mail.mime_type == "text/html"
          [nil, mail.body.decoded]
        else
          [mail.body.decoded, nil]
        end
      end

      # Lockally has no reply_to field, so Reply-To is carried in headers; standard
      # MIME headers the Mail gem manages are skipped.
      def custom_headers(mail)
        managed = %w[from to cc bcc subject reply-to sender date message-id
                     content-type content-transfer-encoding mime-version]
        out = {}
        out["Reply-To"] = Array(mail.reply_to).join(", ") if mail.reply_to
        mail.header.fields.each do |field|
          next if managed.include?(field.name.downcase)

          out[field.name] = field.value.to_s
        end
        out
      end

      def send_api
        @send_api ||= begin
          config = ::Lockally::Configuration.new
          config.access_token = settings[:api_key]
          if settings[:base_url]
            require "uri"
            uri = URI.parse(settings[:base_url])
            config.scheme = uri.scheme if uri.scheme
            config.host = [uri.host, uri.port].compact.join(":")
          end
          ::Lockally::SendApi.new(::Lockally::ApiClient.new(config))
        end
      end

      def idempotency_key
        "lk-#{SecureRandom.hex(16)}"
      end
    end
  end
end
