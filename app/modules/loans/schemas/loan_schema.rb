module Loans
  module Schemas
    class LoanSchema
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

      def self.application(app)
        {
          id:              app.id,
          loan_product:    app.loan_product.name,
          amount:          app.amount.to_f,
          amount_to_repay: app.amount_to_repay.to_f,
          amount_repaid:   app.amount_repaid.to_f,
          status:          app.status,
          due_date:        app.due_date,
          created_at:      app.created_at
        }
      end

      def self.application_collection(apps)
        apps.map { |a| application(a) }
      end

      def self.repayment(rep)
        {
          id:              rep.id,
          amount:          rep.amount.to_f,
          transaction_ref: rep.transaction_record.reference,
          created_at:      rep.created_at
        }
      end

      def self.repayment_collection(repayments)
        repayments.map { |r| repayment(r) }
      end
    end
  end
end
