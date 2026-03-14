module Investments
  module Schemas
    class InvestmentSchema
      def self.product(product)
        {
          id:            product.id,
          name:          product.name,
          description:   product.description,
          interest_rate: product.interest_rate.to_f,
          duration_days: product.duration_days,
          is_active:     product.is_active
        }
      end

      def self.product_collection(products)
        products.map { |p| product(p) }
      end

      def self.investment(inv)
        {
          id:                 inv.id,
          investment_product: inv.investment_product.name,
          amount_invested:    inv.amount_invested.to_f,
          expected_return:    inv.expected_return.to_f,
          status:             inv.status,
          start_date:         inv.start_date,
          end_date:           inv.end_date,
          created_at:         inv.created_at
        }
      end

      def self.investment_collection(invs)
        invs.map { |i| investment(i) }
      end

      def self.earning(earning)
        {
          id:              earning.id,
          amount:          earning.amount.to_f,
          transaction_ref: earning.transaction_record.reference,
          created_at:      earning.created_at
        }
      end

      def self.earning_collection(earnings)
        earnings.map { |e| earning(e) }
      end
    end
  end
end
