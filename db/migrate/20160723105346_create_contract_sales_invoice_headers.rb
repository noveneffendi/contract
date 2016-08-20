class CreateContractSalesInvoiceHeaders < ActiveRecord::Migration
  def change
    create_table :contract_sales_invoice_headers do |t|
      t.date :sales_invoice_date
      t.decimal :amount
      t.decimal :discount
      t.decimal :discount_amount
      t.boolean :tax
      t.decimal :tax_amount
      t.decimal :total_amount
      t.decimal :outstanding_total_amount
      t.text :notes
      t.integer :status
      t.string :employee_name
      t.integer :do_id
      t.string :si_id
      t.integer :so_id
      t.references :customer
      t.references :warehouse
      t.text :delivery_address
      t.integer :shipping_id
      t.date :due_date
      t.boolean :close
      t.string :gst_code
      t.integer :sales_id
      t.decimal :cash_disc
      t.integer :counter_print
      t.references :currency
      t.decimal :exchrate
      t.integer :shipment
      t.string :other_si_number
      t.integer :sales_quotation_header_id

      t.timestamps
    end
    add_index :contract_sales_invoice_headers, :customer_id
    add_index :contract_sales_invoice_headers, :warehouse_id
    add_index :contract_sales_invoice_headers, :currency_id
  end
end
