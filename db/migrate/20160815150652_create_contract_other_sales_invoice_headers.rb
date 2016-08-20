class CreateContractOtherSalesInvoiceHeaders < ActiveRecord::Migration
  def change
    create_table :contract_other_sales_invoice_headers do |t|
      t.date :sales_invoice_date
      t.string :si_id, :limit => 14
      t.decimal :amount, :precision => 18, :scale => 2, :default => 0
      t.decimal :discount, :precision => 6, :scale => 2, :default => 0
      t.decimal :discount_amount, :precision => 18, :scale => 2, :default => 0
      t.boolean :tax
      t.decimal :tax_amount, :precision => 18, :scale => 2, :default => 0
      t.decimal :total_amount, :precision => 20, :scale => 2, :default => 0
      t.decimal :outstanding_total_amount, :precision => 20, :scale => 2, :default => 0
      t.text :notes
      t.integer :status, :limit => 1, :default => 0
      t.string :employee_name
      t.references :customer
      t.boolean :close, :default => true
      t.references :currency
      t.decimal :exchrate, :precision => 18, :scale => 2, :default => 0
      t.string :fp_code
      t.integer :sales_id
      t.integer :counter_print, :limit => 1
      t.date :due_date
      t.references :sales_quotation_header

      t.timestamps
    end
    add_index :contract_other_sales_invoice_headers, :customer_id
    add_index :contract_other_sales_invoice_headers, :currency_id
  end
end
