module Contract
  class OtherSalesInvoiceDetail < ActiveRecord::Base
    self.table_name = 'contract_other_sales_invoice_details'
    belongs_to :other_sales_invoice_header
    attr_accessible :description, :discount_item, :discount_item_price, :price, :quantity, :total_amount, :unit_of_measure_id

    def discount_amount
    	sih = OtherSalesInvoiceHeader.where(:id => self.other_sales_invoice_header_id).first
    	total_disc_amount_header = (self.total_amount.to_f * sih.discount.to_f/100) + ((self.total_amount.to_f - (self.total_amount.to_f * sih.discount.to_f/100)))
    	total_disc_amount_detail = ((self.quantity.to_f * self.price.to_f) * (self.discount_item.to_f / 100)) - self.discount_item_price.to_f

    	total_disc_amount = total_disc_amount_header.to_f + total_disc_amount_detail.to_f
    
    	return total_disc_amount
  	end
  end
end
