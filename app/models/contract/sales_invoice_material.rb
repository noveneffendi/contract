module Contract
  class SalesInvoiceMaterial < ActiveRecord::Base
    belongs_to :product
    belongs_to :unit_of_measure
    belongs_to :sales_invoice_detail
    attr_accessible :amount, :discount_item, :discount_item_price, :number, :outstanding_qty, :price, :quantity
  	self.table_name = "contract_sales_invoice_materials"
  end
end
