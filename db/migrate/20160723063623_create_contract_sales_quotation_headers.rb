class CreateContractSalesQuotationHeaders < ActiveRecord::Migration
  def change
    create_table :contract_sales_quotation_headers do |t|
      t.date :sales_quotation_date
      t.string :contact_person
      t.text :notes
      t.decimal :amount, :precision => 18, :scale => 2
      t.decimal :discount, :precision => 6,  :scale => 3
      t.decimal :discount_amount, :precision => 18, :scale => 2
      t.boolean :tax
      t.decimal :tax_amount, :precision => 18, :scale => 2
      t.decimal :total_amount, :precision => 18, :scale => 2
      t.string :employee_name
      t.integer :status, :limit => 2, :default => 0
      t.string :sq_id
      t.integer :customer_id
      t.text :approval_notes
      t.boolean :close, :default => false
      t.integer :sales_id
      t.decimal :cash_disc, :precision => 5,  :scale => 3
      t.references :currency
      t.decimal :exchrate, :precision => 18, :scale => 2, :default => 0.0
      t.integer :rev_number, :limit => 2, :default => 0

      t.timestamps
    end
    add_index :contract_sales_quotation_headers, :currency_id
  end
end
