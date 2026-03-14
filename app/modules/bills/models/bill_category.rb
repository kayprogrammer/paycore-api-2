module Bills
  module Models
    class BillCategory < ApplicationRecord
      self.table_name = "bill_categories"

      has_many :providers, class_name: "Bills::Models::BillProvider", foreign_key: :bill_category_id

      validates :name, :slug, presence: true
      validates :slug, uniqueness: true

      scope :active, -> { where(is_active: true) }
    end
  end
end
