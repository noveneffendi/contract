module Contract
  class SalesQuotationMaterial < ActiveRecord::Base
    belongs_to :product
    belongs_to :unit_of_measure
    belongs_to :sales_quotation_detail
    attr_accessible :amount, :discount_item, :discount_item_price, :number, :outstanding_qty, :price, :quantity, :unit_of_measure_id, :product_id

    before_save :set_amount
    after_save :set_header_amount
    before_create :set_row_number
    after_create :set_outstanding_qty
    after_destroy :set_header_amount

    self.table_name = 'contract_sales_quotation_materials'

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
    	sales_quotation_header = SalesQuotationHeader.joins(:sales_quotation_details)
                                .where("contract_sales_quotation_details.id = ?", self.sales_quotation_detail_id).last

        sales_quotation_details = SalesQuotationDetail.where(:sales_quotation_header_id => sales_quotation_header.id).order(:number)

        total_amount = 0
        sales_quotation_details.each do |sod|
            total_amount += self.class.select("sum(contract_sales_quotation_materials.amount) as sdetail_amount")
                            .where(:sales_quotation_detail_id => sod.id).reorder("").last.sdetail_amount.to_f
        end

        total_amount += SalesQuotationCost.select("sum(contract_sales_quotation_costs.amount) as sdetail_amount")
                        .where("sales_quotation_header_id = ? ", sales_quotation_header.id).reorder("").last.sdetail_amount.to_f

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

    def set_outstanding_qty
    	self.outstanding_qty = self.quantity
    end

    def set_row_number
    	self.number = self.class.where(:sales_quotation_detail_id => self.sales_quotation_detail_id).count + 1
    end
  end
end
