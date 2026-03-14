module Payments
  module Schemas
    class PaymentSchema
      # Formats a reusable payment link
      def self.link(link)
        {
          id:          link.id,
          title:       link.title,
          description: link.description,
          amount:      link.amount ? link.amount.to_f : nil, # nil means any amount
          link_url:    link.link_url,
          currency:    link.wallet.currency.code,
          is_active:   link.is_active,
          created_at:  link.created_at
        }
      end

      def self.link_collection(links)
        links.map { |l| link(l) }
      end

      # Formats an exact invoice and its line items
      def self.invoice(invoice)
        {
          id:             invoice.id,
          invoice_number: invoice.invoice_number,
          customer_name:  invoice.customer_name,
          customer_email: invoice.customer_email,
          due_date:       invoice.due_date,
          status:         invoice.status,
          currency:       invoice.wallet.currency.code,
          subtotal:       invoice.subtotal.to_f,
          tax_rate:       invoice.tax_rate.to_f,
          total:          invoice.total.to_f,
          items:          invoice.items.map { |i| item(i) },
          created_at:     invoice.created_at
        }
      end

      def self.item(item)
        {
          id:         item.id,
          name:       item.name,
          quantity:   item.quantity,
          unit_price: item.unit_price.to_f,
          amount:     item.amount.to_f
        }
      end

      def self.invoice_collection(invoices)
        invoices.map { |i| invoice(i) }
      end
    end
  end
end
