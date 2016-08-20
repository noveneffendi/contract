module Contract
  class SalesInvoiceDetail < ActiveRecord::Base
    belongs_to :unit_of_measure
    belongs_to :sales_invoice_header
    attr_accessible :category, :description, :number, :quantity
    self.table_name = "contract_sales_invoice_details"
  end
end
