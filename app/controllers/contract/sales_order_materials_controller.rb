require_dependency "contract/application_controller"

module Contract
  class SalesOrderMaterialsController < ApplicationController
    before_filter :get_sales_order_detail, :only => [:new, :create]
    before_filter :get_sales_order_header, :only => [:create, :update, :destroy]    

    # GET /sales_order_materials/new
    # GET /sales_order_materials/new.json
    def new
      @sales_order_material = @sales_order_detail.sales_order_materials.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_order_material }
      end
    end
  
    # GET /sales_order_materials/1/edit
    def edit
      @sales_order_material = SalesOrderMaterial.find(params[:id])
    end
  
    # POST /sales_order_materials
    # POST /sales_order_materials.json
    def create
      @sales_order_material = @sales_order_detail.sales_order_materials.new(params[:sales_order_material])

      # format create_log(subject, object, detail, employee_name)
      create_log("Create Material", "Sales Order", "Create new material with header id:#{@sales_order_header.so_id}, 
          product:#{@sales_order_material.product.try(:name)}, quantity:#{params[:sales_order_material][:quantity]}, 
          unit:#{@sales_order_material.unit_of_measure.try(:name)}, price:#{params[:sales_order_material][:price]}, 
          disc price:#{params[:sales_order_material][:discount_item_price]}, disc:#{params[:sales_order_material][:discount_item]}, 
          total:#{params[:sales_order_material][:amount]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_order_material.save
          get_sales_material_details

          format.js
          # format.html { redirect_to @sales_order_material, notice: 'Sales order material was successfully created.' }
          format.json { render json: @sales_order_material, status: :created, location: @sales_order_material }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_order_material.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_order_materials/1
    # PUT /sales_order_materials/1.json
    def update
      @sales_order_material = SalesOrderMaterial.find(params[:id])

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Detail", "Sales Order", "Update detail with header id:#{@sales_order_header.so_id}, 
        product:#{@sales_order_material.product.try(:name)}, 
        quantity from:#{@sales_order_material.quantity} to:#{params[:sales_order_material][:quantity]}, 
        unit:#{@sales_order_material.unit_of_measure.try(:name)}, 
        price from:#{@sales_order_material.price} to:#{params[:sales_order_material][:price]}, 
        disc price from:#{@sales_order_material.discount_item_price} to:#{params[:sales_order_material][:discount_item_price]}, 
        disc from:#{@sales_order_material.discount_item} to:#{params[:sales_order_material][:discount_item]}, 
        total from:#{@sales_order_material.amount} to:#{params[:sales_order_material][:amount]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_order_material.update_attributes(params[:sales_order_material])
          get_sales_material_details
          format.js
          # format.html { redirect_to @sales_order_material, notice: 'Sales order material was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_order_material.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_order_materials/1
    # DELETE /sales_order_materials/1.json
    def destroy
      @sales_order_material = SalesOrderMaterial.find(params[:id])
      @sales_order_material.destroy
      get_sales_material_details
  
      respond_to do |format|
        # format.html { redirect_to sales_order_materials_url }
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

      def get_sales_material_details
        @sales_order_materials = @sales_order_header.sales_order_details.sales_order_materials.order(:id)
      end
  end
end
