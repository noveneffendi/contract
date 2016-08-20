require_dependency "contract/application_controller"

module Contract
  class SalesOrderDetailsController < ApplicationController
    before_filter :get_sales_order_header, :only => [:new, :create, :get_sales_order_details]
    # GET /sales_order_details/new
    # GET /sales_order_details/new.json
    def new
      @sales_order_detail = @sales_order_header.sales_order_details.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_order_detail }
      end
    end
  
    # GET /sales_order_details/1/edit
    def edit
      @sales_order_detail = SalesOrderDetail.find(params[:id])
    end
  
    # POST /sales_order_details
    # POST /sales_order_details.json
    def create
      @sales_order_detail = @sales_order_header.sales_order_details.new(params[:sales_order_detail])
  
      respond_to do |format|
        if @sales_order_detail.save
          get_sales_order_details
          # format.html { redirect_to @sales_order_detail, notice: 'Sales order detail was successfully created.' }
          format.js
          format.json { render json: @sales_order_detail, status: :created, location: @sales_order_detail }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_order_detail.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_order_details/1
    # PUT /sales_order_details/1.json
    def update
      @sales_order_detail = SalesOrderDetail.find(params[:id])
  
      respond_to do |format|
        if @sales_order_detail.update_attributes(params[:sales_order_detail])
          get_sales_order_details
          # format.html { redirect_to @sales_order_detail, notice: 'Sales order detail was successfully updated.' }
          format.js
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_order_detail.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_order_details/1
    # DELETE /sales_order_details/1.json
    def destroy
      @sales_order_detail = SalesOrderDetail.find(params[:id])
      @sales_order_detail.destroy
      get_sales_order_details
  
      respond_to do |format|
        # format.html { redirect_to sales_order_details_url }
        format.js
        format.json { head :no_content }
      end
    end

    private
      def get_sales_order_header
        @sales_order_header = SalesOrderHeader.find(params[:sales_order_header_id])
      end

      def get_sales_order_details
        @sales_order_details = @sales_order_header.sales_order_details.order(:id)
      end
  end
end
