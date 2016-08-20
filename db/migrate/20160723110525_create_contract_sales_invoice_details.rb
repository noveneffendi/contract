class CreateContractSalesInvoiceDetails < ActiveRecord::Migration
  def change
    create_table :contract_sales_invoice_details do |t|
      t.string :description
      t.references :unit_of_measure
      t.decimal :quantity, :precision => 6, :scale => 2
      t.string :category
      t.references :sales_invoice_header
      t.integer :number

      t.timestamps
    end
    add_index :contract_sales_invoice_details, :unit_of_measure_id
    add_index :contract_sales_invoice_details, :sales_invoice_header_id
  end
end
