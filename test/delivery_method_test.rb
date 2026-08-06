# frozen_string_literal: true

require "minitest/autorun"
require "base64"
require "mail"
require "lockally/rails/delivery_method"

class FakeSendApi
  attr_reader :calls

  def initialize
    @calls = []
  end

  def v1_send_post(idempotency_key, request)
    @calls << [idempotency_key, request]
    nil
  end
end

class DeliveryMethodTest < Minitest::Test
  def setup
    @fake = FakeSendApi.new
    @method = Lockally::Rails::DeliveryMethod.new(send_api: @fake)
  end

  def multipart_mail
    Mail.new do
      from "alerts@acme.com"
      to "user@example.com"
      cc "cc@example.com"
      reply_to "reply@acme.com"
      subject "Your code"
      text_part { body "code 123" }
      html_part { content_type "text/html; charset=UTF-8"; body "<b>code 123</b>" }
      add_file filename: "invoice.pdf", content: "BYTES"
    end
  end

  def test_maps_multipart_message
    req = @method.build_request(multipart_mail)

    assert_equal "alerts@acme.com", req.from
    assert_equal ["user@example.com"], req.to
    assert_equal ["cc@example.com"], req.cc
    assert_equal "Your code", req.subject
    assert_equal "code 123", req.text
    assert_equal "<b>code 123</b>", req.html
    assert_equal "reply@acme.com", req.headers["Reply-To"]

    assert_equal 1, req.attachments.length
    att = req.attachments.first
    assert_equal "invoice.pdf", att.filename
    assert_equal "application/pdf", att.content_type
    assert_equal Base64.strict_encode64("BYTES"), att.content_base64
  end

  def test_html_only_message
    mail = Mail.new do
      from "a@acme.com"
      to "b@example.com"
      subject "Hi"
      content_type "text/html; charset=UTF-8"
      body "<p>hello</p>"
    end
    req = @method.build_request(mail)
    assert_equal "<p>hello</p>", req.html
    assert_nil req.text
  end

  def test_deliver_calls_api_with_idempotency_key
    mail = Mail.new do
      from "a@acme.com"
      to "b@example.com"
      subject "Hi"
      body "yo"
    end
    @method.deliver!(mail)

    assert_equal 1, @fake.calls.length
    key, request = @fake.calls.first
    assert key.start_with?("lk-")
    assert_equal "a@acme.com", request.from
    assert_equal "yo", request.text
  end
end
