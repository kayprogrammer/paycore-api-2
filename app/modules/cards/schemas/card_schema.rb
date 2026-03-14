module Cards
  module Schemas
    class CardSchema
      def self.call(card)
        {
          id:               card.id,
          name_on_card:     card.name_on_card,
          card_number:      mask_card(card.card_number),
          brand:            card.brand,
          expiry:           card.expiry,
          c_type:           card.c_type,
          status:           card.status,
          provider:         card.provider,
          wallet_currency:  card.wallet.currency.code,
          created_at:       card.created_at
        }
      end

      def self.collection(cards)
        cards.map { |c| call(c) }
      end

      private

      def self.mask_card(number)
        return number if number.length <= 4
        "*" * (number.length - 4) + number[-4..-1]
      end
    end
  end
end
