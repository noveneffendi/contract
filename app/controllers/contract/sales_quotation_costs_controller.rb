require_dependency "contract/application_controller"

module Contract
  class SalesQuotationCostsController < ApplicationController
    before_filter :get_sales_quotation_header, :only => [:new, :edit, :create, :update, :destroy]
    before_filter :get_unit_of_measures, :only => [:new, :edit]
  
    # GET /sales_quotation_costs/new
    # GET /sales_quotation_costs/new.json
    def new
      @sales_quotation_cost = @sales_quotation_header.sales_quotation_costs.new
  
      respond_to do |format|
        format.js
      end
    end
  
    # GET /sales_quotation_costs/1/edit
    def edit
      @sales_quotation_cost = SalesQuotationCost.find(params[:id])
    end
  
    # POST /sales_quotation_costs
    # POST /sales_quotation_costs.json
    def create
      @sales_quotation_cost = @sales_quotation_header.sales_quotation_costs.new(params[:sales_quotation_cost])

      # format create_log(subject, object, detail, employee_name)
      create_log("Create Cost", "Sales Quotation", "Create new cost with header id:#{@sales_quotation_header.sq_id}, 
          description:#{params[:sales_quotation_cost][:description]}, quantity:#{params[:sales_quotation_cost][:quantity]}, 
          price:#{params[:sales_quotation_cost][:price]}, disc price:#{params[:sales_quotation_cost][:discount_item_price]}, 
          disc:#{params[:sales_quotation_cost][:discount_item]}, 
          total:#{params[:sales_quotation_cost][:amount]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_quotation_cost.save
          get_sales_cost_details
          # Get Sales Order Header information
          get_sales_quotation_header

          format.js
          format.json { render json: @sales_quotation_cost, status: :created, location: @sales_quotation_cost }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_quotation_cost.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_quotation_costs/1
    # PUT /sales_quotation_costs/1.json
    def update
      @sales_quotation_cost = SalesQuotationCost.find(params[:id])

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Cost", "Sales Order", "Update detail with header id:#{@sales_quotation_header.sq_id}, 
        description:#{params[:sales_quotation_cost][:description]}, 
        quantity from:#{@sales_quotation_cost.quantity} to:#{params[:sales_quotation_cost][:quantity]}, 
        price from:#{@sales_quotation_cost.price} to:#{params[:sales_quotation_cost][:price]}, 
        disc price from:#{@sales_quotation_cost.discount_item_price} to:#{params[:sales_quotation_cost][:discount_item_price]}, 
        disc from:#{@sales_quotation_cost.discount_item} to:#{params[:sales_quotation_cost][:discount_item]}, 
        total from:#{@sales_quotation_cost.amount} to:#{params[:sales_quotation_cost][:amount]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_quotation_cost.update_attributes(params[:sales_quotation_cost])
          get_sales_cost_details
          # Get Sales Order Header information
          get_sales_quotation_header

          format.js
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_quotation_cost.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_quotation_costs/1
    # DELETE /sales_quotation_costs/1.json
    def destroy
      @sales_quotation_cost = SalesQuotationCost.find(params[:id])
      @sales_quotation_cost.destroy
      get_sales_cost_details
      # Get Sales Order Header information
      get_sales_quotation_header
  
      respond_to do |format|
        # format.html { redirect_to sales_quotation_costs_url }
        format.js
        format.json { head :no_content }
      end
    end

    private
      def get_sales_quotation_header
        @sales_quotation_header = SalesQuotationHeader.find(params[:sales_quotation_header_id])
      end

      def get_sales_cost_details
        @sales_quotation_costs = @sales_quotation_header.sales_quotation_costs.order(:id)
      end
  end
end
