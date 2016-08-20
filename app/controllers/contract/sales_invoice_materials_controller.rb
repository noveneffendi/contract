require_dependency "contract/application_controller"

module Contract
  class SalesInvoiceMaterialsController < ApplicationController
    # GET /sales_invoice_materials
    # GET /sales_invoice_materials.json
    def index
      @sales_invoice_materials = SalesInvoiceMaterial.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @sales_invoice_materials }
      end
    end
  
    # GET /sales_invoice_materials/1
    # GET /sales_invoice_materials/1.json
    def show
      @sales_invoice_material = SalesInvoiceMaterial.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @sales_invoice_material }
      end
    end
  
    # GET /sales_invoice_materials/new
    # GET /sales_invoice_materials/new.json
    def new
      @sales_invoice_material = SalesInvoiceMaterial.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_invoice_material }
      end
    end
  
    # GET /sales_invoice_materials/1/edit
    def edit
      @sales_invoice_material = SalesInvoiceMaterial.find(params[:id])
    end
  
    # POST /sales_invoice_materials
    # POST /sales_invoice_materials.json
    def create
      @sales_invoice_material = SalesInvoiceMaterial.new(params[:sales_invoice_material])
  
      respond_to do |format|
        if @sales_invoice_material.save
          format.html { redirect_to @sales_invoice_material, notice: 'Sales invoice material was successfully created.' }
          format.json { render json: @sales_invoice_material, status: :created, location: @sales_invoice_material }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_invoice_material.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_invoice_materials/1
    # PUT /sales_invoice_materials/1.json
    def update
      @sales_invoice_material = SalesInvoiceMaterial.find(params[:id])
  
      respond_to do |format|
        if @sales_invoice_material.update_attributes(params[:sales_invoice_material])
          format.html { redirect_to @sales_invoice_material, notice: 'Sales invoice material was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_invoice_material.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_invoice_materials/1
    # DELETE /sales_invoice_materials/1.json
    def destroy
      @sales_invoice_material = SalesInvoiceMaterial.find(params[:id])
      @sales_invoice_material.destroy
  
      respond_to do |format|
        format.html { redirect_to sales_invoice_materials_url }
        format.json { head :no_content }
      end
    end
  end
end
