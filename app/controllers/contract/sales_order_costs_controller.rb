require_dependency "contract/application_controller"

module Contract
  class SalesOrderCostsController < ApplicationController
    before_filter :get_sales_order_detail, :only => [:new, :create]
    before_filter :get_sales_order_header, :only => [:create, :update, :destroy]
  
    # GET /sales_order_costs/new
    # GET /sales_order_costs/new.json
    def new
      @sales_order_cost = @sales_order_detail.sales_order_costs.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_order_cost }
      end
    end
  
    # GET /sales_order_costs/1/edit
    def edit
      @sales_order_cost = SalesOrderCost.find(params[:id])
    end
  
    # POST /sales_order_costs
    # POST /sales_order_costs.json
    def create
      @sales_order_cost = @sales_order_detail.sales_order_costs.new(params[:sales_order_cost])

      # format create_log(subject, object, detail, employee_name)
      create_log("Create Cost", "Sales Order", "Create new cost with header id:#{@sales_order_header.so_id}, 
          description:#{params[:sales_order_cost][:description]}, quantity:#{params[:sales_order_cost][:quantity]}, 
          price:#{params[:sales_order_cost][:price]}, disc price:#{params[:sales_order_cost][:discount_item_price]}, 
          disc:#{params[:sales_order_cost][:discount_item]}, 
          total:#{params[:sales_order_cost][:amount]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_order_cost.save
          format.js
          # format.html { redirect_to @sales_order_cost, notice: 'Sales order cost was successfully created.' }
          format.json { render json: @sales_order_cost, status: :created, location: @sales_order_cost }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_order_cost.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_order_costs/1
    # PUT /sales_order_costs/1.json
    def update
      @sales_order_cost = SalesOrderCost.find(params[:id])

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Cost", "Sales Order", "Update detail with header id:#{@sales_order_header.so_id}, 
        description:#{params[:sales_order_cost][:description]}, 
        quantity from:#{@sales_order_cost.quantity} to:#{params[:sales_order_cost][:quantity]}, 
        price from:#{@sales_order_cost.price} to:#{params[:sales_order_cost][:price]}, 
        disc price from:#{@sales_order_cost.discount_item_price} to:#{params[:sales_order_cost][:discount_item_price]}, 
        disc from:#{@sales_order_cost.discount_item} to:#{params[:sales_order_cost][:discount_item]}, 
        total from:#{@sales_order_cost.amount} to:#{params[:sales_order_cost][:amount]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_order_cost.update_attributes(params[:sales_order_cost])
          format.js
          # format.html { redirect_to @sales_order_cost, notice: 'Sales order cost was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_order_cost.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_order_costs/1
    # DELETE /sales_order_costs/1.json
    def destroy
      @sales_order_cost = SalesOrderCost.find(params[:id])
      @sales_order_cost.destroy
  
      respond_to do |format|
        # format.html { redirect_to sales_order_costs_url }
        format.js
        format.json { head :no_content }
      end
    end

    private
      def get_sales_order_header
        @sales_order_header = SalesOrderHeader.find(params[:sales_order_header_id])
      end

      def get_sales_order_detail
        @sales_order_detail = @sales_order_header.sales_order_details.find(params[:sales_order_detail_id])
      end

      def get_sales_cost_details
        @sales_order_costs = @sales_order_header.sales_order_details.sales_order_costs.order(:id)
      end
  end
end
