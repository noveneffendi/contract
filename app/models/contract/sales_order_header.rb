require 'contract/filter'

module Contract
  class SalesOrderHeader < ActiveRecord::Base
	# include Contract::Filter
  	SO_PREFIX_DEFAULT = 'SO-'
  	
    belongs_to :currency_id
    has_many :sales_order_details, :include => [:sales_order_materials, :sales_order_costs]

    attr_accessible :amount, :approval_notes, :cash_disc, :close, :contact_person, :customer_id, :discount, :discount_amount, 
    	:employee_name, :exchrate, :notes, :sales_id, :sales_order_date, :so_id, :status, :tax, :tax_amount
 	
 	cattr_accessor :revision_status

 	scope :posted, where(:status => 1).order("so_id DESC")
	scope :so_has_outstanding_qty, joins(:sales_order_details).where("sales_order_details.outstanding_qty > ?", 0)
	scope :so_has_not_invoiced, joins("LEFT OUTER JOIN (SELECT * FROM sales_invoice_headers WHERE sales_invoice_headers.status = 1) sales_invoice_headers ON sales_order_headers.so_id = sales_invoice_headers.so_id")
	      .joins("LEFT OUTER JOIN delivery_order_headers ON sales_invoice_headers.do_id = delivery_order_headers.do_id")
	      .where("sales_invoice_headers.si_id is null")
	scope :not_close, where(:close => false)
	# scope :tax_transaction, where("so_id like ?", "#{SO_PREFIX_TAX}%")
	# scope :non_tax_transaction, where("so_id like ?", "#{SO_PREFIX_NON_TAX}%")
	scope :have_si, lambda { |si_id| where "so_id in (select so_id from sales_invoice_headers where status <> 5 and so_id = ?)", so_id }
	scope :not_yet_invoiced, where("so_id NOT IN (SELECT so_id FROM sales_invoice_headers WHERE status = 1)").order(:so_id)
	scope :current_period, where(:close => false)

	def self.so_header_id(transaction_date, tax_type=0)
	    prefix = SO_PREFIX_DEFAULT

	    so_id_previous = SalesOrderHeader.all(:select => "Max(so_id) as max_so_id", 
	      :conditions => ["date_part('month', sales_order_date)=date_part('month', CAST('#{transaction_date}' AS Date)) and date_part('year', sales_order_date)=date_part('year', CAST('#{transaction_date}' AS Date)) and so_id like ?", "#{prefix}%"], 
	      :limit => 1).first.max_so_id

	    if so_id_previous.blank?
		    month_id = "%02d" % transaction_date.strftime("%m").to_i
		    year_id = "%02d" % transaction_date.strftime("%y").to_i
		    new_value_id = 1
	    else
	      	month_id = so_id_previous[5, 2]
	        year_id = so_id_previous[3, 2]
        	value_id = so_id_previous[8, 4]
        	new_value_id = value_id.to_i + 1
	    end

	    so_id_new = prefix + year_id.to_s + month_id.to_s + "-%04d" % new_value_id.to_s
	end

	def self.search_month(month)
	    if month
		    where("date_part('month', sales_order_date) = ? ", "#{month}")
	    else
			scoped
	    end
	end

	def self.search_year(year)
	    if year
		    where("date_part('year', sales_order_date) = ? ", "#{year}")
	    else
		    scoped
	    end
	end

	def self.search_by_description(description)
		if !description.empty?
			sales_order_details = self.joins(:sales_order_details)
									.where("LOWER(sales_order_details.description) LIKE ?", "%#{description.downcase}%")
			arr_ids = []
			if sales_order_details.empty?
				sales_order_costs = SalesOrderCost.search_by_description(description).order(:sales_order_detail_id)

				if sales_order_costs.present?
					sales_order_costs.each do |soc|
						arr_ids.push(soc.sales_order_detail_id)
					end
				end
			else # sales_order_detail present
				sales_order_details.each do |sod|
					arr_ids.push(sod.id)
				end

				sales_order_costs = SalesOrderCost.search_by_description(description).order(:sales_order_detail_id)

				if sales_order_costs.present?
					sales_order_costs.each do |soc|
						arr_ids.push(soc.sales_order_detail_id)
					end
				end
			end

			joins(:sales_order_details).where("sales_order_details.id = ?", arr_ids)
		else
			scoped
		end
	end

	def self.search_by_product(product)
		if product
			joins(:sales_order_materials).joins(:product).where("LOWER(products.name) like ?", "%#{product.downcase}%")
		else
			scoped
		end
	end

	# FOR REPORT

	def self.report_period(start_period, end_period)
		if start_period.present? && end_period.present?
		    where(:sales_order_date => (start_period)..(end_period))
		else
			scoped
		end
	end
  end
end
