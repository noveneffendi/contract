module Contract
  class ApplicationController < ::ApplicationController
    # protect_from_forgery :with => :exception
    layout 'application'

    def get_unit_of_measures
    	@uoms = UnitOfMeasure.active
    end

    def get_products
    	@products = Product.active.order(:name)
    end
  end
end
