module Contract
  class SalesQuotationDetail < ActiveRecord::Base
    belongs_to :unit_of_measure
    belongs_to :sales_quotation_header
    has_many :sales_quotation_materials, :dependent => :destroy
    attr_accessible :category, :description, :number, :quantity, :unit_of_measure_id
    self.table_name = 'contract_sales_quotation_details'

    before_create :set_row_number

    def row_number(header_id)
        sales_detail = self.class.joins(:sales_quotation_header)
                        .where("sales_quotation_header_id = ?", header_id.to_i)
                        .order("created_at ASC").count
        return sales_detail
    end

    def self.show_detail_by_id(id)
        arr_detail = []

        sqds = self.where(:sales_quotation_header_id => id)
        sqds.each do |sqd|
            arr_detail.push [sqd.category, sqd.description, "", "", "", "", ""]
            arr_detail.push ["#{I18n.t 'product'}", "#{I18n.t 'quantity'}", "#{I18n.t 'unit'}", 
                "#{I18n.t 'price'}", "#{I18n.t 'disc_rp'}", "#{I18n.t 'disc'}", "#{I18n.t 'total'}"]

            material_amount = 0
            sqms = SalesQuotationMaterial.where(:sales_quotation_detail_id => sqd.id)
            sqms.each do |sqm|
                arr_detail.push [sqm.product.try(:name), sqm.quantity, sqm.unit_of_measure.try(:name), 
                    sqm.price, sqm.discount_item_price, sqm.discount_item, sqm.amount]
                material_amount += sqm.amount
            end
            arr_detail.push ["#{I18n.t 'total'}", "", "", "", "", "", material_amount]
        end

        return arr_detail
    end

    private
    def set_row_number
    	self.number = self.class.where(:sales_quotation_header_id => self.sales_quotation_header_id).count + 1
    end
  end
end
