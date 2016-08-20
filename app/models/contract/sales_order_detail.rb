module Contract
  class SalesOrderDetail < ActiveRecord::Base
    belongs_to :unit_of_measure
    belongs_to :sales_order_header
    has_many :sales_order_materials
    has_many :sales_order_costs
    attr_accessible :category, :description, :number, :quantity
  end
end
