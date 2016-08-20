module Contract
  class SalesQuotationCost < ActiveRecord::Base
    belongs_to :unit_of_measure
    belongs_to :sales_quotation_header
    attr_accessible :amount, :description, :discount_item, :discount_item_price, :price, :quantity, :unit_of_measure_id

    before_save :set_amount
    after_save :set_header_amount
    after_destroy :set_header_amount

    self.table_name = 'contract_sales_quotation_costs'

    def self.search_by_description(description)
    	if description
			where("LOWER(sales_quotation_costs.description) LIKE ?", "%#{description.downcase}%")
    	else
    		scoped
    	end
    end

    def discount_amount
        total_disc_amount = ((self.quantity.to_f * self.price.to_f) * (self.discount_item.to_f / 100)) - self.discount_item_price.to_f
        
        return total_disc_amount
    end

    private
    def set_amount
        self.amount = (self.quantity.to_f*self.price.to_f) - ((self.discount_item.to_f/100)*(self.quantity.to_f*self.price.to_f.to_f)) 
                        - self.discount_item_price.to_f
    end

    def set_header_amount
        sales_quotation_header = SalesQuotationHeader.find(self.sales_quotation_header_id)
        sales_quotation_details = SalesQuotationDetail.where(:sales_quotation_header_id => self.sales_quotation_header_id)

        total_amount = 0
        sales_quotation_details.each do |sod|
            total_amount += SalesQuotationMaterial.select("sum(contract_sales_quotation_materials.amount) as sdetail_amount")
                            .where(:sales_quotation_detail_id => sod.id).reorder("").last.sdetail_amount.to_f
        end

        total_amount += self.class.select("sum(contract_sales_quotation_costs.amount) as sdetail_amount")
                        .where(:sales_quotation_header_id => self.sales_quotation_header_id).reorder("").last.sdetail_amount.to_f

        amount_before_cash_disc = total_amount.to_f - ((sales_quotation_header.discount/100)*total_amount.to_f) - sales_quotation_header.discount_amount
        amount_before_tax = amount_before_cash_disc.to_f - (amount_before_cash_disc.to_f*(sales_quotation_header.cash_disc.to_f/100))

        if sales_quotation_header.tax == true
           tax_amount = amount_before_tax * 0.1
        else
            tax_amount = 0
        end
        # Update sales quotation header
        soh = SalesQuotationHeader.find(sales_quotation_header.id)
        soh.update_attributes(:amount => amount_before_tax, :tax_amount => tax_amount, :total_amount => (amount_before_tax.to_f + tax_amount.to_f))
    end
  end
end
