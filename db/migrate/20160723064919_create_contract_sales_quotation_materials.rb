class CreateContractSalesQuotationMaterials < ActiveRecord::Migration
  def change
    create_table :contract_sales_quotation_materials do |t|
      t.references :product
      t.references :unit_of_measure
      t.decimal :quantity, :precision => 12, :scale => 5
      t.decimal :price, :precision => 18, :scale => 2
      t.decimal :discount_item, :precision => 6,  :scale => 3
      t.decimal :discount_item_price, :precision => 18, :scale => 2
      t.decimal :amount, :precision => 18, :scale => 2
      t.decimal :outstanding_qty, :precision => 12, :scale => 5
      t.references :sales_quotation_detail
      t.integer :number

      t.timestamps
    end
    add_index :contract_sales_quotation_materials, :product_id
    add_index :contract_sales_quotation_materials, :unit_of_measure_id
    add_index :contract_sales_quotation_materials, :sales_quotation_detail_id
  end
end
