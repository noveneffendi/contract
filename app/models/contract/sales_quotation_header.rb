require 'contract/filter'

module Contract
  class SalesQuotationHeader < ActiveRecord::Base
	include Contract::Filter
	self.table_name = 'contract_sales_quotation_headers'
  	SQ_PREFIX_DEFAULT = 'SQ-'
  	
    belongs_to :currency
    belongs_to :customer
    has_many :sales_quotation_details, :dependent => :destroy
    has_many :sales_quotation_costs, :dependent => :destroy
    has_many :sales_quotation_materials, :through => :sales_quotation_details

    attr_accessible :amount, :approval_notes, :cash_disc, :close, :contact_person, :customer_id, :discount, :discount_amount, 
    	:employee_name, :exchrate, :notes, :sales_id, :sales_quotation_date, :sq_id, :status, :tax, :tax_amount, 
    	:currency_id, :total_amount, :rev_number
 	
 	cattr_accessor :revision_status

 	scope :posted, where(:status => 1).order("sq_id DESC")
	scope :sq_has_not_invoiced, joins("LEFT OUTER JOIN (SELECT * FROM contract_sales_invoice_headers WHERE contract_sales_invoice_headers.status = 1) sales_invoice_headers ON contract_sales_quotation_headers.id = sales_invoice_headers.sales_quotation_header_id")
	      .joins("LEFT OUTER JOIN delivery_order_headers ON sales_invoice_headers.do_id = delivery_order_headers.id")
	      .where("sales_invoice_headers.si_id is null")
	scope :not_close, where(:close => false)
	# scope :tax_transaction, where("so_id like ?", "#{SO_PREFIX_TAX}%")
	# scope :non_tax_transaction, where("so_id like ?", "#{SO_PREFIX_NON_TAX}%")
	scope :have_si, lambda { |si_id| where "so_id in (select sq_id from contract_sales_invoice_headers where status <> 5 and sq_id = ?)", sq_id }
	scope :not_yet_invoiced, where("sq_id NOT IN (SELECT sq_id FROM contract_sales_invoice_headers WHERE status = 1)").order(:sq_id)
	scope :current_period, where(:close => false)

	def self.sq_header_id(transaction_date, tax_type=0)
	    prefix = SQ_PREFIX_DEFAULT

	    sq_id_previous = SalesQuotationHeader.all(:select => "Max(sq_id) as max_sq_id", 
	      :conditions => ["date_part('month', sales_quotation_date)=date_part('month', CAST('#{transaction_date}' AS Date)) and date_part('year', sales_quotation_date)=date_part('year', CAST('#{transaction_date}' AS Date)) and sq_id like ?", "#{prefix}%"], 
	      :limit => 1).first.max_sq_id

	    if sq_id_previous.blank?
		    month_id = "%02d" % transaction_date.strftime("%m").to_i
		    year_id = "%02d" % transaction_date.strftime("%y").to_i
		    new_value_id = 1
	    else
	      	month_id = sq_id_previous[5, 2]
	        year_id = sq_id_previous[3, 2]
        	value_id = sq_id_previous[8, 4]
        	new_value_id = value_id.to_i + 1
	    end

	    sq_id_new = prefix + year_id.to_s + month_id.to_s + "-%04d" % new_value_id.to_s
	end

	def self.search_month(month)
	    if month
		    where("date_part('month', sales_quotation_date) = ? ", "#{month}")
	    else
			scoped
	    end
	end

	def self.search_year(year)
	    if year
		    where("date_part('year', sales_quotation_date) = ? ", "#{year}")
	    else
		    scoped
	    end
	end

	def self.search_by_description(description)
		if !description.empty?
			sales_quotation_details = self.joins(:sales_quotation_details)
									.where("LOWER(contract_sales_quotation_details.description) LIKE ?", "%#{description.downcase}%")
			arr_ids = []
			if sales_quotation_details.empty?
				sales_quotation_costs = SalesQuotationCost.search_by_description(description).order(:sales_quotation_detail_id)

				if sales_quotation_costs.present?
					sales_quotation_costs.each do |soc|
						arr_ids.push(soc.sales_quotation_detail_id)
					end
				end
			else # sales_quotation_detail present
				sales_quotation_details.each do |sod|
					arr_ids.push(sod.id)
				end

				sales_quotation_costs = SalesQuotationCost.search_by_description(description).order(:sales_quotation_detail_id)

				if sales_quotation_costs.present?
					sales_quotation_costs.each do |soc|
						arr_ids.push(soc.sales_quotation_detail_id)
					end
				end
			end

			joins(:sales_quotation_details).where("contract_sales_quotation_details.id = ?", arr_ids)
		else
			scoped
		end
	end

	def self.search_by_product(product)
		if !product.empty?
			joins("LEFT JOIN contract_sales_quotation_materials ON contract_sales_quotation_materials.sales_quotation_detail_id = contract_sales_quotation_details.id")
			.joins("LEFT JOIN products ON contract_sales_quotation_materials.product_id = products.id")
			.where("LOWER(products.name) like ?", "%#{product.downcase}%")
		else
			scoped
		end
	end

	# FOR REPORT

	def self.report_period(start_period, end_period)
		if start_period.present? && end_period.present?
		    where(:sales_quotation_date => (start_period)..(end_period))
		else
			scoped
		end
	end
  end
end
