class CreateContractSalesQuotationDetails < ActiveRecord::Migration
  def change
    create_table :contract_sales_quotation_details do |t|
      t.string :description
      t.references :unit_of_measure
      t.decimal :quantity, :precision => 6, :scale => 2
      t.string :category
      t.references :sales_quotation_header
      t.integer :number

      t.timestamps
    end
    add_index :contract_sales_quotation_details, :unit_of_measure_id
    add_index :contract_sales_quotation_details, :sales_quotation_header_id, :name => 'index_csq_details_on_csq_headers'
  end
end
