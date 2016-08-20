module Contract
	module Filter
		module ClassMethod
			def search_amount(start_amount, end_amount)
				if start_amount.blank? && end_amount.blank?
					scoped
				elsif start_amount.blank? && !end_amount.blank?
					where(:total_amount <= end_amount)
				elsif end_amount.blank? && !start_amount.blank?
					where(:total_amount >= start_amount)
				else
					where(:total_amount => (start_amount)..(end_amount))
				end
			end

			def search_currency(currency)
				if currency.present?
					where("currency_id = ?", currency)
				else
					scoped
				end
			end

			def search_customer(customer)
			    if customer!=0
			    	where("customer_id = ?", customer)
			    else
			    	scoped
			    end
			end

			def search_status(status)
			    if status=='0' || status=='1' || status=='4' || status=='5'
				    where('status = ?', status)
			    else
				    scoped
			    end
			end

			def search_warehouse(warehouse)
			    if warehouse!=0
			    	where("warehouse_id = ?", warehouse)
	    		else
	      			scoped
	    		end
	  		end

	  		def search_sales_person(sales_person)
	  			if sales_person!=0
				    where("sales_id = ?", sales_person)
			    else
					scoped
			    end
	  		end

			def to_csv(options = {})
				CSV.generate(options) do |csv|
					csv << column_names
					all.each do |row|
						csv << row_attributes.values_at(*column_names)
					end
				end
			end
		end

		def self.included(clazz)
			clazz.extend ClassMethod
		end
	end
end