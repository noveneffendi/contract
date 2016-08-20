require_dependency "contract/application_controller"

module Contract
  class SalesInvoiceDetailsController < ApplicationController
    # GET /sales_invoice_details
    # GET /sales_invoice_details.json
    def index
      @sales_invoice_details = SalesInvoiceDetail.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @sales_invoice_details }
      end
    end
  
    # GET /sales_invoice_details/1
    # GET /sales_invoice_details/1.json
    def show
      @sales_invoice_detail = SalesInvoiceDetail.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @sales_invoice_detail }
      end
    end
  
    # GET /sales_invoice_details/new
    # GET /sales_invoice_details/new.json
    def new
      @sales_invoice_detail = SalesInvoiceDetail.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_invoice_detail }
      end
    end
  
    # GET /sales_invoice_details/1/edit
    def edit
      @sales_invoice_detail = SalesInvoiceDetail.find(params[:id])
    end
  
    # POST /sales_invoice_details
    # POST /sales_invoice_details.json
    def create
      @sales_invoice_detail = SalesInvoiceDetail.new(params[:sales_invoice_detail])
  
      respond_to do |format|
        if @sales_invoice_detail.save
          format.html { redirect_to @sales_invoice_detail, notice: 'Sales invoice detail was successfully created.' }
          format.json { render json: @sales_invoice_detail, status: :created, location: @sales_invoice_detail }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_invoice_detail.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_invoice_details/1
    # PUT /sales_invoice_details/1.json
    def update
      @sales_invoice_detail = SalesInvoiceDetail.find(params[:id])
  
      respond_to do |format|
        if @sales_invoice_detail.update_attributes(params[:sales_invoice_detail])
          format.html { redirect_to @sales_invoice_detail, notice: 'Sales invoice detail was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_invoice_detail.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_invoice_details/1
    # DELETE /sales_invoice_details/1.json
    def destroy
      @sales_invoice_detail = SalesInvoiceDetail.find(params[:id])
      @sales_invoice_detail.destroy
  
      respond_to do |format|
        format.html { redirect_to sales_invoice_details_url }
        format.json { head :no_content }
      end
    end
  end
end
