module Wallets
  # Periodic job that fetches live exchange rates from ExchangeRate-API
  # and upserts them into the exchange_rates table.
  # Scheduled via SolidQueue's recurring tasks (configured in config/recurring.yml).
  class RefreshRatesJob < ApplicationJob
    queue_as :default

    # Free tier: https://api.exchangerate-api.com/v4/latest/USD
    RATE_API_URL = "https://api.exchangerate-api.com/v4/latest/USD"
    CURRENCIES   = %w[NGN KES GHS USD].freeze

    def perform
      response = Faraday.get(RATE_API_URL)
      return unless response.success?

      data  = JSON.parse(response.body)
      rates = data["rates"]

      # Build all pairwise rates between supported currencies
      CURRENCIES.each do |from_code|
        from_in_usd = rates[from_code]
        next unless from_in_usd

        CURRENCIES.each do |to_code|
          next if from_code == to_code

          to_in_usd = rates[to_code]
          next unless to_in_usd

          # cross rate: from → USD → to
          cross_rate = to_in_usd.to_f / from_in_usd.to_f
          Wallets::Models::ExchangeRate.upsert_rate(from_code, to_code, cross_rate)
        end
      end

      Rails.logger.info("[RefreshRatesJob] Exchange rates updated at #{Time.current}")
    rescue StandardError => e
      Rails.logger.error("[RefreshRatesJob] Failed: #{e.message}")
    end
  end
end
