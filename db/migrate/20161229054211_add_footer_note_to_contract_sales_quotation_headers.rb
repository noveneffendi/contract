class AddFooterNoteToContractSalesQuotationHeaders < ActiveRecord::Migration
  def change
    add_column :contract_sales_quotation_headers, :footer_note, :text
  end
end
