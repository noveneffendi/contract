class CreateContractOtherSalesInvoiceDetails < ActiveRecord::Migration
  def change
    create_table :contract_other_sales_invoice_details do |t|
      t.string :description
      t.decimal :quantity, :precision => 12, :scale => 5, :default => 0
      t.decimal :discount_item, :precision => 6, :scale => 2, :default => 0
      t.decimal :discount_item_price, :precision => 18, :scale => 2, :default => 0
      t.decimal :price, :precision => 18, :scale => 2, :default => 0
      t.decimal :total_amount, :precision => 20, :scale => 2, :default => 0
      t.references :other_sales_invoice_header

      t.timestamps
    end
    add_index :contract_other_sales_invoice_details, :other_sales_invoice_header_id, :name => 'index_cosi_details_on_cosi_headers'
  end
end
