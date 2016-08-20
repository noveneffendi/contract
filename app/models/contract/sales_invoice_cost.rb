module Contract
  class SalesInvoiceCost < ActiveRecord::Base
    belongs_to :unit_of_measure
    belongs_to :sales_invoice_header
    attr_accessible :amount, :description, :discount_item, :discount_item_price, :price, :quantity
    self.table_name = "contract_sales_invoice_costs"
  end
end
