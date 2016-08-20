class CreateContractSalesInvoiceMaterials < ActiveRecord::Migration
  def change
    create_table :contract_sales_invoice_materials do |t|
      t.references :product
      t.references :unit_of_measure
      t.decimal :quantity, :precision => 12, :scale => 5
      t.decimal :price, :precision => 18, :scale => 2
      t.decimal :discount_item, :precision => 6,  :scale => 3
      t.decimal :discount_item_price, :precision => 18, :scale => 2
      t.decimal :amount, :precision => 18, :scale => 2
      t.decimal :outstanding_qty, :precision => 12, :scale => 5
      t.references :sales_invoice_detail
      t.integer :number

      t.timestamps
    end
    add_index :contract_sales_invoice_materials, :product_id
    add_index :contract_sales_invoice_materials, :unit_of_measure_id
    add_index :contract_sales_invoice_materials, :sales_invoice_detail_id, :name => 'index_sim_on_sid'
  end
end
