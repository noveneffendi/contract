class CreateContractSalesQuotationCosts < ActiveRecord::Migration
  def change
    create_table :contract_sales_quotation_costs do |t|
      t.string :description
      t.references :unit_of_measure
      t.decimal :quantity, :precision => 6, :scale => 2
      t.decimal :amount, :precision => 18, :scale => 2
      t.decimal :discount_item, :precision => 6,  :scale => 3
      t.decimal :discount_item_price, :precision => 18, :scale => 2
      t.decimal :price, :precision => 18, :scale => 2
      t.references :sales_quotation_header

      t.timestamps
    end
    add_index :contract_sales_quotation_costs, :unit_of_measure_id
    add_index :contract_sales_quotation_costs, :sales_quotation_header_id, :name => 'index_csq_costs_on_csq_headers'
  end
end
