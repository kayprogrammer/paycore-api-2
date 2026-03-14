module Bills
  module Models
    class BillProvider < ApplicationRecord
      self.table_name = "bill_providers"

      belongs_to :category, class_name: "Bills::Models::BillCategory", foreign_key: :bill_category_id
      has_many   :payments, class_name: "Bills::Models::BillPayment", foreign_key: :bill_provider_id

      validates :name, :slug, :provider_code, presence: true
      validates :slug, uniqueness: true

      scope :active, -> { where(is_active: true) }
    end
  end
end
