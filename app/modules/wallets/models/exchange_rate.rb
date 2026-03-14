module Wallets
  module Models
    class ExchangeRate < ApplicationRecord
      self.table_name = "exchange_rates"

      belongs_to :from_currency, class_name: "Wallets::Models::Currency"
      belongs_to :to_currency,   class_name: "Wallets::Models::Currency"

      validates :rate, :fetched_at, presence: true
      validates :rate, numericality: { greater_than: 0 }

      # Returns all rates as a nested hash: { "NGN" => { "USD" => 0.00065, ... }, ... }
      def self.as_map
        all.includes(:from_currency, :to_currency).each_with_object({}) do |er, map|
          from = er.from_currency.code
          to   = er.to_currency.code
          map[from]     ||= {}
          map[from][to]   = er.rate.to_f
        end
      end

      # Upserts a rate for a given from→to currency pair.
      def self.upsert_rate(from_code, to_code, rate)
        from = Wallets::Models::Currency.find_by_code!(from_code)
        to   = Wallets::Models::Currency.find_by_code!(to_code)

        find_or_initialize_by(from_currency: from, to_currency: to).tap do |er|
          er.rate       = rate
          er.fetched_at = Time.current
          er.save!
        end
      end
    end
  end
end
