require 'contract/filter'

module Contract
  class OtherSalesInvoiceHeader < ActiveRecord::Base
  	include Contract::Filter
  	self.table_name = 'contract_other_sales_invoice_headers'
  	OT_SI_PREFIX_DEFAULT = 'ST-'

  	belongs_to :customer
  	belongs_to :currency
  	has_many :other_sales_invoice_details

    after_create :insert_expense_from_quotation, :if => "sales_quotation_header_id != 0"

  	attr_accessible :amount, :close, :counter_print, :discount, :employee_name, :exchrate, :fp_code, 
  		:notes, :outstanding_total_amount, :sales_id, :sales_invoice_date, :si_id, :status, :tax, 
  		:tax_amount, :total_amount, :due_date, :customer_id, :currency_id, :discount_amount, :sales_quotation_header_id

  	cattr_accessor :revision_status

  	scope :with_sq_id, lambda { |sq_id| where(:sales_quotation_header_id => sq_id) }
    scope :posted, where(:status => 1).order("si_id DESC")
  	scope :with_tax, where(:tax => true)
  	scope :have_pr, lambda { |si_id| where "si_id in (select si_id from sales_return_headers where status <> 5 and si_id = ?)", si_id }
  	scope :not_void, where("status != 5")
  	scope :current_period, where(:close => false)

  	scope :unpaid, select("id, si_id, sales_invoice_date, customer_id, due_date, total_amount,outstanding_total_amount, 'O' as flag, currency_id, exchrate")
                  	.where("si_id NOT IN (SELECT spd.si_id 
                        FROM sales_payment_details spd INNER JOIN sales_payment_headers sph ON spd.sales_payment_header_id = sph.id 
                        WHERE sph.status<>5) and outstanding_total_amount > 0 and status = '1'")

  	scope :not_yet_paid, lambda { |customer_id| select("id, si_id, sales_invoice_date, outstanding_total_amount, 'O' as flag, currency_id, exchrate")
                        .where "si_id NOT IN (SELECT spd.si_id FROM sales_payment_details spd 
                        	INNER JOIN sales_payment_headers sph ON spd.sales_payment_header_id = sph.id 
                        	INNER JOIN other_sales_invoice_headers osih ON spd.si_id = osih.si_id
                        	WHERE sph.status<>5 and (osih.status = '1' OR osih.status = '0')) and outstanding_total_amount > 0 and customer_id =?", customer_id }
  
  	scope :paid, select("id, si_id, sales_invoice_date, customer_id, due_date, total_amount, 'O' as flag, currency_id, exchrate")
              	.where("si_id IN (SELECT spd.si_id FROM sales_payment_details spd INNER JOIN sales_payment_headers sph 
                	ON spd.sales_payment_header_id = sph.id WHERE sph.status<>5) and outstanding_total_amount <= 0 and status = '1'")

  	def total_discount
    	total_discount = (self.amount.to_f * self.discount.to_f/100) + self.discount_amount.to_f
    	return total_discount
  	end

  	def outstanding_amount
    	payments = SalesPaymentHeader.joins(:sales_payment_details).where("sales_payment_details.si_id = ?", self.si_id)

    	balance = self.total_amount.to_f
    	payments.each do |p|
      		balance -= p.amount.to_f
    	end

    	return balance
  	end

    def sales_quotation_id
      if self.sales_quotation_header_id != 0
        sq_id = SalesQuotationHeader.find(self.sales_quotation_header_id).try(:sq_id)
      else
        sq_id = ''
      end
      return sq_id
    end

  	def self.other_si_header_id(transaction_date, tax_type=0)
  		prefix = OT_SI_PREFIX_DEFAULT

    	other_si_id_previous = OtherSalesInvoiceHeader.all(:select => "Max(si_id) as max_si_id", 
      		:conditions => ["date_part('month', sales_invoice_date)=date_part('month', CAST('#{transaction_date}' AS Date)) and date_part('year', sales_invoice_date)=date_part('year', CAST('#{transaction_date}' AS Date)) and si_id like ?", "#{prefix}%"], 
      		:limit => 1).first.max_si_id

    	if other_si_id_previous.blank?
      		month_id = "%02d" % transaction_date.strftime("%m").to_i
      		year_id = "%02d" % transaction_date.strftime("%y").to_i
      		new_value_id = 1
    	else
        	month_id = other_si_id_previous[5, 2]
        	year_id = other_si_id_previous[3, 2]
        	value_id = other_si_id_previous[8, 4]
        	new_value_id = value_id.to_i + 1
    	end
    	si_id_new = prefix + year_id.to_s + month_id.to_s + "-%04d" % new_value_id.to_s
  	end

  	def self.fp_code_generator(date)
    	company = Company.last
    	standart_fp_code = company.try(:standart_fp_code)

    	sales_tax_invoice = SalesTaxInvoice.where(:year => date.to_date.strftime("%Y")).last
    	sales_tax_invoice = SalesTaxInvoice.create(:year => date.to_date.strftime("%Y"), 
                                               :last_fp_code => 0, 
                                               :close => false) if sales_tax_invoice.blank?
    	year = sales_tax_invoice.year[2,2]
    	new_fp_code = sales_tax_invoice.last_fp_code.to_i+1

    	sales_tax_invoice.update_attributes(:last_fp_code => new_fp_code)

    	return "#{standart_fp_code}-#{year}.%08d" % new_fp_code
  	end
 
  	def self.check_due_date_invoice(customer_id)
    	if customer_id.to_i!=0
      		customer = Customer.find(customer_id)
      		sales_invoices = OtherSalesInvoiceHeader.posted.search_customer(customer.id)
      						.where("outstanding_total_amount>0").where("current_date > due_date+7")

	      	if sales_invoices.blank? 
	        	can_do=1
	        	invoice_lock = false
	      	elsif customer.supervisor_unlock_approval==true
	        	can_do=1
	        	invoice_lock = true
	      	else
	        	can_do=0
	        	invoice_lock = true
	      	end
	      	customer.update_attributes(:invoice_lock => invoice_lock, :supervisor_unlock_approval => false, :supervisor_unlock_notes => "")
    	else
	      	can_do = 2
    	end

    	return can_do
  	end

  	def self.search_month(month)
    	if month
      		where("date_part('month', sales_invoice_date) = ? ", "#{month}")
    	else
      		scoped
    	end
  	end

  	def self.search_year(year)
    	if year
      		where("date_part('year', sales_invoice_date) = ? ", "#{year}")
    	else
      		scoped
    	end
  	end

  	# FOR REPORT

  	def self.report_period(start_period, end_period)
    	if start_period.present? && end_period.present?
      		where(:sales_invoice_date => (start_period)..(end_period))
    	else
      		scoped
    	end
  	end

  	def self.to_csv(options = {})
    	CSV.generate(options) do |csv|
      		csv << column_names
      		all.each do |row|
        		csv << row.attributes.values_at(*column_name)
      		end
    	end
  	end

    private
    def insert_expense_from_quotation
      sqh = SalesQuotationHeader.find(self.sales_quotation_header_id)
      sqcs = sqh.sales_quotation_costs.order(:created_at)
      osih = OtherSalesInvoiceHeader.find(self.id); amnt = 0
      other_sales_invoice_details.destroy_all

      sqcs.each do |sqc|
        other_sales_invoice_details.create(:description => sqc.description, :total_amount => sqc.amount, 
          :price => sqc.price, :quantity => sqc.quantity, :discount_item => sqc.discount_item, 
          :discount_item_price => sqc.discount_item_price)
        
        amnt += sqc.amount.to_f
      end

      self.update_attributes(:amount => amnt.to_f, :total_amount => (amnt.to_f - self.total_discount.to_f))
    end
  end
end
