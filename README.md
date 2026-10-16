<!-- lockally-brand-header -->
<p align="center">
  <a href="https://lockally.com">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/LockallyInc/community/main/brand/lockup-dark.png">
      <img alt="Lockally" src="https://raw.githubusercontent.com/LockallyInc/community/main/brand/lockup-light.png" width="260">
    </picture>
  </a>
</p>
<!-- /lockally-brand-header -->

# lockally-rails

Official [Lockally](https://lockally.com) ActionMailer adapter for Rails. Point Rails
mail at Lockally and every `deliver`/`deliver_later` — from mailers, Devise, Action
Mailbox bounces, anything — is delivered by Lockally with no other changes.

## Install

```ruby
# Gemfile
gem "lockally-rails"
```

```bash
bundle install
```

## Configure

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :lockally
config.action_mailer.lockally_settings = {
  api_key: ENV["LOCKALLY_API_KEY"],          # lk_test_… runs in sandbox
  # base_url: "https://api.lockally.com",     # optional override
}
```

The railtie registers the `:lockally` delivery method automatically when Rails boots.

## Send

Nothing special — use ActionMailer as usual:

```ruby
class UserMailer < ApplicationMailer
  def welcome(user)
    mail(from: "alerts@yourdomain.com", to: user.email, subject: "Welcome",
         reply_to: "support@yourdomain.com")
  end
end

UserMailer.welcome(user).deliver_later
```

### Mapping notes

- **Reply-To** is sent as a header (Lockally has no `reply_to` field).
- **Attachments** are base64-encoded as `{ filename, content_type, content_base64 }`.
- Multipart mail maps its text and HTML parts to `text` / `html`.
- One `Idempotency-Key` is generated per send (24 h dedupe window).

## License

MIT © Lockally
