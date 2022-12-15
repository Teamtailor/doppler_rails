# frozen_string_literal: true

require_relative "doppler-rails/version"
require "faraday"
require "rails"

module DopplerRails
  RETRY_EXCEPTIONS = [Faraday::ConnectionFailed, *Faraday::Request::Retry::DEFAULT_EXCEPTIONS].freeze
  TOKEN = ENV["DOPPLER_TOKEN"]
  FALLBACK_FILE_PATH = ENV["DOPPLER_FALLBACK_FILE_PATH"]

  module_function

  def load_secrets
    Operations.fetch_enviroment_variables
  end

  module Operations
    module_function

    def fetch_enviroment_variables
      return if TOKEN.blank?
      response = connection.get("configs/config/secrets/download?format=json")
      if response.success?
        store_fallback(response.body)
        ENV.update(JSON.parse(response.body))
      else
        use_fallback_if_present
      end
    rescue Faraday::Error
      use_fallback_if_present
    end

    def store_fallback(secrets)
      return unless FALLBACK_FILE_PATH.present?
      File.write(FALLBACK_FILE_PATH, encrypt(secrets), encoding: "ascii-8bit")
    end

    def use_fallback_if_present
      return unless FALLBACK_FILE_PATH.present?
      return unless File.exist?(FALLBACK_FILE_PATH)
      secrets = decrypt(File.read(FALLBACK_FILE_PATH, encoding: "ascii-8bit"))
      ENV.update(JSON.parse(secrets))
    end

    def connection
      Faraday.new("https://api.doppler.com/v3/") do |conn|
        conn.request :basic_auth, TOKEN, ""
        conn.request :retry, max: 3, interval: 0.3, backoff_factor: 2, exceptions: RETRY_EXCEPTIONS
      end
    end

    def decrypt(message)
      encrypted, salt = message.split("\n", 2)
      key = ActiveSupport::KeyGenerator.new(TOKEN).generate_key(Base64.urlsafe_decode64(salt), ActiveSupport::MessageEncryptor.key_len)
      ActiveSupport::MessageEncryptor.new(key).decrypt_and_verify(encrypted)
    end

    def encrypt(secrets)
      salt = SecureRandom.random_bytes(ActiveSupport::MessageEncryptor.key_len)
      key = ActiveSupport::KeyGenerator.new(TOKEN).generate_key(salt, ActiveSupport::MessageEncryptor.key_len)
      ActiveSupport::MessageEncryptor.new(key).encrypt_and_sign(secrets) + "\n" + Base64.urlsafe_encode64(salt)
    end
  end

  class Railtie < Rails::Railtie
    config.before_configuration do
      DopplerRails.load_secrets
    end
  end
end
