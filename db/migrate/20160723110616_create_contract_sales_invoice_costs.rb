class CreateContractSalesInvoiceCosts < ActiveRecord::Migration
  def change
    create_table :contract_sales_invoice_costs do |t|
      t.string :description
      t.references :unit_of_measure
      t.decimal :quantity, :precision => 6, :scale => 2
      t.decimal :amount, :precision => 18, :scale => 2
      t.decimal :discount_item, :precision => 6,  :scale => 3
      t.decimal :discount_item_price, :precision => 18, :scale => 2
      t.decimal :price, :precision => 18, :scale => 2
      t.references :sales_invoice_header

      t.timestamps
    end
    add_index :contract_sales_invoice_costs, :unit_of_measure_id
    add_index :contract_sales_invoice_costs, :sales_invoice_header_id, :name => 'index_sic_on_sih'
  end
end
