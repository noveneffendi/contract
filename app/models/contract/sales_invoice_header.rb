require 'contract/filter'
module Contract
  class SalesInvoiceHeader < ActiveRecord::Base
  	include Filter
    SI_PREFIX_DEFAULT = 'SI-'
    belongs_to :customer
    belongs_to :warehouse
    belongs_to :currency
    attr_accessible :amount, :cash_disc, :close, :counter_print, :delivery_address, :discount, :discount_amount, :do_id, 
    	:due_date, :employee_name, :exchrate, :gst_code, :notes, :other_si_number, :outstanding_total_amount, :sales_id, 
    	:sales_invoice_date, :shipment, :shipping_id, :si_id, :so_id, :status, :tax, :tax_amount, :total_amount
    attr_accessor :shipping_name, :shipping_address, :sales_quotation_header_id
    cattr_accessor :revision_status

    self.table_name = "contract_sales_invoice_headers"

    scope :with_so_id, lambda { |so_id| where(:so_id => so_id) }
  	scope :posted, where(:status => 1).order("si_id DESC")
  	scope :si_has_outstanding_qty, joins(:sales_invoice_details).where("sales_invoice_details.outstanding_qty > ?", 0)
  	scope :with_tax, where(:tax => true)
  	scope :have_sr, lambda { |si_id| where "si_id in (select si_id from sales_return_headers where status <> 5 and si_id = ?)", si_id }
  	scope :not_void, where("status != 5")
  	scope :current_period, where(:close => false)
  	scope :unpaid, lambda { |si_id| select("id, si_id, sales_invoice_date, customer_id, due_date, total_amount, outstanding_total_amount, 'I' as flag, currency_id, exchrate")
                	.where("si_id NOT IN (SELECT spd.si_id FROM sales_payment_details spd JOIN sales_payment_headers sph ON spd.sales_payment_header_id = sph.id
                        WHERE sph.status<>5) and outstanding_total_amount > 0 and status = '1' and si_id like ?", "#{si_id}%") }

  	scope :not_yet_paid, lambda { |customer_id, si_id| select("id, si_id, sales_invoice_date, outstanding_total_amount, 'I' as flag, currency_id, exchrate")
                      	.where "si_id NOT IN (SELECT spd.si_id FROM sales_payment_details spd INNER JOIN sales_payment_headers sph 
                        	ON spd.sales_payment_header_id = sph.id INNER JOIN sales_invoice_headers sih ON spd.si_id = sih.si_id
                        	WHERE sph.status<>5 and (sih.status=1 OR sih.status=0)) and sih.outstanding_total_amount > 0 and customer_id = ? and si_id like ?", customer_id, "#{si_id}%"}

  	scope :sales_history_data, lambda { select('sales_invoice_headers.si_id, sales_invoice_headers.sales_invoice_date, sales_invoice_headers.customer_id,
        	transactions.product_id, transactions.price, sales_invoice_headers.currency_id, sales_invoice_headers.sales_id, products.name,
        	transactions.quantity, transactions.return_qty, ((transactions.quantity - transactions.return_qty) * transactions.price) total_purchase_amount,
        	(sales_invoice_details.total_amount / sales_invoice_details.quantity) nett_price, sales_invoice_details.price sale_price, sales_invoice_details.discount_item,
        	((transactions.quantity - transactions.return_qty) * (sales_invoice_details.total_amount / sales_invoice_details.quantity)) total_sales_amount, 
        	sales_invoice_headers.total_amount')
      		.joins("INNER JOIN transactions ON sales_invoice_headers.si_id = transactions.reference_id")
      		.joins("INNER JOIN products ON transactions.product_id = products.id")
      		.joins("INNER JOIN sales_invoice_details ON sales_invoice_headers.id = sales_invoice_details.sales_invoice_header_id 
        		AND transactions.product_id = sales_invoice_details.product_id")}

  	scope :paid, select("id, si_id, sales_invoice_date, customer_id, due_date, total_amount, 'I' as flag, currency_id, exchrate")
    				.where("outstanding_total_amount <= 0 and si_id IN (select spd.si_id FROM sales_payment_details spd JOIN sales_payment_headers sph ON spd.sales_payment_header_id = sph.id
      					WHERE sph.status<>5) and status = '1'")

  	scope :history_by_period, lambda { |start_period,end_period| where "sales_invoice_headers.sales_invoice_date between ? and ?", start_period.to_date, end_period.to_date }
  
  	def sq_id
      sqh = SalesQuotationHeader.find_by_id(self.sales_quotation_header_id)
      return sqh.sq_id
    end

    def sales_person_name
      name = User.find(self.sales_id).full_name
	  end

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

  	def paid_amount
    	amount = SalesPaymentDetail.joins(:sales_payment_header)
              .where("sales_payment_headers.status = 1 and sales_invoice_header_id = ?", self.id).sum(:amount)
    	return amount
  	end

  	def self.invoice_union_list(customer, tax_type=0)
    	if tax_type.to_s == 'x'
      		sales_invoices = self.not_yet_paid(customer, SI_PREFIX_NON_TAX)
    	elsif tax_type.to_s == 'l'
      		sales_invoices = self.not_yet_paid(customer, SI_PREFIX_TAX)
    	else
      		sales_invoices = self.not_yet_paid(customer, SI_PREFIX_DEFAULT)
    	end
    	other_sales_invoices = OtherSalesInvoiceHeader.not_yet_paid(customer)

    	find_by_sql("#{sales_invoices.to_sql} UNION #{other_sales_invoices.to_sql} ORDER BY sales_invoice_date desc")
  	end

  	def self.paid_list(tax_type=0)
    	@sales_invoices = self.paid.search_tax_type(tax_type)

    	@other_sales_invoices = OtherSalesInvoiceHeader.paid
  	end

  	def self.unpaid_list(tax_type=0)
    	if tax_type.to_s == 'x'
      		@sales_invoices = self.unpaid(SI_PREFIX_NON_TAX)
    	elsif tax_type.to_s == 'l'
      		@sales_invoices = self.unpaid(SI_PREFIX_TAX)
    	else
      		@sales_invoices = self.unpaid(SI_PREFIX_DEFAULT)
    	end
    	@other_sales_invoices = OtherSalesInvoiceHeader.unpaid
  	end

  	def self.union_unpaid_list(tax_type=0)
    	unpaid_list(tax_type)

    	find_by_sql("#{@sales_invoices.to_sql} UNION #{@other_sales_invoices.to_sql} ORDER BY sales_invoice_date desc")
  	end

  	# PAID transactions by customer
  	def self.customer_total_paid(currency,customer,tax_type=0)
    	paid_list(tax_type)

    	if customer > 0 && currency > 0
      		find_by_sql(["select x.customer_id,sum(x.outstanding_total_amount) sum_total_amount from (#{@sales_invoices.to_sql}
        		UNION #{@other_sales_invoices.to_sql} ORDER BY customer_id) x group by x.customer_id having customer_id = ? and customer_id = ?", customer, currency])
    	elsif customer == 0 && currency > 0
      		find_by_sql(["select x.customer_id,sum(x.outstanding_total_amount) sum_total_amount from (#{@sales_invoices.to_sql} 
        		UNION #{@other_sales_invoices.to_sql} ORDER by customer_id) x group by x.customer_id having currency_id = ?", currency])
    	elsif currency == 0 && customer > 0
      		find_by_sql(["select x.customer_id,sum(x.outstanding_total_amount) sum_total_amount from (#{@sales_invoices.to_sql} 
        		UNION #{@other_sales_invoices.to_sql} ORDER by customer_id) x group by x.customer_id having customer_id = ?", customer])
    	else
      		find_by_sql("select x.customer_id,sum(x.outstanding_total_amount) sum_total_amount from (#{@sales_invoices.to_sql} 
        		UNION #{@other_sales_invoices.to_sql} ORDER by customer_id) x group by x.customer_id")
    	end
  	end

  	def self.paid_by_customer(customer, tax_type=0)
    	paid_list(tax_type)

    	sales_invoices = @sales_invoices.where(:customer_id => customer)
    	other_sales_invoices = @other_sales_invoices.where(:customer_id => customer)

    	find_by_sql("#{sales_invoices.to_sql} UNION #{other_sales_invoices.to_sql} ORDER BY sales_invoice_date desc")
  	end

  	# UNPAID transactions by customer
  	def self.customer_total_unpaid(currency,customer,tax_type=0)
    	unpaid_list(tax_type)
  
    	if customer > 0 && currency > 0
      		find_by_sql(["select x.customer_id,sum(x.total_amount) sum_total_amount from (#{@sales_invoices.to_sql} 
        		UNION #{@other_sales_invoices.to_sql} ORDER by customer_id) x group by x.customer_id, currency_id having customer_id = ? and currency_id = ?", customer, currency])
    	elsif customer == 0 && currency > 0
      		find_by_sql(["select x.customer_id,sum(x.total_amount) sum_total_amount from (#{@sales_invoices.to_sql} 
        		UNION #{@other_sales_invoices.to_sql} ORDER by customer_id) x group by x.customer_id, currency_id having currency_id = ?", currency])
    	elsif currency == 0 && customer > 0
      		find_by_sql(["select x.customer_id,sum(x.total_amount) sum_total_amount from (#{@sales_invoices.to_sql} 
        		UNION #{@other_sales_invoices.to_sql} ORDER by customer_id) x group by x.customer_id, currency_id having customer_id = ?", customer])
    	else
      		find_by_sql("select x.customer_id,sum(x.total_amount) sum_total_amount from (#{@sales_invoices.to_sql} 
        		UNION #{@other_sales_invoices.to_sql} ORDER by customer_id) x group by x.customer_id, currency_id")
    	end    
  	end

  	def self.unpaid_by_customer(customer)
    	unpaid_list(tax_type)
    
    	sales_invoices = @sales_invoices.where(:customer_id => customer)
    	other_sales_invoices = @other_sales_invoices.where(:customer_id => customer)

    	find_by_sql("#{sales_invoices.to_sql} UNION #{other_sales_invoices.to_sql} ORDER BY sales_invoice_date desc")
  	end

  	def self.si_header_id(transaction_date, tax_type=0)
      prefix = SI_PREFIX_DEFAULT
    	

    	si_id_previous = SalesInvoiceHeader.all(:select => "Max(si_id) as max_si_id", 
      		:conditions => ["date_part('month', sales_invoice_date)=date_part('month', CAST('#{transaction_date}' AS Date)) and date_part('year', sales_invoice_date)=date_part('year', CAST('#{transaction_date}' AS Date)) and si_id like ?", "#{prefix}%"], 
      		:limit => 1).first.max_si_id

    	if si_id_previous.blank?
      		month_id = "%02d" % transaction_date.strftime("%m").to_i
      		year_id = "%02d" % transaction_date.strftime("%y").to_i
      		new_value_id = 1
    	else
        	month_id = si_id_previous[5, 2]
        	year_id = si_id_previous[3, 2]
        	value_id = si_id_previous[8, 4]
        	new_value_id = value_id.to_i + 1
    	end
    	si_id_new = prefix + year_id.to_s + month_id.to_s + "-%04d" % new_value_id.to_s

    	#self.si_id ||= si_id_new if not si_id.present?
  	end

  	def self.fp_code_generator(date)
    	company = Company.last
    	standart_fp_code = company.try(:standart_fp_code)

    	sales_tax_invoice = SalesTaxInvoice.where(:year => date.to_date.strftime("%Y")).last
    	sales_tax_invoice = SalesTaxInvoice.create(:year => date.to_date.strftime("%Y"), 
                                               :last_fp_code => 0, :close => false) if sales_tax_invoice.blank?
    	year = sales_tax_invoice.year[2,2]
    	new_fp_code = sales_tax_invoice.last_fp_code.to_i+1

    	sales_tax_invoice.update_attributes(:last_fp_code => new_fp_code)

    	return "#{standart_fp_code}-#{year}.%08d" % new_fp_code
  	end

  	def shipping_agent_name(shipping_id)
    	name = Supplier.is_shipping.find(shipping_id).try(:name)
  	end

  	def shipping_agent_address(shipping_id)
    	@shipping = Supplier.is_shipping.find(shipping_id)
    	address = "#{@shipping.address}, #{@shipping.city.try(:name)}"
  	end

  	def shipping_name
    	Supplier.is_shipping.find(shipping_id).try(:name)
  	end

  	def shipping_address
    	@shipping = Supplier.is_shipping.find(shipping_id)
    	return "#{@shipping.address}, #{@shipping.city.try(:name)}"
  	end

  	def shipment_description
    	case self.shipment
    	when 0
      		return "#{t 'delivered'}"
    	when 1
      		return "#{t 'delivered_by_expedition'}"
    	when 2
      		return "#{t 'taken'}"
    	else
      		return nil
    	end
  	end

  	def so_trans_id
    	soh = SalesOrderHeader.where(:so_id => self.so_id).first
    	if soh.present?
      		id = soh.id
    	else
      		id = nil
    	end
    	return id
  	end

	def do_trans_id
    	doh = DeliveryOrderHeader.where(:do_id => self.do_id).first
    	if doh.present?
      		id = doh.id
    	else
      		id =nil
    	end
    	return id
  	end

  	# use for count sales commission information
  	def total_amount_after_return
    	total_return = SalesReturnHeader.where(:si_id => self.si_id).sum(:total_amount)

    	total_amount = self.total_sales_amount.to_f - total_return.to_f
  	end

  	def total_return_amount
    	self.total_amount.to_f - self.total_amount_after_return
  	end

  	def total_profit_amount
    	sids = self.sales_invoice_details.order(:id)
    	total_profit = 0
    	sids.each do |sid|
      		total_profit += sid.profit.to_f
    	end

    	return total_profit
  	end

  	def self.check_due_date_invoice(customer_id)
    	if customer_id.to_i!=0
      		customer = Customer.find(customer_id)
      		sales_invoices = SalesInvoiceHeader.posted.search_customer(customer.id)
      							.where("outstanding_total_amount>0 and current_date > due_date+7")

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

  	def self.search_so_id(so_id)
    	if so_id!=''
      		where("so_id = ?", "#{so_id}")
    	else
      		scoped
    	end
  	end

  	def self.search_do_id(do_id)
    	if do_id!=''
      		where("do_id = ?", "#{do_id}")
    	else
      		scoped
    	end
  	end

  	def self.search_sales_person(sales_person)
    	if sales_person!=0
      		where("sales_id = ?", sales_person)
    	else
      		scoped
    	end
  	end

  	def self.history_by_transaction_product(product)
    	if product!=0
      		where("transactions.product_id = ?", product)
    	else
      		scoped
    	end
  	end

  	def self.history_by_product(product)
    	if product!=0
      		where("sales_invoice_details.product_id = ?", product)
    	else
      		scoped
    	end
  	end

  	def self.history_by_customer(customer)
    	if customer!=0
      		where("sales_invoice_headers.customer_id = ?", customer)
    	else
      		scoped
    	end
  	end

  	def self.history_by_currency(currency)
    	if currency!=0
      		where("sales_invoice_headers.currency_id = ?", currency)
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

  	# FOR  BI Report

  	def self.turnover_by_month(period)
    	current_month = period.to_date.strftime("%m")
    	current_year = period.to_date.strftime("%Y")
    	
    	sihs = self.posted.where("date_part('month', sales_invoice_date)=? and date_part('year', sales_invoice_date)=?", current_month, current_year)
    	total_turnover = 0

    	sihs.each do |sih|
      		total_turnover += (sih.total_amount.to_f - sih.tax_amount.to_f)
    	end

    	srhs = SalesReturnHeader.posted.where("date_part('month', sales_return_date)= ? and date_part('year', sales_return_date) = ?", current_month, current_year)

    	srhs.each do |srh|
      		total_turnover -= srh.total_amount.to_f
    	end

    	return total_turnover
  	end

  	def self.total_unpaid_amount(tt=0)
    	sih = self.union_unpaid_list(tt)
    	total_unpaid_amount = 0

    	sih.each do |sh|
      		total_unpaid_amount += sh.total_amount
    	end

    	return total_unpaid_amount
  	end

  end
end
