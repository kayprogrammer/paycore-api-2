module Bills
  module Schemas
    class BillSchema
      # Formats a single bill category (with nested providers)
      def self.category_with_providers(category)
        {
          id:        category.id,
          name:      category.name,
          slug:      category.slug,
          icon_url:  category.icon_url,
          providers: category.providers.active.map { |p| provider(p) }
        }
      end

      # Formats a single bill provider
      def self.provider(provider)
        {
          id:            provider.id,
          name:          provider.name,
          slug:          provider.slug,
          logo_url:      provider.logo_url,
          provider_code: provider.provider_code
        }
      end

      # Formats a bill payment record
      def self.payment(payment)
        {
          id:          payment.id,
          provider:    payment.provider.name,
          amount:      payment.amount.to_f,
          fee:         payment.fee.to_f,
          customer_id: payment.customer_id,
          status:      payment.status,
          reference:   payment.reference,
          created_at:  payment.created_at
        }
      end

      def self.payment_collection(payments)
        payments.map { |p| payment(p) }
      end
    end
  end
end
