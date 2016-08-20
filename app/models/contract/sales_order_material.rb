module Contract
  class SalesOrderMaterial < ActiveRecord::Base
    belongs_to :product
    belongs_to :unit_of_measure
    belongs_to :sales_order_detail
    attr_accessible :amount, :discount_item, :discount_item_price, :number, :outstanding_qty, :price, :quantity

    before_save :set_amount
    after_save :set_header_amount
    before_create :set_row_number
    after_create :set_outstanding_qty
    after_destroy :set_header_amount

    def discount_amount
	    total_disc_amount = ((self.quantity.to_f * self.price.to_f) * (self.discount_item.to_f / 100)) - self.discount_item_price.to_f
	    
	    return total_disc_amount
	end

    protected
    def set_amount
    	self.amount = (self.quantity.to_f*self.price.to_f) - ((self.discount_item.to_f/100)*(self.quantity.to_f*self.price.to_f.to_f)) 
    					- self.discount_item_price.to_f
    end

    def set_header_amount
    	total_amount = SalesOrderMaterial.sales_order_detail.select("sum(sales_order_materials.amount) as sdetail_amount").last.sdetail_amount
    	total_amount += SalesOrderCost.sales_order_detail.select("sum(sales_order_costs.amount) as sdetail_amount").last.sdetail_amount

    	sales_order_header = SalesOrderHeader.sales_order_details.find(self.sales_order_detail_id)

    	amount_before_cash_disc = total_amount.to_f - ((sales_order_header.discount/100)*total_amount.to_f) - sales_order_header.discount_amount
	    amount_before_tax = amount_before_cash_disc.to_f - (amount_before_cash_disc.to_f*(sales_order_header.cash_disc.to_f/100))

	    if sales_order_header.tax == true
	    	sales_order_header.tax_amount = amount_before_tax * 0.1
	    end
    end

    def set_outstanding_qty
    	self.outstanding_qty = self.quantity
    end

    def set_row_number
    	self.number = SalesOrderDetail.sales_order_materials.count
    end
  end
end
