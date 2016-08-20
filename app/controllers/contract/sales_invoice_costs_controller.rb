require_dependency "contract/application_controller"

module Contract
  class SalesInvoiceCostsController < ApplicationController
    # GET /sales_invoice_costs
    # GET /sales_invoice_costs.json
    def index
      @sales_invoice_costs = SalesInvoiceCost.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @sales_invoice_costs }
      end
    end
  
    # GET /sales_invoice_costs/1
    # GET /sales_invoice_costs/1.json
    def show
      @sales_invoice_cost = SalesInvoiceCost.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @sales_invoice_cost }
      end
    end
  
    # GET /sales_invoice_costs/new
    # GET /sales_invoice_costs/new.json
    def new
      @sales_invoice_cost = SalesInvoiceCost.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_invoice_cost }
      end
    end
  
    # GET /sales_invoice_costs/1/edit
    def edit
      @sales_invoice_cost = SalesInvoiceCost.find(params[:id])

      @sq_ids = SalesQuotationHeader.posted.sq_has_not_invoiced.not_close
                  .where("contract_sales_quotation_headers.customer_id = ?", @sales_invoice_header.customer_id)
                  .uniq.order(:sq_id).reverse_order
    end
  
    # POST /sales_invoice_costs
    # POST /sales_invoice_costs.json
    def create
      @sales_invoice_cost = SalesInvoiceCost.new(params[:sales_invoice_cost])
  
      respond_to do |format|
        if @sales_invoice_cost.save
          format.html { redirect_to @sales_invoice_cost, notice: 'Sales invoice cost was successfully created.' }
          format.json { render json: @sales_invoice_cost, status: :created, location: @sales_invoice_cost }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_invoice_cost.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_invoice_costs/1
    # PUT /sales_invoice_costs/1.json
    def update
      @sales_invoice_cost = SalesInvoiceCost.find(params[:id])
  
      respond_to do |format|
        if @sales_invoice_cost.update_attributes(params[:sales_invoice_cost])
          format.html { redirect_to @sales_invoice_cost, notice: 'Sales invoice cost was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_invoice_cost.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_invoice_costs/1
    # DELETE /sales_invoice_costs/1.json
    def destroy
      @sales_invoice_cost = SalesInvoiceCost.find(params[:id])
      @sales_invoice_cost.destroy
  
      respond_to do |format|
        format.html { redirect_to sales_invoice_costs_url }
        format.json { head :no_content }
      end
    end
  end
end
