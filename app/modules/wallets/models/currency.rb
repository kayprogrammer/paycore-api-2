module Wallets
  module Models
    class Currency < ApplicationRecord
      self.table_name = "currencies"

      has_many :wallets,          class_name: "Wallets::Models::Wallet",       foreign_key: :currency_id
      has_many :rates_from,       class_name: "Wallets::Models::ExchangeRate",  foreign_key: :from_currency_id
      has_many :rates_to,         class_name: "Wallets::Models::ExchangeRate",  foreign_key: :to_currency_id

      validates :code, :name, :symbol, presence: true
      validates :code, uniqueness: true

      scope :active, -> { where(is_active: true) }

      def self.find_by_code!(code)
        find_by!(code: code.to_s.upcase)
      end
    end
  end
end
