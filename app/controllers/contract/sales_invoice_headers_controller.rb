require_dependency "contract/application_controller"
require_dependency "contract/authorize"

module Contract
  class SalesInvoiceHeadersController < ApplicationController
    before_filter(:except => [:si_id_by_customer, :warehouse_by_si, :add_discount, :add_discount_put, :view_note, :view_delivery]) { |c| c.authorize_access c.controller_name, params[:tt] }
    before_filter :set_sales_invoice_header, only: [:show, :edit, :update, :status_post, :status_void, :add_discount, :add_discount_put, :show_post_void, :view_note, :show_triple, :revise, :view_delivery, :revision_process]
    before_filter :set_tax_type, only: [:index, :show, :new, :edit, :revise, :create, :update, :add_discount, :add_discount_put, :status_post, :status_void, :show_post_void, :paid_invoices]
    before_filter :get_currencies, only: [:new, :edit, :status_post, :status_void, :revision_process]
    before_filter :get_customer, only: [:index, :paid_invoices, :unpaid_invoice]
    respond_to :js, :only => [:view_note, :view_delivery, :add_discount, :add_discount_put, :warehouse_by_si, :si_id_by_customer]
    # GET /sales_invoice_headers
    # GET /sales_invoice_headers.json
    def index
      if params[:date].blank?
        @sales_invoice_headers = SalesInvoiceHeader.where("date_part('month', sales_invoice_date)=date_part('month', current_date) and date_part('year', sales_invoice_date)=date_part('year', current_date)")
      else
        @sales_invoice_headers = SalesInvoiceHeader.order("si_id DESC").search_month(params[:date][:month])
          .search_year(params[:date][:year]).search_amount(params[:start_amount], params[:end_amount])
          .search_customer(params[:customer].to_i).search_so_id(params[:so_id]).search_currency(params[:currency])
          .search_do_id(params[:do_id]).search_status(params[:status]).search_sales_person(params[:sales].to_i)
      end

      if @tax_type.to_s == 'x' # NON TAX
        @sales_invoice_headers = @sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_NON_TAX}%").order("si_id DESC").paginate(:per_page => 20, :page => params[:page])
      elsif @tax_type.to_s == 'l' # WITH TAX
        @sales_invoice_headers = @sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_TAX}%").order("si_id DESC").paginate(:per_page => 20, :page => params[:page])
      else # if unknown params
        if @split_tax_and_non_tax_transaction == 1
          redirect_to home_path
          return
        else
          @sales_invoice_headers = @sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_DEFAULT}%").order("si_id DESC").paginate(:per_page => 20, :page => params[:page])
        end
      end

      # @customers = Customer.all
      if @tax_type.to_s == 'x' # NON TAX
        @so_ids = SalesOrderHeader.posted.non_tax_transaction.select("distinct so_id").order("so_id DESC")
      elsif @tax_type.to_s == 'l'
        @so_ids = SalesOrderHeader.posted.tax_transaction.select("distinct so_id").order("so_id DESC")
      else
        @so_ids = SalesOrderHeader.posted.select("distinct so_id").order("so_id DESC")
      end

      @do_ids = DeliveryOrderHeader.posted.select("distinct do_id").order("do_id DESC")
      @sales = User.sales.order(:first_name)

      if @tax_type.to_s.present?
        @can_do_print = load_additional_resource('/delivery_order_header?tt='"#{params[:tt].to_s}",0)
        @can_print = load_additional_resource('/sales_invoice_headers?tt='"#{params[:tt].to_s}",0)
      else
        @can_do_print = load_additional_resource('/delivery_order_header',0)
        @can_print = load_additional_resource('/'"#{controller_name}",0)
      end

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @sales_invoice_headers }
        format.js
      end
    end

    # GET /sales_invoice_headers/1
    # GET /sales_invoice_headers/1.json
    def show
      @sales_invoice_details = SalesInvoiceDetail.find(:all, :joins => [:product], 
        :conditions => ["sales_invoice_details.sales_invoice_header_id = ?", params[:id].to_s], 
        :order => "sales_invoice_details.created_at")
      @status_help=0

      @total_discount = 0; @total_amount = 0
      @sales_invoice_details.each do |sid|
        @total_discount += sid.discount_amount.to_f
        @total_amount += sid.quantity.to_f * sid.price.to_f
      end

      if params[:format] == "pdf"
        if @sales_invoice_header.counter_print < 1
          @sales_invoice_header.update_attributes(:counter_print => @sales_invoice_header.counter_print.to_i + 1)
          prawnto :prawn => { :page_size => [595.28, 420.95], :page_layout => :portrait, :top_margin => 5, :left_margin => 10, :bottom_margin => 10 }, :inline => true
          can_do = 1
        else
          can_do = 0
        end
      end

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @sales_invoice_header }
        if params[:format]=="pdf"
          if can_do == 1
            format.pdf
          else 
            format.html { redirect_to sales_invoice_header_paths, notice: "#{t 'cannot_print'}" }
          end
        end
      end
    end

    def show_triple
      @sales_invoice_details = SalesInvoiceDetail.find(:all, :joins => [:product], :conditions => ["sales_invoice_details.sales_invoice_header_id = ?", params[:id].to_s], :order => "sales_invoice_details.created_at")
      @status_help=0

      prawnto :prawn => { :page_size => [595.28, 420.95], :page_layout => :portrait, :top_margin => 5, :left_margin => 10, :bottom_margin => 20 }, :filename => "#{I18n.t 'print_out'}-#{I18n.t 'sales_invoice'} Rangkap Tiga #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true

      respond_to do |format|
        if @sales_invoice_header.counter_print == 0
          @sales_invoice_header.update_attributes(:counter_print => 1)
          format.pdf
        else
          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to sales_invoice_headers_path(:tt => params[:tt].to_s), notice: "#{t 'cannot_print'}".html_safe }   
          else
            format.html { redirect_to sales_invoice_headers_path, notice: "#{t 'cannot_print'}".html_safe }
          end
        end
      end
    end

    # GET /sales_invoice_headers/new
    # GET /sales_invoice_headers/new.json
    def new
      @sales_invoice_header = SalesInvoiceHeader.new
      @sales_invoice_header.sales_invoice_date = Date.today.strftime("%d-%m-%Y")
      @sales_invoice_header.status = 0
      @sales_invoice_header.currency_id = @default_currency
      @sales_invoice_header.exchrate = @default_rate
      @sales_invoice_header.due_date = Date.today.strftime("%d-%m-%Y")
      @sales_invoice_header.employee_name = current_user.full_name

      # date_editor
      @readonly = false

      @so_ids = SalesOrderHeader.so_has_outstanding_qty.where(:id => 0)
      @sq_ids = SalesQuotationHeader.posted.order(:sq_id)
      @sales_persons = User.active.sales.order(:first_name)

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_invoice_header }
      end
    end

    # GET /sales_invoice_headers/1/edit
    def edit
      if @tax_type.to_s == 'x' # NON TAX
        @so_ids = SalesOrderHeader.so_has_outstanding_qty.non_tax_transaction.where(:customer_id => @sales_invoice_header.customer_id)
      elsif @tax_type.to_s == 'l'
        @so_ids = SalesOrderHeader.so_has_outstanding_qty.tax_transaction.where(:customer_id => @sales_invoice_header.customer_id)
      else
        @so_ids = SalesOrderHeader.so_has_outstanding_qty.where(:customer_id => @sales_invoice_header.customer_id)
        @sq_ids = SalesQuotationHeader.posted.sq_has_not_invoiced.not_close
                  .where("contract_sales_quotation_headers.customer_id = ?", @sales_invoice_header.customer_id)
                  .uniq.order(:sq_id).reverse_order
      end

      # date_editor
      @readonly = false

      @sales_persons = User.active.sales.select("users.id,users.first_name,users.last_name")
                        .joins("INNER JOIN sales_order_headers ON sales_order_headers.sales_id = users.id")
                        .where("sales_order_headers.so_id = ?", @sales_invoice_header.so_id)
    end

    def revise
      # check can revise role for current_user
      if @tax_type.to_s.present?
        # can_revise = load_additional_resource('/sales_invoice_headers?tt='"#{@tax_type.to_s}",1)
        can_revise = load_additional_resource(sales_invoice_headers_path(:tt => @tax_type),1)
      else
        can_revise = load_additional_resource(sales_invoice_headers_path,1)
      end
      
      if can_revise == false
        raise CanCan::AccessDenied
      end

      doh = DeliveryOrderHeader.where(:do_id => @sales_invoice_header.do_id).last

      if @sales_invoice_header.status != 5 && @sales_invoice_header.close == false && doh.status == 0
        sihs = SalesInvoiceHeader.have_sr(@sales_invoice_header.si_id).not_void
        if sihs.blank?
          @sales_invoice_header.revision_status = 1

          revision_process(@sales_invoice_header.id)
        else
          retur = ''
          sihs.each do |s|
            srh = SalesReturnHeader.where(:si_id => s.si_id).last
            if srh.present?
              retur += "#{srh.sr_id} " 
            end
          end
          respond_to do |format|
            if @split_tax_and_non_tax_transaction == 1
              format.html { redirect_to sales_invoice_headers_path(:tt => @tax_type.to_s, :page => params[:page]), notice: "#{t 'si.revision_fail', :retur => retur}" }   
            else
              format.html { redirect_to sales_invoice_headers_path(:page => params[:page]), notice: "#{t 'si.revision_fail', :retur => retur}" }
            end
          end
        end
      else
        respond_to do |format|
          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id, :tt => @tax_type.to_s), notice: "#{t 'transaction_void'}" }
          else
            format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id), notice: "#{t 'transaction_void'}" }
          end
        end
      end
    end

    def revision_process(sales_invoice_header_id)
      # void delivery order transaction header
      @delivery_order_header = DeliveryOrderHeader.where("do_id = ?", @sales_invoice_header.do_id).last
      
      # for module_type with accounting
      if @module_type == 2 || @module_type == 3 
        delete_general_ledger_transaction(@sales_invoice_header.si_id)
      else
        delete_account_receivable_transaction(@sales_invoice_header.si_id)
      end

      @transactions = Transaction.where(:reference_id => @sales_invoice_header.si_id, :transaction_date => @sales_invoice_header.sales_invoice_date)
      description = "Revisi transaksi penjualan dengan No. #{@sales_invoice_header.si_id}"
      @transactions.each do |transaction|
        if transaction.transaction_type.to_i==1
          type=0
        elsif transaction.transaction_type.to_i==0
          type=1
        else
          type=nil
        end

        amount = transaction.quantity * transaction.price
        # format stock_input(warehouse_id, product_id, price, model_quantity, id, updated_at, notes, amount, status, description, debet, credit, is_revise, currency, rate)
        # reference_id = change to do_id
        stock_input(transaction.warehouse_source_id, transaction.product_id, transaction.price, transaction.quantity, @delivery_order_header.do_id, 
          @sales_invoice_header.updated_at, @sales_invoice_header.notes, amount, type, description, 0, 0, true, @default_currency, @default_rate)

        delete_transaction(transaction.id)
      end
      # end reversing

      # set si status to entry
      @sales_invoice_header.update_attributes(:status => 0)

      # format create_log(subject, object, detail, employee_name)
      create_log("Revise", "Sales Invoice", "Revision header with id:#{@sales_invoice_header.si_id}, SO:#{@sales_invoice_header.so_id}, DO:#{@sales_invoice_header.do_id}, warehouse:#{@sales_invoice_header.warehouse.try(:name)}, customer:#{@sales_invoice_header.customer.try(:name)}, shipment:#{@sales_invoice_header.shipment}, delivery address:#{@sales_invoice_header.delivery_address}, amount:#{@sales_invoice_header.amount}, disc(%):#{@sales_invoice_header.discount}, disc(Rp):#{@sales_invoice_header.discount_amount}, tax:#{@sales_invoice_header.tax}, tax amount:#{@sales_invoice_header.tax_amount}, total:#{@sales_invoice_header.total_amount}, notes:#{@sales_invoice_header.notes}", current_user.full_name)

      respond_to do |format|
        if @split_tax_and_non_tax_transaction == 1
          format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id, :tt => @tax_type.to_s), notice: "#{t 'sales_invoice'} #{t 'can_revised'}" }
        else
          format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id), notice: "#{t 'sales_invoice'} #{t 'can_revised'}" }
        end 
      end
    end

    # POST /sales_invoice_headers
    # POST /sales_invoice_headers.json
    def create
      if @feature_check_due_date == 1 # TRUE
        can_do = SalesInvoiceHeader.check_due_date_invoice(params[:sales_invoice_header][:customer_id])
      else
        can_do = 1
      end

      if can_do.to_i==1
        @sales_invoice_header = SalesInvoiceHeader.create(params[:sales_invoice_header])

        if @split_tax_and_non_tax_transaction == 1
          si_id = SalesInvoiceHeader.si_header_id(params[:sales_invoice_header][:sales_invoice_date].to_date, @tax_type)
          if @tax_type == 'l'
            tax = TRUE
          else
            tax = FALSE
          end
        else
          si_id = SalesInvoiceHeader.si_header_id(params[:sales_invoice_header][:sales_invoice_date].to_date)
          tax = FALSE
        end

        @sales_order_header = SalesOrderHeader.where(:so_id => @sales_invoice_header.so_id).last

        due_date = params[:sales_invoice_header][:due_date]

        @sales_invoice_header.update_attributes(:si_id => si_id,
                                                :due_date => due_date, 
                                                :amount => 0, 
                                                :discount => @sales_order_header.discount.to_f, 
                                                :discount_amount => @sales_order_header.discount_amount.to_f, 
                                                :tax => tax, 
                                                :tax_amount => 0, 
                                                :total_amount => 0, 
                                                :status => 0, 
                                                :outstanding_total_amount => 0, :close => false)

        respond_to do |format|
          # format create_log(subject, object, detail, employee_name)
          create_log("Create Header", "Sales Invoice", "Create new header with id:#{@sales_invoice_header.si_id}, SO:#{@sales_invoice_header.so_id}, DO:#{@sales_invoice_header.do_id}, warehouse:#{@sales_invoice_header.warehouse.try(:name)}, customer:#{@sales_invoice_header.customer.try(:name)}, shipment:#{@sales_invoice_header.shipment}, delivery address:#{@sales_invoice_header.delivery_address}, due date:#{due_date}, notes:#{@sales_invoice_header.notes}.", current_user.full_name)

          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to sales_invoice_header_path(@sales_invoice_header, :tt => @tax_type), notice: "#{t 'sales_invoice'} #{t 'created'}" }
          else
            format.html { redirect_to @sales_invoice_header, notice: "#{I18n.t 'sales_invoice'} #{I18n.t 'created'}" }
          end

          format.json { render json: @sales_invoice_header, status: :created, location: @sales_invoice_header }
        end
      elsif can_do==0
        respond_to do |format|
          format.html { redirect_to sales_invoice_headers_path, notice: "Pelanggan masih memiliki faktur belum lunas yang melebihi 7 hari setelah jatuh tempo, faktur baru tidak dapat dibuat. Silahkan klik <u>#{view_context.link_to('disini', send_approval_request_approval_people_path(:customer_id => params[:sales_invoice_header][:customer_id]))}</u> untuk meminta persetujuan pada Supervisor.".html_safe }
        end
      else
        respond_to do |format|
          format.html { redirect_to sales_invoice_headers_path, notice: "#{t 'customer_not_found'}" }
        end
      end
    end

    # PUT /sales_invoice_headers/1
    # PUT /sales_invoice_headers/1.json
    def update
      customer_id=@sales_invoice_header.customer_id
      customer=@sales_invoice_header.customer.try(:name)
      warehouse=@sales_invoice_header.warehouse.try(:name)
      # shipping_agent_name=@sales_invoice_header.shipping_agent_name(@sales_invoice_header.shipping_id)
      shipment=@sales_invoice_header.shipment
      delivery_address=@sales_invoice_header.delivery_address
      so_id=@sales_invoice_header.so_id
      do_id=@sales_invoice_header.do_id
      notes=@sales_invoice_header.notes
      amount=@sales_invoice_header.amount
      discount=@sales_invoice_header.discount
      discount_amount=@sales_invoice_header.discount_amount
      tax=@sales_invoice_header.tax
      tax_amount=@sales_invoice_header.tax_amount
      total_amount=@sales_invoice_header.total_amount
      notes=@sales_invoice_header.notes

      respond_to do |format|
        if @split_tax_and_non_tax_transaction == 1
          month_prefix = @sales_invoice_header.si_id[6,2].to_i
        else
          month_prefix = @sales_invoice_header.si_id[5,2].to_i
        end
        if month_prefix == params[:sales_invoice_header][:sales_invoice_date].to_date.strftime("%m").to_i
          if @sales_invoice_header.update_attributes(params[:sales_invoice_header])
            # Delete all the details cause update relational data
            if so_id != params[:sales_invoice_header][:so_id] || customer_id != params[:sales_invoice_header][:customer_id]
              soh_id = SalesOrderHeader.where(:so_id => so_id).last.id
              sales_details = @sales_invoice_header.sales_invoice_details.order(:id)
              sales_details.each do |sid|
                # return so outstanding qty before destroy
                sod = SalesOrderDetail.where(:sales_order_header_id => soh_id, :product_id => sid.product_id).last
                if sod.present?
                  sod.update_attributes(:outstanding_qty => sod.outstanding_qty.to_f + sid.quantity.to_f)
                end
                sid.return_stock_end_qty_ready
                sid.destroy
              end
            end

            # format create_log(subject, object, detail, employee_name)
            create_log("Update Header", "Sales Invoice", "Update header with id:#{@sales_invoice_header.si_id}, SO from:#{so_id} to:#{@sales_invoice_header.so_id}, DO from:#{do_id} to:#{@sales_invoice_header.do_id}, warehouse from:#{warehouse} to:#{@sales_invoice_header.warehouse.try(:name)}, customer from:#{customer} to:#{@sales_invoice_header.customer.try(:name)}, shipment from:#{shipment} to:#{@sales_invoice_header.shipment}, delivery address from:#{delivery_address} to:#{@sales_invoice_header.delivery_address}, amount from:#{amount} to:#{@sales_invoice_header.amount}, disc(%) from:#{discount} to:#{@sales_invoice_header.discount}, disc(Rp) from:#{discount_amount} to:#{@sales_invoice_header.discount_amount}, tax from:#{tax} to:#{@sales_invoice_header.tax}, tax amount from:#{tax_amount} to:#{@sales_invoice_header.tax_amount}, total from:#{total_amount} to:#{@sales_invoice_header.total_amount}, notes from:#{} to:#{@sales_invoice_header.notes}", current_user.full_name)

            if @split_tax_and_non_tax_transaction == 1
              format.html { redirect_to sales_invoice_header_path(@sales_invoice_header, :tt => @tax_type), notice: "#{t 'sales_invoice'} #{t 'updated'}" }
            else
              format.html { redirect_to @sales_invoice_header, notice: "#{t 'sales_invoice'} #{t 'updated'}" }
            end
            format.json { head :no_content }
          else
            format.html { render action: "edit" }
            format.json { render json: @sales_invoice_header.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id), notice: "#{t 'warning.different_date_with_id'}" }
        end
      end
    end

    def add_discount_put
      # GET DATA BEFORE UPDATED FOR LOG
      discount_old=@sales_invoice_header.discount
      discount_amount_old=@sales_invoice_header.discount_amount
      cash_disc_old=@sales_invoice_header.cash_disc
      tax_old=@sales_invoice_header.tax
      tax_amount_old=@sales_invoice_header.tax_amount
      total_amount_old=@sales_invoice_header.total_amount
      # END GET DATA BEFORE UPDATED FOR LOG

      # promo disc
      discount = params[:sales_invoice_header][:discount]
      discount_amount = params[:sales_invoice_header][:discount_amount]
      # cash disc
      cash_discount = params[:sales_invoice_header][:cash_disc]
      tax = params[:sales_invoice_header][:tax]

      amount_before_cash_disc = @sales_invoice_header.amount.to_f - ((discount.to_f/100)*@sales_invoice_header.amount.to_f) - discount_amount.to_f
      amount_before_tax = amount_before_cash_disc.to_f - (amount_before_cash_disc.to_f*(cash_discount.to_f/100))

      # if tax=='1'
      if params[:tt].to_s == 'l' || tax == true || tax == 'true'
        tax_amount = amount_before_tax * 0.1
      else
        tax_amount = 0
      end

      total_amount = amount_before_tax + tax_amount.to_f

      @sales_invoice_details = @sales_invoice_header.sales_invoice_details.order(:id)

      @sales_invoice_header.update_attributes(:discount => discount, :discount_amount => discount_amount, :cash_disc => cash_discount,
        :tax => tax, :tax_amount => tax_amount, :total_amount => total_amount, :outstanding_total_amount => total_amount)

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Header", "Sales Invoice", "Update discount header with id:#{@sales_invoice_header.si_id}, amount:#{@sales_invoice_header.amount}, disc(%) from:#{discount_old} to:#{@sales_invoice_header.discount}, disc(Rp) from:#{discount_amount_old} to:#{@sales_invoice_header.discount_amount}, cash disc(%) from:#{cash_disc_old} to:#{@sales_invoice_header.cash_disc}, tax from:#{tax_old} to:#{@sales_invoice_header.tax}, tax amount from:#{tax_amount_old} to:#{@sales_invoice_header.tax_amount}, total from:#{total_amount_old} to:#{@sales_invoice_header.total_amount}.}", current_user.full_name)
    end

    def status_post
      @warehouse = Warehouse.find(@sales_invoice_header.warehouse_id)

      if @sales_invoice_header.status == 0
        company = Company.last
        can_do = 0; message = ""
        # get budget information
        budget = Customer.find(@sales_invoice_header.customer_id).budget.to_f

        if current_receivable_by_customer(@sales_invoice_header.customer_id, @sales_invoice_header.total_amount) <= budget
          # create transaction record and GL
          @sales_invoice_details = SalesInvoiceDetail.where("sales_invoice_header_id = ?", params[:id])
          @customer = Customer.where(:id => @sales_invoice_header.customer_id).last
        
          sum_quantity = SalesInvoiceDetail.find(:all, :select => "sum(quantity) as sum_quantity", 
            :conditions => ["sales_invoice_header_id = ?", params[:id].to_s]).last.sum_quantity

          sub_amount = @sales_invoice_header.amount
          sub_discount = @sales_invoice_header.discount
          sub_disc_amount = @sales_invoice_header.discount_amount
          sub_cash_disc = @sales_invoice_header.cash_disc
          sub_tax = @sales_invoice_header.tax
          if sub_tax==true
            tax=0.1
          else
            tax=0
          end

          # total disc before cash disc
          total_disc_before_cash_disc = (sub_amount.to_f*(sub_discount.to_f/100)) + sub_disc_amount.to_f

          total_disc = total_disc_before_cash_disc.to_f - (total_disc_before_cash_disc.to_f*(sub_cash_disc.to_f/100))
          disc_per_quantity = total_disc.to_f/sum_quantity.to_f

          # CHECKING PKP ETC
          # sales_tax_account = JournalDiscTax.where(:description => 'Pajak/Tax Penjualan').last.try(:chart_of_account_id)
          sales_tax_account = CurrencyStaticAccount.where(:description => 'Pajak/Tax Penjualan', 
            :currency_id => @sales_invoice_header.currency_id).last.try(:chart_of_account_id)
          company = Company.last
          @is_pkp = 0
          if company.present?
            if company.try(:is_pkp) == true && sales_tax_account!=0 && @sales_invoice_header.tax_amount!=0
              debet_account = 0
              @is_pkp = 1
            end
          end

          gl_notes = "Penjualan dengan nomor faktur #{@sales_invoice_header.si_id} untuk Customer: #{@sales_invoice_header.customer.name}."

          cek = 0
          old_sales_account = 0
          sid_count = @sales_invoice_header.sales_invoice_details.count
          product_desc = ''
          @sales_invoice_details.each do |sid|
            can_do, message = inventory_checking(@sales_invoice_header.warehouse_id, sid.product_id, sid.quantity)
            break if can_do == 0
          end

          if can_do == 1
            commission = 0

            # insert SI header to DO header
            notes = "(SO: #{@sales_invoice_header.so_id}, SI: #{@sales_invoice_header.si_id}) #{@sales_invoice_header.notes}"

            if @sales_invoice_header.do_id.present?
              doh = DeliveryOrderHeader.where(:do_id => @sales_invoice_header.do_id).last
              dods = DeliveryOrderDetail.where(:delivery_order_header_id => doh.id)
            else
              doh = []
            end

            if doh.blank? || doh.status == 5
              @delivery_order_header = DeliveryOrderHeader.create(:do_id => DeliveryOrderHeader.do_header_id("SI", @sales_invoice_header.sales_invoice_date, @sales_invoice_header.warehouse_id, @tax_type),
                                                                  :ref_id => @sales_invoice_header.si_id, 
                                                                  :delivery_order_date => Date.today.strftime("%Y-%m-%d"), 
                                                                  :warehouse_id => @sales_invoice_header.warehouse_id, 
                                                                  :name => @customer.name, 
                                                                  :address => @customer.address, 
                                                                  :city => @customer.city.try(:name), 
                                                                  :notes => notes, 
                                                                  :employee_name => current_user.full_name, 
                                                                  :status => 0, :is_mutation => false, :close => false)
              # update sales invoice header do_id
              @sales_invoice_header.update_attributes(:do_id => @delivery_order_header.do_id)
              # --------------------------- #
            end

            @sales_invoice_details.each do |sid|
              @product = Product.find(sid.product_id)

              price = sid.price
              disc = sid.discount_item
              disc_item = sid.discount_item_price

              price_after_disc = price.to_f - ((disc.to_f/100)*price.to_f) - (disc_item.to_f/sid.quantity) - disc_per_quantity.to_f

              if @sales_invoice_header.tax_amount!=0 && @is_pkp==1 # harga tidak termasuk ppn
                price_new = price_after_disc.to_f
              else # kalau bukan pkp
                sub_tax_amount_new = tax.to_f*price_after_disc.to_f
                price_new = price_after_disc.to_f + sub_tax_amount_new.to_f
              end
              amount = sid.quantity.to_f * price_new.to_f

              # Get Item Category commission
              category_id = Product.find(sid.product_id).category_id
              commission += (Category.find(category_id).commission.to_f / 100) * price_after_disc

              # creating/updating sales_price
              sales_price = SalesPrice.where(:customer_id => @customer.id, :product_id => @product.id).last
              if sales_price.blank?
                sales_price = SalesPrice.create(:transaction_date => @sales_invoice_header.updated_at, :customer_id => @customer.id, 
                  :product_id => @product.id, :price => price_new * @sales_invoice_header.exchrate)
              else
                sales_price.update_attributes(:transaction_date => @sales_invoice_header.updated_at, :price => price_new * @sales_invoice_header.exchrate)
              end
              # end sales_price

              # update product ordered outstanding qty with invoiced qty
              @sod = SalesOrderDetail.find(:all, :joins => [:sales_order_header], 
                :conditions => ["sales_order_headers.so_id = ? and sales_order_details.product_id = ?", @sales_invoice_header.so_id, sid.product_id]).last

              outstanding_qty_new = (@sod.outstanding_qty.to_f - sid.quantity.to_f)
              @sales_order_detail = SalesOrderDetail.find(@sod.id)
              @sales_order_detail.update_attributes(:outstanding_qty => outstanding_qty_new.to_f)

              if doh.blank? || doh.status == 5 || dods.blank?
                if dods.blank?
                  @delivery_order_header = DeliveryOrderHeader.where(:do_id => @sales_invoice_header.do_id).first
                end
                # insert SI detail data to DO detail
                @delivery_order_detail = @delivery_order_header.delivery_order_details.create(:product_id => sid.product_id, 
                                                                                              :quantity => sid.quantity.to_f, 
                                                                                              :unit_of_measure_id => sid.unit_of_measure_id)
              end

              if @module_type == 2 || @module_type == 3
                # GL ACCOUNT FOR INVENTORY (D:HPP, C:Inventory)
                # if using Product Warehouse
                # debet_account = get_product_account(sid.product_id, @sales_invoice_header.warehouse_id, 1) # stock output account/HPP
                # credit_account = get_product_account(sid.product_id, @sales_invoice_header.warehouse_id, 0) # stock input account/inventory

                # if not using Product Warehouse
                debet_account = Product.find(sid.product_id).try(:stock_output_account) # stock output account/HPP
                credit_account = Product.find(sid.product_id).try(:chart_of_account_id) # stock input account/inventory
              else
                debet_account = 0
                credit_account = 0
              end

              # FORMAT stock_output(warehouse_id, product_id, model_quantity, id, notes, updated_at, status, description, debet, credit)
              cogs = stock_output(@sales_invoice_header.warehouse_id, sid.product_id, sid.quantity, @sales_invoice_header.si_id, @sales_invoice_header.notes, 
                @sales_invoice_header.sales_invoice_date, @sales_invoice_header.status, gl_notes, debet_account, credit_account, @default_currency, @default_rate)

              total_amount =+ amount
            end # end detail loop

            if @module_type == 2 || @module_type == 3
              # =======================================
              # INPUT GL FOR SALES (D:AR, C:Sales, Tax)
              # =======================================

              # @sjds = SalesInvoiceDetail.where("sales_invoice_header_id = ?", params[:id]).first
              # sales_coa = get_product_account(@sjds.product_id, @warehouse.id, 2) # income account
              sales_coa = CurrencyStaticAccount.where(:description => 'Penjualan', 
                :currency_id => @sales_invoice_header.currency_id).last.try(:chart_of_account_id) # sales income account

              # receivable_account = @customer.chart_of_account_id
              receivable_account = @customer.customer_accounts.where(:currency_id => @sales_invoice_header.currency_id).last.account_receivable
              
              sales_total_amount = @sales_invoice_header.total_amount.to_f - @sales_invoice_header.tax_amount.to_f
              # AR DEBET GL
              # format create_gl(date, reference, notes, amount, coa, transaction_status, description, currency, exchange rate)
              create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, 
                (sales_total_amount * @sales_invoice_header.exchrate.to_f), receivable_account, 'D', gl_notes, 
                sales_coa, @sales_invoice_header.currency_id, @sales_invoice_header.exchrate, sales_total_amount)
              # format general_ledger_balance(coa_id, amount, transaction_status)
              general_ledger_balance(receivable_account, (sales_total_amount * @sales_invoice_header.exchrate.to_f), "D", @sales_invoice_header.sales_invoice_date)

              # SALES CREDIT GL
              # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
              create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, 
                (sales_total_amount * @sales_invoice_header.exchrate.to_f), sales_coa, 'C', gl_notes, receivable_account, 
                @sales_invoice_header.currency_id, @sales_invoice_header.exchrate, sales_total_amount)
              # format general_ledger_balance(coa_id, amount, transaction_status)
              general_ledger_balance(sales_coa, (sales_total_amount * @sales_invoice_header.exchrate.to_f), "C", @sales_invoice_header.sales_invoice_date)

              # CHECKING PKP ETC
              # sales_tax_account = JournalDiscTax.where(:description => 'Pajak/Tax Penjualan').last.try(:chart_of_account_id)
              sales_tax_account = CurrencyStaticAccount.where(:description => 'Pajak/Tax Penjualan', 
                :currency_id => @sales_invoice_header.currency_id).last.try(:chart_of_account_id)

              company = Company.last
              @is_pkp = 0
              if company.present?
                if company.try(:is_pkp) == true && sales_tax_account!=0 && @sales_invoice_header.tax_amount!=0
                  debet_account = 0
                  @is_pkp = 1
                end
              end

              # INPUT TAX AMOUNT
              if @sales_invoice_header.tax_amount!=0 && @is_pkp==1
                # AR INPUT GL WITH TRANSACTION CURRENCY
                # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, 
                  (@sales_invoice_header.tax_amount.to_f * @sales_invoice_header.exchrate.to_f), receivable_account, 'D', 
                  gl_notes, sales_tax_account, @sales_invoice_header.currency_id, @sales_invoice_header.exchrate, @sales_invoice_header.tax_amount.to_f)
                # format general_ledger_balance(coa_id, amount, transaction_status)
                general_ledger_balance(receivable_account, (@sales_invoice_header.tax_amount.to_f * @sales_invoice_header.exchrate.to_f), "D", @sales_invoice_header.sales_invoice_date)
                # TAXES INPUT GL
                # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, 
                  (@sales_invoice_header.tax_amount.to_f * @sales_invoice_header.exchrate.to_f), sales_tax_account, 'C', 
                  gl_notes, receivable_account, @sales_invoice_header.currency_id, @sales_invoice_header.exchrate, @sales_invoice_header.tax_amount.to_f)
                # format general_ledger_balance(coa_id, amount, transaction_status)
                general_ledger_balance(sales_tax_account, (@sales_invoice_header.tax_amount.to_f * @sales_invoice_header.exchrate.to_f), "C", @sales_invoice_header.sales_invoice_date)

                # PROSES MATA UANG ASING
                if @sales_invoice_header.currency.try(:is_default) == false
                  cross_sales_tax_account = CurrencyStaticAccount.where(:description => 'Pajak/Tax Penjualan',
                    :currency_id => Currency.is_default.id).last.try(:chart_of_account_id)

                  cross_receivable_account = CurrenctStaticAccount.where(:description => 'Pajak/Tax Penjualan',
                    :currency_id => @default_currency).last.try(:chart_of_account_id)
                  tax_amount_conv = @sales_invoice_header.tax_amount * @sales_invoice_header.exchrate
                  
                  # AR INPUT GL REVERSE JOURNAL FOR GST WITH FOREIGN CURRENCY
                  # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                  create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, 
                    (@sales_invoice_header.tax_amount.to_f * @sales_invoice_header.exchrate.to_f), sales_tax_account, 'D', gl_notes, 
                    receivable_account, @sales_invoice_header.currency_id, @sales_invoice_header.exchrate, @sales_invoice_header.tax_amount.to_f)
                  # format general_ledger_balance(coa_id, amount, transaction_status)
                  general_ledger_balance(sales_tax_account, (@sales_invoice_header.tax_amount.to_f * @sales_invoice_header.exchrate.to_f), "D", @sales_invoice_header.sales_invoice_date)
                  # TAXES INPUT GL
                  # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                  create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, @sales_invoice_header.tax_amount.to_f, 
                    receivable_account, 'C', gl_notes, sales_tax_account, @sales_invoice_header.currency_id, @sales_invoice_header.exchrate)
                  # format general_ledger_balance(coa_id, amount, transaction_status)
                  general_ledger_balance(receivable_account, (@sales_invoice_header.tax_amount.to_f * @sales_invoice_header.exchrate.to_f), "C", @sales_invoice_header.sales_invoice_date)

                  #AR INPUT GL FOR GST WITH LOCAL CURRENCY
                  # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                  create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, tax_amount_conv.to_f, 
                    cross_receivable_account, 'D', gl_notes, cross_sales_tax_account, @default_currency, @default_rate, @sales_invoice_header.tax_amount.to_f)
                  # format general_ledger_balance(coa_id, amount, transaction_status)
                  general_ledger_balance(cross_receivable_account, tax_amount_conv.to_f, "D", @sales_invoice_header.sales_invoice_date)
                  # TAXES INPUT GL
                  # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                  create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, tax_amount_conv.to_f, 
                    cross_sales_tax_account, 'C', gl_notes, cross_receivable_account, @default_currency, @default_rate, @sales_invoice_header.tax_amount.to_f)
                  # format general_ledger_balance(coa_id, amount, transaction_status)
                  general_ledger_balance(cross_sales_tax_account, tax_amount_conv.to_f, "C", @sales_invoice_header.sales_invoice_date)
                end
                ##################################
                
              end
              # ===========================================
              # END INPUT GL FOR SALES (D:AR, C:Sales, Tax)
              # ===========================================
            else # inventory only
              # create_account_receivable_transaction(transaction_date,ref_id,customer_id,amount,notes,transaction_status)
              create_account_receivable_transaction(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id,
                @sales_invoice_header.customer_id, @sales_invoice_header.total_amount, gl_notes, 'D')
            end # accounting process

            if @calculate_sales_commission.to_i == 1
              commission_amount = commission.to_f * exchrate.to_f
              # Count commission for sales person per invoice amount (before tax)
              if @sales_invoice_header.sales_id.present? && commission_amount > 0
                if @module_type == 2 || @module_type == 3
                  # Get Salesman Commission account
                  commission_account = User.find(sales_id).commission_exp_account
                  other_ap_account = User.find(sales_id).ap_account

                  # COMMISSION DEBET GL
                  # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                  create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, commission_amount, 
                    commission_account, 'D', gl_notes, other_ap_account, @default_currency, @default_rate, 0)
                  # format general_ledger_balance(coa_id, amount, transaction_status)
                  general_ledger_balance(commission_account, commission_amount, "D", @sales_invoice_header.sales_invoice_date)

                  # OTHER AP CREDIT GL
                  # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
                  create_gl(@sales_invoice_header.sales_invoice_date, @sales_invoice_header.si_id, @sales_invoice_header.notes, commission_amount, 
                    other_ap_account, 'C', gl_notes, commission_account, @default_currency, @default_rate, 0)
                  # format general_ledger_balance(coa_id, amount, transaction_status)
                  general_ledger_balance(other_ap_account, commission_amount, "C", @sales_invoice_header.sales_invoice_date)
                else
                  create_sales_commission_transaction(@sales_invoice_header.sales_invoice_date, 
                    @sales_invoice_header.sales_id, @sales_invoice_header.si_id, commission_amount)
                end
              end
            end

            @sales_invoice_header.update_attributes(:status => 1)

            # format create_log(subject, object, detail, employee_name)
            create_log("Post", "Sales Invoice", "Post header with id:#{@sales_invoice_header.si_id}, SO:#{@sales_invoice_header.so_id}, DO:#{@sales_invoice_header.do_id}, warehouse:#{@sales_invoice_header.warehouse.try(:name)}, customer:#{@sales_invoice_header.customer.try(:name)}, shipment:#{@sales_invoice_header.shipment}, delivery address:#{@sales_invoice_header.delivery_address}, amount:#{@sales_invoice_header.amount}, disc(%):#{@sales_invoice_header.discount}, disc(Rp):#{@sales_invoice_header.discount_amount}, tax:#{@sales_invoice_header.tax}, tax amount:#{@sales_invoice_header.tax_amount}, total:#{@sales_invoice_header.total_amount}, notes:#{@sales_invoice_header.notes}", current_user.full_name)

            if @split_tax_and_non_tax_transaction == 1
              redirect_to sales_invoice_headers_path(:tt => params[:tt].to_s)
            else
              redirect_to sales_invoice_headers_path
            end
          else
            respond_to do |format|
              if @split_tax_and_non_tax_transaction == 1
                format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id, :tt => params[:tt].to_s), notice: "#{t 'si.post_stock_fail', :product => message }" }
              else
                format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id), notice: "#{t 'si.post_stock_fail', :product => message }" }
              end
            end
          end # can_do
        else
          respond_to do |format|
            if @split_tax_and_non_tax_transaction == 1
              format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id, :tt => params[:tt].to_s), notice: "#{I18n.t 'si.post_fail', :customer => @sales_invoice_header.customer.try(:name)}" }
            else
              format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id), notice: "#{I18n.t 'si.post_fail', :customer => @sales_invoice_header.customer.try(:name)}" }
            end
          end
        end
      else
        respond_to do |format|
          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id, :tt => params[:tt].to_s), notice: "#{t 'transaction_approved'}" }
          else
            format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id), notice: "#{t 'transaction_approved'}" }
          end
        end
      end
    end

    def status_void
      if @sales_invoice_header.status != 5
        @sales_invoice_details = @sales_invoice_header.sales_invoice_details.order(:id)
        @customer = Customer.find(@sales_invoice_header.customer_id)

        # void delivery order transaction header
        @delivery_order_header = DeliveryOrderHeader.where("do_id = ?", @sales_invoice_header.do_id).last
        @delivery_order_header.update_attributes(:status => 5)

        # adding outstanding_qty back
        sales_order_header = SalesOrderHeader.where(:so_id => @sales_invoice_header.so_id).last
        sales_order_details = sales_order_header.sales_order_details.order(:id)

        @sales_invoice_details.each  do |sid|
          # sales_order_details.each do |sod|
          #   if sid.product_id == sod.product_id
          #     outstanding_qty_new = sod.outstanding_qty + sid.quantity
          #     sod.update_attributes(:outstanding_qty => outstanding_qty_new)
          #   end
          # end
          sid.return_so_outstanding_qty
        end
        # adding outsanding_qty back

        # create reversing transaction and GL entry.

        # for module_type with accounting
        if @module_type == 2 || @module_type == 3 
          notes = "Proses void faktur penjualan dgn No.#{@sales_invoice_header.si_id}"
          # FORMAT: reversing_gl_transaction(reference_id, updated_at, notes) => check on application_controller.rb
          reversing_gl_transaction(@sales_invoice_header.si_id, @sales_invoice_header.updated_at, notes)
        else
          notes = "Proses void faktur penjualan dgn No.#{@sales_invoice_header.si_id}"
          create_account_receivable_transaction(@sales_invoice_header.sales_invoice_date,@sales_invoice_header.si_id,@sales_invoice_header.customer_id,
            @sales_invoice_header.total_amount,notes,'D')
        end
      
        @transactions = Transaction.where(:reference_id => @sales_invoice_header.si_id)
        @transactions.each do |transaction|
          if transaction.transaction_type==1
            type=0
          elsif transaction.transaction_type==0
            type=1
          else
            type=nil
          end

          amount = transaction.quantity * transaction.price
          # format stock_input(warehouse_id, product_id, price, model_quantity, id, updated_at, notes, amount, status, description, debet, credit)
          stock_input(transaction.warehouse_source_id, transaction.product_id, transaction.price, transaction.quantity, @sales_invoice_header.si_id, 
            @sales_invoice_header.updated_at, @sales_invoice_header.notes, amount, type, notes, 0, 0, @default_currency, @default_rate)
        end
        # end reversing

        @sales_invoice_header.update_attributes(:status => 5)

        # format create_log(subject, object, detail, employee_name)
        create_log("Void", "Sales Invoice", "Void header with id:#{@sales_invoice_header.si_id}, SO:#{@sales_invoice_header.so_id}, DO:#{@sales_invoice_header.do_id}, warehouse:#{@sales_invoice_header.warehouse.try(:name)}, customer:#{@sales_invoice_header.customer.try(:name)}, shipment:#{@sales_invoice_header.shipment}, delivery address:#{@sales_invoice_header.delivery_address}, amount:#{@sales_invoice_header.amount}, disc(%):#{@sales_invoice_header.discount}, disc(Rp):#{@sales_invoice_header.discount_amount}, tax:#{@sales_invoice_header.tax}, tax amount:#{@sales_invoice_header.tax_amount}, total:#{@sales_invoice_header.total_amount}, notes:#{@sales_invoice_header.notes}", current_user.full_name)

        if @split_tax_and_non_tax_transaction == 1
          redirect_to sales_invoice_headers_path(:tt => params[:tt].to_s)
        else
          redirect_to sales_invoice_headers_path
        end
      else
        respond_to do |format|
          format.html { redirect_to sales_invoice_header_path(@sales_invoice_header.id), notice: "#{t 'transaction_void'}" }
        end
      end
    end

    def show_post_void
      @sales_invoice_details = SalesInvoiceDetail.find(:all, :joins => [:product], 
        :conditions => ["sales_invoice_details.sales_invoice_header_id = " + params[:id].to_s], 
        :order => "sales_invoice_details.created_at")

      prawnto :prawn => {:top_margin => 20}, :filename => "#{I18n.t 'print_out'}-#{I18n.t 'sales_invoice'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true

      respond_to do |format|
        format.html
        format.pdf
      end
    end

    def paid_invoices
      @customer_trans = SalesInvoiceHeader.customer_total_paid(params[:currency].to_i,params[:customer].to_i,@tax_type)

      respond_to do |format|
        format.html
        format.js
        format.pdf
      end
    end

    def unpaid_invoice
      # customer_total_unpaid(tax_type=0)
      @customer_trans = SalesInvoiceHeader.customer_total_unpaid(params[:currency].to_i,params[:customer].to_i)

      if params[:format] == "pdf"
        @reports = []
        if @customer_trans.present?
          @customer_trans.each do |c|
            @reports.push ["", "#{t 'customer'}", c.customer.name, "#{t 'total_amount'}", c.sum_total_amount]
            @reports.push ["#{t 'number'}".upcase, "#{t 'si_id'}".upcase, "#{t 'dates'}".upcase, "#{t 'due_date'}".upcase, "#{t 'total_amount'}".upcase]
            unpaid_invoice = SalesInvoiceHeader.unpaid_by_customer(c.customer_id)
            i=0; unpaid_invoice.each do |u|
              @reports.push [i+=1, u.si_id, u.sales_invoice_date.try(:strftime, "%d-%m-%Y"), u.due_date.try(:strftime, "%d-%m-%Y"), u.outstanding_total_amount]
            end
          end
        else
          @reports.push ["","","NO. DATA","",""]
        end

        prawnto :prawn => {:top_margin => 10}, :filename => "#{I18n.t 'print_out'}-#{I18n.t 'unpaid_sales_invoice'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true
      end

      respond_to do |format|
        format.html
        format.js
        format.pdf { render :layout => false }
      end
    end

    def si_id_by_customer
      if params[:id].present?
        @si_ids = SalesInvoiceHeader.posted.si_has_outstanding_qty.where("sales_invoice_headers.customer_id = ?", "#{params[:id]}").order("si_id ASC").uniq
      else
        @si_ids = SalesInvoiceHeader.posted.si_has_outstanding_qty.uniq
      end
    end

    def warehouse_by_si
      if params[:id].present?
        @warehouse = SalesInvoiceHeader.select("warehouse_id id, warehouses.name").joins(:warehouse).where(:si_id => params[:id]).last
      else
        @warehouse = []
      end
    end

    def report_generator(tt=nil)
      @sales_invoice_headers = SalesInvoiceHeader.posted
      .report_period(params[:start_period].to_date, params[:end_period].to_date)
      .search_amount(params[:start_amount], params[:end_amount])
      .search_customer(params[:customer].to_i)

      if tt.to_s == 'x'
        @sales_invoice_headers = @sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_NON_TAX}%").order(:si_id)
      elsif tt.to_s == 'l'
        @sales_invoice_headers = @sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_TAX}%").order(:si_id)
      else
        @sales_invoice_headers = @sales_invoice_headers.order(:si_id)
      end

      header_ids=[]
      @sales_invoice_headers.each do |header|
        header_ids.push [header.id]
      end
      @sales_invoice_details = SalesInvoiceDetail.where(:sales_invoice_header_id => [header_ids])

      @sales_invoices = []
      @total_rows = 0
      total = 0
      header_row = 0
      @sales_invoice_headers.each do |header|
        header_row+=1
        if header.tax==true
          tax="10%"
        else
          tax=''
        end
        @sales_invoices.push [header_row, 
          header.si_id, 
          header.so_id, 
          header.do_id, 
          header.sales_invoice_date.strftime("%m-%d-%Y"), 
          header.customer.try(:name), 
          header.amount, 
          header.discount, 
          header.discount_amount,
          tax, 
          "", 
          header.total_amount,
          header.id]

        total+=header.total_amount.to_f
        @total_rows+=1
        @sales_invoice_details.each do |detail|
          if detail.sales_invoice_header_id==header.id
            qty = "#{detail.quantity} #{detail.unit_of_measure.try(:name)}"
            @sales_invoices.push ["", detail.product.try(:name), "", "", qty, "(price:)", detail.price, detail.discount_item, detail.discount_item_price, "", detail.total_amount, "", ""]
            @total_rows+=1
          end
        end
      end
      @sales_invoices.push ["", "", "", "", "", "", "", "", "", "", "#{(t 'total').upcase}", total, ""]
      @total_rows+=1
    end

    def report_filter
      if params[:start_period].present?
        if params[:tt].present?
          report_generator(params[:tt].to_s)
          @can_print = load_additional_resource('/sales_invoice_headers?tt='"#{params[:tt].to_s}",0)
        else
          report_generator
          @can_print = load_additional_resource('/'"#{controller_name}",0)
        end
      else
        @sales_invoices = []
        @can_print = false
      end
      
      respond_to do |format|
        if params[:print]
          if params[:tt].present?
            format.html { redirect_to :action => "report", :format => "pdf", 
              :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, 
              :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount], :tt => params[:tt].to_s }
          else
            format.html { redirect_to :action => "report", :format => "pdf", 
              :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, 
              :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount] }
          end
        elsif params[:excel]
          if params[:tt].present?
            format.html { redirect_to :action => "report", :format => "xls", 
              :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, 
              :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount], :tt => params[:tt].to_s }
          else
            format.html { redirect_to :action => "report", :format => "xls", 
              :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, 
              :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount] }
          end
        elsif params[:tax_invoice]
          if params[:tt].present?
            format.html { redirect_to :action => "tax_invoice", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount], :tt => params[:tt].to_s }
          else
            format.html { redirect_to :action => "tax_invoice", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount] }
          end
        else
          format.html
          # format.js
        end
      end
    end

    def report
      if params[:tt].present?
        report_generator(params[:tt].to_s)
      else
        report_generator
      end

      @start_period = params[:start_period].to_date.strftime("%d-%m-%Y")
      @end_period = params[:end_period].to_date.strftime("%d-%m-%Y")

      if params[:start_amount].to_i==0
        @start_amount = "All"
      else
        @start_amount = params[:start_amount]
        @start_amount = "Rp " + @start_amount
      end

      if params[:end_amount].to_i==0
        @end_amount = "All"
      else
        @end_amount = params[:end_amount]
        @end_amount = "Rp " + @end_amount
      end

      if params[:customer].to_i==0
        @customer = "All"
      else
        @customer = Customer.find(params[:customer]).name
      end

      @employee = current_user.full_name

      prawnto :prawn => {:top_margin => 35}, :filename => "#{I18n.t 'report'}-#{I18n.t 'sales_invoice'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true

      respond_to do |format|
        format.pdf { render :layout => false }
        format.csv { send_data @sales_invoices.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'report'}-#{I18n.t 'sales_invoice'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
      end
    end

    def tax_invoice_generator
      @sales_invoice_headers = SalesInvoiceHeader.posted.with_tax
      .report_period(params[:start_period].to_date, params[:end_period].to_date)
      .search_amount(params[:start_amount], params[:end_amount])
      .search_customer(params[:customer].to_i)

      if tt.to_s == 'x'
        @sales_invoice_headers = @sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_NON_TAX}%").order(:si_id)
      elsif tt.to_s == 'l'
        @sales_invoice_headers = @sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_TAX}%").order(:si_id)
      else
        @sales_invoice_headers = @sales_invoice_headers.order(:si_id)
      end

      header_ids=[]
      @sales_invoice_headers.each do |header|
        header_ids.push [header.id]
      end
      @sales_invoice_details = SalesInvoiceDetail.where(:sales_invoice_header_id => [header_ids])

      @sales_invoices = []
      @total_rows = 0
      total = 0
      header_row = 0
      @sales_invoice_headers.each do |header|
        header_row+=1
        if header.tax==true
          tax="10%"
        else
          tax=''
        end
        @sales_invoices.push [header_row, 
          header.si_id, 
          header.so_id, 
          header.do_id, 
          header.sales_invoice_date.strftime("%m-%d-%Y"), 
          header.customer.try(:name), 
          header.amount, 
          header.discount, 
          header.discount_amount,
          tax, 
          "", 
          header.total_amount,
          header.id]

        total+=header.total_amount
        @total_rows+=1
        @sales_invoice_details.each do |detail|
          if detail.sales_invoice_header_id==header.id
            qty = "#{detail.quantity} #{detail.unit_of_measure.try(:name)}"
            @sales_invoices.push ["", 
              detail.product.try(:name), "", "", 
              qty, "(price:)", 
              detail.price, 
              detail.discount_item, 
              detail.discount_item_price, "", 
              detail.total_amount, "", ""]
            @total_rows+=1
          end
        end
      end
      @sales_invoices.push ["", "", "", "", "", "", "", "", "", "", "#{(t 'total').upcase}", total, ""]
      @total_rows+=1
    end

    def tax_invoice_filter
      if params[:start_period].present?
        tax_invoice_generator
      else
        @sales_invoices = []
      end
      respond_to do |format|
        if params[:tax_invoice]
          format.html { redirect_to :action => "tax_invoice", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount] }
        elsif params[:tax_invoice_report]
          format.html { redirect_to :action => "tax_invoice_report", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount] }
        else
          format.html
          format.js
        end
      end
    end

    def tax_invoice
      @sales_invoice_headers = SalesInvoiceHeader.posted.with_tax
      .report_period(params[:start_period].to_date, params[:end_period].to_date)
      .search_amount(params[:start_amount], params[:end_amount])
      .search_customer(params[:customer].to_i)
      .order(:si_id)

      respond_to do |format|
        format.pdf do
          pdf = TaxInvoicePdf.new(@sales_invoice_headers, view_context, ApplicationController.helpers.employee_full_name(current_user.id))
          send_data pdf.render, filename: "#{I18n.t 'standart_tax_invoice'} #{Time.now.localtime.strftime("%Y-%m-%d %H.%M.%S")}.pdf", 
          type: "application/pdf", disposition: "inline"
        end
        format.csv { send_data @models.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'standart_tax_invoice'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
      end
    end

    def tax_invoice_report
      tax_invoice_generator

      if params[:start_period].present? and params[:end_period].present?
        @start_period = params[:start_period].to_date.strftime("%d-%m-%Y")
        @end_period = params[:end_period].to_date.strftime("%d-%m-%Y")
      end

      @employee = current_user.full_name

      prawnto :prawn => {:top_margin => 35}, :filename => "#{I18n.t 'report'}-#{I18n.t 'standart_tax_invoice'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true

      respond_to do |format|
        format.pdf { render :layout => false }
        format.csv { send_data @sales_invoices.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'report'}-#{I18n.t 'standart_tax_invoice'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
      end
    end

    def cross_tab_report_generator
      @start_period = params[:start_period].to_date
      @end_period = params[:end_period].to_date
      day   = @start_period.strftime("%d").to_i
      month = @start_period.strftime("%m").to_i
      year  = @start_period.strftime("%Y").to_i
      ep_day   = @end_period.strftime("%d").to_i
      ep_month = @end_period.strftime("%m").to_i
      ep_year  = @end_period.strftime("%Y").to_i
      @models = [[]] # for PDF and XLS

      # get all month to process
      @months=0
      if ep_year-year>0 # crossing year
        (year..ep_year).each do |i| # looping the crossing years
          if i==year
            start_month = month
            end_month = 12
          elsif i==ep_year
            start_month = 1
            end_month = ep_month
          else
            start_month = 1
            end_month = 12
          end

          if end_month-start_month>0 # crossing month
            (start_month..end_month).each do |i| # looping through months
              @months+=1
            end # looping through months
          elsif end_month-start_month=0 # same month
            @months+=1
          else # end month greater than start month, fail
            can_do=0
          end
        end # looping the crossing years
      elsif ep_year-year==0 # same year
        if ep_month-month>0 # crossing month
          (month..ep_month).each do |i| # looping through months
            @months+=1
          end # looping through months
        elsif ep_month-month==0 # same month
          @months+=1
        else # end month greater than start month, fail
          can_do=0
        end
      else # end year greater than start year, fail
        can_do=0
      end

      (1..@months).each do |i| # need to update those 999
        @rows = [[]]

        if i!=1 # first day gonna be start day
          day=1
        end

        if month==13
          year+=1
          month=1
        end

        if month==ep_month && year==ep_year
          end_day = ep_day
        else
          end_day = "#{year}-#{month}-01".to_date.end_of_month.strftime("%d").to_i
        end

        @sales_invoice_headers = SalesInvoiceHeader.posted.report_period("%02d"%month + "/%02d"%day + "/#{year}", "%02d"%month + "/%02d"%end_day + "/#{year}").search_warehouse(params[:warehouse].to_i).order(:si_id).paginate(:per_page => 20, :page => params[:page])

        header_ids=[]
        @sales_invoice_headers.each do |header|
          header_ids.push [header.id]
        end
        @sales_invoices = SalesInvoiceDetail.select("EXTRACT(DAY FROM sales_invoice_date) AS date, EXTRACT(MONTH FROM sales_invoice_date) AS date_month, EXTRACT(YEAR FROM sales_invoice_date) AS date_year, product_id, SUM(quantity) AS qty").joins(:sales_invoice_header).where(:sales_invoice_header_id => [header_ids]).group(:product_id, "sales_invoice_headers.sales_invoice_date").order(:date)
        @sales_invoices_distinct = SalesInvoiceDetail.select("DISTINCT(product_id), unit_of_measure_id").where(:sales_invoice_header_id => [header_ids]).order(:product_id)

        # filling header table content
        @header = [] # array one dimention to collect all temp header
        @header << "#{(Date::ABBR_MONTHNAMES[month]).upcase} '" + ("1/#{month}/#{year}").to_date.strftime('%y').to_s
        (day..end_day).each do |i|
          @header << "#{ApplicationController.helpers.get_day_of_week(year, month, i)}
          #{i}"
        end
        @header << "Total"
        @header << "Unit"
        @rows << @header # filling array temp one dimention to array final two dimention
        # end filling header table content

        # filling content
        @sales_invoices_distinct.each do |distinct_item| # looping distinct product
          @content = [] # array one dimention to collect all temp content
          @content << "#{distinct_item.product.try(:name)}"
          total=0
          (day..end_day).each do |j| # looping date
            blank=0
            @sales_invoices.each do |invoice| # looping all data
              if invoice.product_id==distinct_item.product_id && invoice.date.to_i==j && invoice.date_month.to_i==month && invoice.date_year.to_i==year # check for qty place
                blank+=1; @qty=invoice.qty.to_f
              end # check for qty place
            end # looping all data

            if blank!=0 # save the result to the dynamic variables
              @content << @qty
              total+=@qty.to_f
            else
              @content << ""
            end # save the result to the dynamic variables
          end # looping date
          @content << "#{total}"
          @content << distinct_item.unit_of_measure.try(:name)

          @rows << @content # filling array temp one dimention to array final two dimention
        end # looping distinct product
        # end filling content

        instance_variable_set "@month#{i}", @rows # for HTML
        @models.push [@rows] # for PDF n XLS

        if month==ep_month && year==ep_year
          break # get out from looping
        else
          month+=1
        end
      end
    end

    def cross_tab_report_filter
      if params[:start_period].present?
        cross_tab_report_generator
      else
        @months = 1
        @month1 = []
        @sales_invoices = []
        @sales_invoices_distinct = []
      end

      respond_to do |format|
        if params[:print]
          format.html { redirect_to :action => "cross_tab_report", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :warehouse => params[:warehouse] }
        elsif params[:excel]
          format.html { redirect_to :action => "cross_tab_report", :format => "xls", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :warehouse => params[:warehouse] }
        else
          format.html
          format.js
        end
      end
    end

    def cross_tab_report
      if params[:start_period].present? and params[:end_period].present?
        @start_period = params[:start_period].to_date.strftime("%d-%m-%Y")
        @end_period = params[:end_period].to_date.strftime("%d-%m-%Y")
      end

      cross_tab_report_generator

      respond_to do |format|
        format.pdf do
          pdf = CrossTabSalesInvoicePdf.new(@models, view_context, ApplicationController.helpers.get_date_print, ApplicationController.helpers.employee_full_name(current_user.id), @start_period, @end_period, ApplicationController.helpers.company_name)
          send_data pdf.render, filename: "#{I18n.t 'report'}-#{I18n.t 'sales_invoice'} (Cross Tab) #{Time.now.localtime.strftime("%Y-%m-%d %H.%M.%S")}.pdf", 
          type: "application/pdf", disposition: "inline"
        end
        format.csv { send_data @models.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'report'}-#{I18n.t 'sales_invoice'} (Cross Tab) #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
      end
    end

    def cross_tab_report_income_generator
      @start_period = params[:start_period].to_date
      @end_period = params[:end_period].to_date
      day   = @start_period.strftime("%d").to_i
      month = @start_period.strftime("%m").to_i
      year  = @start_period.strftime("%Y").to_i
      ep_day   = @end_period.strftime("%d").to_i
      ep_month = @end_period.strftime("%m").to_i
      ep_year  = @end_period.strftime("%Y").to_i
      @models = [[]] # for PDF and XLS

      # get all month to process
      @months=0
      if ep_year-year>0 # crossing year
        (year..ep_year).each do |i| # looping the crossing years
          if i==year
            start_month = month
            end_month = 12
          elsif i==ep_year
            start_month = 1
            end_month = ep_month
          else
            start_month = 1
            end_month = 12
          end

          if end_month-start_month>0 # crossing month
            (start_month..end_month).each do |i| # looping through months
              @months+=1
            end # looping through months
          elsif end_month-start_month=0 # same month
            @months+=1
          else # end month greater than start month, fail
            can_do=0
          end
        end # looping the crossing years
      elsif ep_year-year==0 # same year
        if ep_month-month>0 # crossing month
          (month..ep_month).each do |i| # looping through months
            @months+=1
          end # looping through months
        elsif ep_month-month==0 # same month
          @months+=1
        else # end month greater than start month, fail
          can_do=0
        end
      else # end year greater than start year, fail
        can_do=0
      end

      (1..@months).each do |i| # need to update those 999
        @rows = [[]]

        if i!=1 # first day gonna be start day
          day=1
        end

        if month==13
          year+=1
          month=1
        end

        if month==ep_month && year==ep_year
          end_day = ep_day
        else
          end_day = "#{year}-#{month}-01".to_date.end_of_month.strftime("%d").to_i
        end


        @sales_invoice_headers = SalesInvoiceHeader.posted.report_period("%02d"%month + "/%02d"%day + "/#{year}", "%02d"%month + "/%02d"%end_day + "/#{year}").order(:si_id)

        header_ids=[]
        @sales_invoice_headers.each do |header|
          header_ids.push [header.id]
        end
        @sales_invoices = SalesInvoiceDetail.search_product(params[:product].to_i)
        .select("EXTRACT(DAY FROM sales_invoice_date) AS date, EXTRACT(MONTH FROM sales_invoice_date) AS date_month, EXTRACT(YEAR FROM sales_invoice_date) AS date_year, warehouse_id, SUM(sales_invoice_details.total_amount) AS amount")
        .joins(:sales_invoice_header)
        .where(:sales_invoice_header_id => [header_ids])
        .group(:warehouse_id, "sales_invoice_headers.sales_invoice_date")
        .order(:date)
        
        # @sales_invoices_distinct = SalesInvoiceDetail.search_product(params[:product].to_i).select("DISTINCT(product_id), unit_of_measure_id").where(:sales_invoice_header_id => [header_ids]).order(:product_id)
        @warehouses = Warehouse.order(:name)

        # filling header table content
        @header = [] # array one dimention to collect all temp header
        @header << "#{(Date::ABBR_MONTHNAMES[month]).upcase} '" + ("1/#{month}/#{year}").to_date.strftime('%y').to_s
        (day..end_day).each do |i|
          @header << "#{ApplicationController.helpers.get_day_of_week(year, month, i)}
          #{i}"
        end
        @header << "Total"
        @rows << @header # filling array temp one dimention to array final two dimention
        # end filling header table content

        # filling content
        @warehouses.each do |warehouse| # looping warehouse
          @content = [] # array one dimention to collect all temp content
          @content << warehouse.name
          total=0
          (day..end_day).each do |j| # looping date
            blank=0
            @sales_invoices.each do |invoice| # looping all data
              if invoice.warehouse_id.to_i==warehouse.id.to_i && invoice.date.to_i==j && invoice.date_month.to_i==month && invoice.date_year.to_i==year # check for amount place
                blank+=1; @amount=invoice.amount.to_f
              end # check for amount place
            end # looping all data

            if blank!=0 # save the result to the dynamic variables
              @content << @amount
              total+=@amount.to_f
            else
              @content << ""
            end # save the result to the dynamic variables
          end # looping date
          @content << "#{total}"

          @rows << @content # filling array temp one dimention to array final two dimention
        end # looping warehouse
        # end filling content

        instance_variable_set "@month#{i}", @rows # for HTML
        @models.push [@rows] # for PDF n XLS

        if month==ep_month && year==ep_year
          break # get out from looping
        else
          month+=1
        end
      end
    end

    def cross_tab_report_income_filter
      if params[:start_period].present?
        cross_tab_report_income_generator
      else
        @months = 1
        @month1 = []
        @sales_invoices = []
        @sales_invoices_distinct = []
        @warehouses = []
      end

      respond_to do |format|
        if params[:print]
          format.html { redirect_to :action => "cross_tab_report_income", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :warehouse => params[:warehouse] }
        elsif params[:excel]
          format.html { redirect_to :action => "cross_tab_report_income", :format => "xls", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :warehouse => params[:warehouse] }
        else
          format.html
          format.js
        end
      end
    end

    def cross_tab_report_income
      if params[:start_period].present? and params[:end_period].present?
        @start_period = params[:start_period].to_date.strftime("%d-%m-%Y")
        @end_period = params[:end_period].to_date.strftime("%d-%m-%Y")
      end
      
      cross_tab_report_income_generator

      respond_to do |format|
        format.pdf do
          pdf = CrossTabSalesInvoiceIncomePdf.new(@models, view_context, ApplicationController.helpers.get_date_print, ApplicationController.helpers.employee_full_name(current_user.id), @start_period, @end_period, ApplicationController.helpers.company_name)
          send_data pdf.render, filename: "#{I18n.t 'report'} #{I18n.t 'gross_sales'} (Cross Tab) #{Time.now.localtime.strftime("%Y-%m-%d %H.%M.%S")}.pdf", 
          type: "application/pdf", disposition: "inline"
        end
        format.csv { send_data @models.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'report'}-#{I18n.t 'gross_sales'} (Cross Tab) #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
      end
    end

    private
      def set_sales_invoice_header
        @sales_invoice_header = SalesInvoiceHeader.find(params[:id])
      end

      def set_tax_type
        if @split_tax_and_non_tax_transaction == 1
          render_form_tax_type_name(params[:tt].to_s)
        end
      end
  end
end