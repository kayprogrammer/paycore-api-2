module Cards
  module Services
    class CardService
      # ------------------------------------------------------------- #
      # Create Virtual Card                                           #
      # Initializes a new virtual card linked to a user's wallet.     #
      # Integrates with a provider like Flutterwave API.              #
      # ------------------------------------------------------------- #
      def self.create_virtual_card!(user:, currency_code:, name_on_card:, amount_to_fund:)
        wallet = ::Wallets::Services::WalletService.find_wallet!(user, currency_code)

        # In a real app, you would charge an issuance fee (e.g., $2) + the funding amount.
        # For this mockup, we'll just check if they have the funding amount.
        issuance_fee = 2.0
        total_cost = amount_to_fund + issuance_fee

        raise "Wallet is locked" if wallet.is_locked?
        raise "Insufficient balance to fund card and pay $2 issuance fee" if wallet.balance < total_cost

        # 1. Debit the wallet for the total cost
        # (This would ideally be wrapped in the same transaction as the card creation,
        # but API calls should usually happen *outside* DB transactions to avoid lock contention).

        # MOCK API CALL TO FLUTTERWAVE/SUDO
        # response = FlutterwaveClient.create_virtual_card(
        #   currency: currency_code,
        #   amount: amount_to_fund,
        #   name: name_on_card
        # )

        # Simulating a successful API response:
        mock_api_response = {
          status: "success",
          data: {
            id: "flw-vc-#{SecureRandom.hex(8)}",
            card_pan: "4111#{SecureRandom.rand(1000..9999)}#{SecureRandom.rand(1000..9999)}1111",
            cvv: SecureRandom.rand(100..999).to_s,
            expiration: "12/28",
            card_type: "Visa"
          }
        }

        card = nil
        ActiveRecord::Base.transaction do
          # Deduct funds
          wallet.debit!(total_cost)

          # Record the transaction for the deduction
          Transactions::Models::Transaction.create!(
            user:        user,
            wallet:      wallet,
            t_type:      "payment",
            amount:      total_cost,
            fee:         issuance_fee,
            status:      "successful",
            description: "Virtual card creation + initial funding"
          )

          # Create the local card record
          card = Cards::Models::Card.create!(
            user:             user,
            wallet:           wallet,
            name_on_card:     name_on_card,
            card_number:      mock_api_response[:data][:card_pan],
            expiry:           mock_api_response[:data][:expiration],
            cvv:              mock_api_response[:data][:cvv],
            brand:            mock_api_response[:data][:card_type],
            c_type:           "virtual",
            status:           "active",
            provider:         "mock", # "flutterwave" in prod
            provider_card_id: mock_api_response[:data][:id]
          )
        end

        [ card, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      # ------------------------------------------------------------- #
      # Freeze Card                                                   #
      # Temporarily suspends the card.                                #
      # ------------------------------------------------------------- #
      def self.freeze_card!(user, card_id)
        card = find_card!(user, card_id)
        raise "Card is already terminated" if card.terminated?
        raise "Card is already frozen" if card.frozen?

        # MOCK API CALL
        # FlutterwaveClient.freeze_card(card.provider_card_id)

        card.freeze!
        [ card, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      # ------------------------------------------------------------- #
      # Unfreeze Card                                                 #
      # Re-activates a frozen card.                                   #
      # ------------------------------------------------------------- #
      def self.unfreeze_card!(user, card_id)
        card = find_card!(user, card_id)
        raise "Card is already terminated" if card.terminated?
        raise "Card is already active" if card.active?

        # MOCK API CALL
        # FlutterwaveClient.unfreeze_card(card.provider_card_id)

        card.unfreeze!
        [ card, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      # ------------------------------------------------------------- #
      # Terminate Card                                                #
      # Permanently disables the card.                                #
      # ------------------------------------------------------------- #
      def self.terminate_card!(user, card_id)
        card = find_card!(user, card_id)
        raise "Card is already terminated" if card.terminated?

        # MOCK API CALL
        # FlutterwaveClient.terminate_card(card.provider_card_id)

        card.terminate!
        [ card, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      private

      def self.find_card!(user, card_id)
        user.cards.find(card_id)
      rescue ActiveRecord::RecordNotFound
        raise "Card not found"
      end
    end
  end
end
