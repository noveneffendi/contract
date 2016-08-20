require_dependency "contract/application_controller"

module Contract
  class SalesOrderHeadersController < ApplicationController
    # before_filter(:except => [:so_id_by_customer, :add_discount, :add_discount_put, :view_note, :approval_notes]) { |c| c.authorize_access c.controller_name, params[:tt] }
    before_filter :set_sales_order_header, only: [:show, :edit, :update, :status_post, :status_void, :add_discount, :add_discount_put, :show_post_void, :view_note, :approval_notes, :approval_status, :close, :revise]
    before_filter :get_currencies, only: [:new, :edit, :status_post, :status_void, :revise]
    respond_to :js, :only => [:view_note, :so_id_by_customer, :add_discount, :add_discount_put, :approval_notes]
    # GET /sales_order_headers
    # GET /sales_order_headers.json
    def index
      if params[:date].blank?
        @sales_order_headers = SalesOrderHeader.where("date_part('month', sales_order_date)=date_part('month', current_date) and date_part('year', sales_order_date)=date_part('year', current_date)")
      else
        @sales_order_headers = SalesOrderHeader.order("so_id DESC").search_month(params[:date][:month])
                                .search_year(params[:date][:year])
                                .search_amount(params[:start_amount], params[:end_amount])
                                .search_customer(params[:customer].to_i).search_status(params[:status])
                                .search_currency(params[:currency]).search_sales_person(params[:sales].to_i)
                                .search_by_description(params[:d]).search_by_product(params[:p])
      end

      @customers = Customer.all.order(:name)

      @sales = User.sales.order(:first_name)

      @sales_order_headers = @sales_order_headers.where("so_id like ?", "#{SalesOrderHeader::SO_PREFIX_DEFAULT}%").order("so_id DESC").paginate(:per_page => 20, :page => params[:page])
  
      # Check current_user can revise?
      @can_revise = load_additional_resource("/#{controller_name}",1)
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @sales_order_headers }
        format.js
      end
    end
  
    # GET /sales_order_headers/1
    # GET /sales_order_headers/1.json
    def show
      @sales_order_details = @sales_order_header.sales_order_details.order(:created_at)

      @subtotal_amount = @sales_order_header.sales_order_details
                          .select("sum(sales_order_details.amount) as pdetail_amount").last.pdetail_amount.to_f

      if @sales_order_header.tax == TRUE
        @tax_amount = @subtotal_amount * 0.1
      else
        @tax_amount = 0
      end

      if !@sales_order_header.sales_id.blank?
        @sales_full_name = get_sales_full_name(@sales_order_header.try(:sales_id))
      end
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @sales_order_header }
        format.pdf
      end
    end
  
    # GET /sales_order_headers/new
    # GET /sales_order_headers/new.json
    def new
      @sales_order_header = SalesOrderHeader.new(:sales_order_date => Date.today.strftime("%d-%m-%Y"), 
                            :status => 0, :currency_id => @default_currency, :exchrate => @default_rate,
                            :employee_name => current_user.full_name)
      @readonly = false
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @sales_order_header }
      end
    end
  
    # GET /sales_order_headers/1/edit
    def edit
      @sales_order_header.employee_name = current_user.full_name
      @readonly = false
    end

    def revise
      # check can revise role for current_user
      can_revise = load_additional_resource("/#{controller_name}",1)

      if can_revise == false
        raise CanCan::AccessDenied
      end

      if @sales_order_header.status != 5 && @sales_order_header.close == false
        sos = SalesInvoiceHeader.with_so_id(@sales_order_header.so_id).not_void
        if sos.blank?
          @sales_order_header.update_attributes(:status => 0)
          @sales_order_header.revision_status = 1

          # format create_log(subject, object, detail, employee_name)
          create_log("Revision", "Sales Order", "Revision header with id:#{@sales_order_header.so_id}, customer:#{@sales_order_header.customer.try(:name)}, CP:#{@sales_order_header.contact_person}, amount:#{@sales_order_header.amount}, disc(%):#{@sales_order_header.discount}, disc(Rp):#{@sales_order_header.discount_amount}, tax:#{@sales_order_header.tax}, tax amount:#{@sales_order_header.tax_amount}, total:#{@sales_order_header.total_amount}, notes:#{@sales_order_header.notes}", current_user.full_name)

          # revision_process(@sales_order_header.id)
        else
          respond_to do |format|
            format.html { redirect_to sales_order_headers_path(params.except(:action, :controller)), notice: "#{t 'so.revision_fail'}, #{t 'so.void_fail2'}".html_safe }   
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to sales_order_header_path(@sales_order_header.id, params.except(:action, :controller)), notice: "#{t 'transaction_void'}" }
        end
      end
    end
  
    # POST /sales_order_headers
    # POST /sales_order_headers.json
    def create
      @sales_order_header = SalesOrderHeader.new(params[:sales_order_header])
      @sales_order_header.so_id = SalesOrderHeader.so_header_id(params[:sales_order_header][:sales_order_date].to_date)
      @sales_order_header.amount = 0
      @sales_order_header.discount = 0
      @sales_order_header.discount_amount = 0
      @sales_order_header.tax = false
      @sales_order_header.tax_amount = @sales_order_header.amount * 0.1
      @sales_order_header.total_amount = 0
      @sales_order_header.status = 0
      @sales_order_header.close = false
      @sales_order_header.save
  
      # format create_log(subject, object, detail, employee_name)
      create_log("Create Header", "Sales Order", "Create new header with id:#{@sales_order_header.so_id}, customer:#{@sales_order_header.customer.try(:name)}, CP:#{@sales_order_header.contact_person}, notes:#{@sales_order_header.notes}.", current_user.full_name)

      respond_to do |format|
        format.html { redirect_to @sales_order_header, notice: "#{I18n.t 'sales_order'} #{I18n.t 'created'}" }
        format.json { render json: @sales_order_header, status: :created, location: @sales_order_header }
      end
    end
  
    # PUT /sales_order_headers/1
    # PUT /sales_order_headers/1.json
    def update
      # Get previous data for log
      customer_id = @sales_order_header.customer_id
      customer=@sales_order_header.customer.try(:name)
      notes=@sales_order_header.notes
      amount=@sales_order_header.amount
      discount=@sales_order_header.discount
      discount_amount=@sales_order_header.discount_amount
      tax=@sales_order_header.tax
      tax_amount=@sales_order_header.tax_amount
      total_amount=@sales_order_header.total_amount
      notes=@sales_order_header.notes
      @sales_order_header.update_attributes(params[:sales_order_header])
  
      respond_to do |format|
        month_prefix = @sales_order_header.so_id[5,2].to_i

        if month_prefix == params[:sales_order_header][:sales_order_date].to_date.strftime("%m").to_i
          if @sales_order_header.update_attributes(params[:sales_order_header])
            # Delete all the details cause update relational data
            if customer_id != params[:sales_order_header][:customer_id]
              sales_order_details = @sales_order_header.sales_order_details.order(:id)
              sales_order_details.each do |sod|
                sod.destroy
              end
            end

            # format create_log(subject, object, detail, employee_name)
            create_log("Update Header", "Sales Order", "Update header with id:#{@sales_order_header.so_id}, customer from:#{customer} to:#{@sales_order_header.customer.try(:name)}, amount from:#{amount} to:#{@sales_order_header.amount}, disc(%) from:#{discount} to:#{@sales_order_header.discount}, disc(Rp) from:#{discount_amount} to:#{@sales_order_header.discount_amount}, tax from:#{tax} to:#{@sales_order_header.tax}, tax amount from:#{tax_amount} to:#{@sales_order_header.tax_amount}, total from:#{total_amount} to:#{@sales_order_header.total_amount}, notes from:#{notes} to:#{@sales_order_header.notes}", current_user.full_name)

            format.html { redirect_to @sales_order_header, notice: "#{I18n.t 'sales_order'} #{I18n.t 'updated'}" }
            format.json { head :no_content }
          else
            format.html { render action: "edit" }
            format.json { render json: @sales_order_header.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to sales_order_header_path(@sales_order_header.id), notice: "#{t 'warning.different_date_with_id'}" }
        end
      end
    end
  
    def close
      @sales_order_header.update_attributes(:status => CLOSE_ORDER_STATUS)
    
      redirect_to sales_order_headers_path(:tt => params[:tt].to_s)
    end

    def add_discount
      @tax_status = get_tax_status(@tax_type)
    end

    def add_discount_put
      # Get previous data for log
      discount_old=@sales_order_header.discount.to_f if @sales_order_header.discount.present?
      discount_amount_old=@sales_order_header.discount_amount.to_f if @sales_order_header.discount_amount.present?
      cash_disc_old=@sales_order_header.cash_disc.to_f if @sales_order_header.cash_disc.present?
      tax_old=@sales_order_header.tax if @sales_order_header.tax.present?
      tax_amount_old=@sales_order_header.tax_amount.to_f if @sales_order_header.tax_amount.present?
      total_amount_old=@sales_order_header.total_amount.to_f if @sales_order_header.total_amount.present?

      # promo disc
      discount = params[:sales_order_header][:discount].to_f
      discount_amount = params[:sales_order_header][:discount_amount].to_f

      # cash disc
      cash_discount = params[:sales_order_header][:cash_disc].to_f

      amount_before_cash_disc = @sales_order_header.amount.to_f - ((discount.to_f/100)*@sales_order_header.amount.to_f) - discount_amount.to_f
      amount_before_tax = amount_before_cash_disc.to_f - (amount_before_cash_disc.to_f*(cash_discount.to_f/100))
      
      # if params[:sales_order_header][:tax].to_i == 0
      tax = params[:sales_order_header][:tax]

      # if tax=='1'
      if tax == TRUE || tax == "true"
        tax_amount = amount_before_tax * 0.1
      else
        tax_amount = 0
      end

      total_amount = amount_before_tax + tax_amount.to_f

      @sales_order_header.update_attributes(:discount => discount, :discount_amount => discount_amount, 
        :cash_disc => cash_discount, :tax => tax, :tax_amount => tax_amount, :total_amount => total_amount)

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Header", "Sales Order", "Update header with id:#{@sales_order_header.so_id}, amount:#{@sales_order_header.amount}, disc(%) from:#{discount_old} to:#{@sales_order_header.discount}, disc(Rp) from:#{discount_amount_old} to:#{@sales_order_header.discount_amount}, tax from:#{tax_old} to:#{@sales_order_header.tax}, tax amount from:#{tax_amount_old} to:#{@sales_order_header.tax_amount}, total from:#{total_amount_old} to:#{@sales_order_header.total_amount}.", current_user.full_name)
    end

    def status_post
      # CHECK CUSTOMER LIMIT BUDGETING
      customer = Customer.find(@sales_order_header.customer_id)
      if customer.present? # check if customer present
        # format current_receivable_by_customer(customer_id, amount)
        ar_balance = current_receivable_by_customer(customer.id, 0)
        if customer.budget.to_f > ar_balance.to_f # check if over budget limit
          # PROCESS IF ACCEPTED
          @sales_order_header.update_attributes(:status => 1)

          # format create_log(subject, object, detail, employee_name)
          create_log("Post", "Sales Order", "Post header with id:#{@sales_order_header.so_id}, customer:#{@sales_order_header.customer.try(:name)}, CP:#{@sales_order_header.contact_person}, amount:#{@sales_order_header.amount}, disc(%):#{@sales_order_header.discount}, disc(Rp):#{@sales_order_header.discount_amount}, tax:#{@sales_order_header.tax}, tax amount:#{@sales_order_header.tax_amount}, total:#{@sales_order_header.total_amount}, notes:#{@sales_order_header.notes}", current_user.full_name)

          redirect_to sales_order_headers_path
          # END PROCESS IF ACCEPTED
        else # process if not accepted, throw notification and freeze transaction
          # PROCESS IF NOT ACCEPTED
          @sales_order_header.update_attributes(:status => 4) # freeze transaction
          @approval_user = User.find(ApprovalPerson.last.try(:user_id))

          # format create_log(subject, object, detail, employee_name)
          create_log("Need Approval", "Sales Order", "Need approval for header with id:#{@sales_order_header.so_id}, customer:#{@sales_order_header.customer.try(:name)}, CP:#{@sales_order_header.contact_person}, amount:#{@sales_order_header.amount}, disc(%):#{@sales_order_header.discount}, disc(Rp):#{@sales_order_header.discount_amount}, tax:#{@sales_order_header.tax}, tax amount:#{@sales_order_header.tax_amount}, total:#{@sales_order_header.total_amount}, notes:#{@sales_order_header.notes}", current_user.full_name)

          respond_to do |format|
            # format notification_email(so_id, requester_full_name, requester_email, approval_user, url)
            UserMailer.notification_email(@sales_order_header.so_id, current_user.full_name, current_user.email, @approval_user, show_post_void_sales_order_header_path(@sales_order_header)).deliver

            format.html { redirect_to show_post_void_sales_order_header_path(@sales_order_header.id) }
            flash[:alert] = "#{I18n.t 'so.over_limit'}"
          end
          # END PROCESS IF NOT ACCEPTED
        end # check if over budget limit
      else
        redirect_to @sales_order_header
      end # check if customer present
      # END CHECK CUSTOMER LIMIT BUDGETING
    end

    def status_void
      # @sales_order_header = SalesOrderHeader.find(params[:id])
      @sales_order_header.update_attributes(:status => 5)

      # format create_log(subject, object, detail, employee_name)
      create_log("Void", "Sales Order", "Void header with id:#{@sales_order_header.so_id}, customer:#{@sales_order_header.customer.try(:name)}, CP:#{@sales_order_header.contact_person}, amount:#{@sales_order_header.amount}, disc(%):#{@sales_order_header.discount}, disc(Rp):#{@sales_order_header.discount_amount}, tax:#{@sales_order_header.tax}, tax amount:#{@sales_order_header.tax_amount}, total:#{@sales_order_header.total_amount}, notes:#{@sales_order_header.notes}", current_user.full_name)

      if @split_tax_and_non_tax_transaction == 1
        redirect_to sales_order_headers_path(:tt => @tax_type)
      else
        redirect_to sales_order_headers_path
      end
    end

    def approval_notes
      @status = params[:status]
    end

    def approval_status
      # @sales_order_header = SalesOrderHeader.find(params[:id])
      if params[:status]=='1'
        @sales_order_header.update_attributes(:approval_notes => params[:sales_order_header][:approval_notes], :status => 1)

        # format create_log(subject, object, detail, employee_name)
        create_log("Approval Post", "Sales Order", "Approval post #{@sales_order_header.so_id} with approval notes:#{@sales_order_header.approval_notes}", current_user.full_name)
      else
        @sales_order_header.update_attributes(:approval_notes => params[:sales_order_header][:approval_notes], :status => 5)

        # format create_log(subject, object, detail, employee_name)
        create_log("Approval Void", "Sales Order", "Approval void #{@sales_order_header.so_id} with approval notes:#{@sales_order_header.approval_notes}", current_user.full_name)
      end

      respond_to do |format|
        if @split_tax_and_non_tax_transaction == 1
          redirect_to sales_order_headers_path(:tt => @tax_type)
        else
          format.html { redirect_to sales_order_headers_path }
        end
      end
    end

    def show_post_void
      @sales_order_details = @sales_order_header.sales_order_details.order("sales_order_details.created_at")

      @subtotal_amount = @sales_order_header.sales_order_details.select("sum(sales_order_details.amount) as sdetail_amount").last.sdetail_amount.to_f

      # if @tax_type.to_s == 'l' || @sales_order_header.tax == TRUE
      if @sales_order_header.tax == TRUE
        @tax_amount = @subtotal_amount * 0.1
      else
        @tax_amount = 0
      end

      @discount_amount = @subtotal_amount.to_f * (@sales_order_header.discount.to_f/100)
      @total_amount = @subtotal_amount.to_f - @discount_amount.to_f + @sales_order_header.tax_amount.to_f
      @status_help = 1

      prawnto :prawn => {:top_margin => 35}, :filename => "#{I18n.t 'print'}-#{I18n.t 'sales_order'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true

      respond_to do |format|
        format.html
        format.pdf
      end
    end

    def so_id_by_customer
      if params[:id].present?
        # @so_ids = SalesOrderHeader.posted.so_has_not_invoiced.where("sales_order_headers.customer_id = ?", "#{params[:id]}").order("so_id ASC")
        prefix = SO_PREFIX_DEFAULT

        @so_ids = SalesOrderHeader
        .posted.so_has_outstanding_qty.not_close
        .where("sales_order_headers.customer_id = ?", "#{params[:id]}")
        .where("sales_order_headers.so_id like ?", "#{prefix}%").uniq
        .order(:so_id).reverse_order

        customer = Customer.find(params[:id])

        @cust_delivery_address = customer.try(:delivery_address)
        @payment_limit = customer.try(:payment_limit_period)
        @sales_id = customer.try(:sales_id)
      else
        @so_ids = []
        @cust_delivery_address = nil
        @payment_limit = 1
        @sales_id = nil
      end
    end

    def report_generator(tt=nil)
      @sales_order_headers = SalesOrderHeader.posted
                              .report_period(params[:start_period].to_date, params[:end_period].to_date)
                              .search_amount(params[:start_amount], params[:end_amount])
                              .search_customer(params[:customer].to_i)

      @sales_order_headers = @sales_order_headers.order(:so_id)

      header_ids=[]
      @sales_order_headers.each do |header|
        header_ids.push [header.id]
      end
      @sales_order_details = SalesOrderDetail.where(:sales_order_header_id => [header_ids])

      @sales_orders = []
      @total_rows = 0
      total = 0
      header_row = 0
      @sales_order_headers.each do |header|
        header_row+=1
        if header.tax==true
          tax="10%"
        else
          tax=""
        end
        @sales_orders.push [header_row, 
          header.so_id, 
          date_without_localtime(header.sales_order_date), 
          header.customer.try(:name), 
          delimiter(header.amount), 
          delimiter(header.discount), 
          delimiter(header.discount_amount), 
          tax, 
          "", 
          delimiter(header.total_amount), 
          header.id]

        @total_rows+=1
        total+=header.total_amount
        @sales_order_details.each do |detail|
          if detail.sales_order_header_id==header.id
            qty = "#{detail.quantity} #{detail.unit_of_measure.try(:name)}"
            @sales_orders.push ["", detail.product.try(:name), qty, "(price:)", delimiter(detail.price), delimiter(detail.discount_item), delimiter(detail.discount_item_price), "", delimiter(detail.amount), "", ""]
            @total_rows+=1
          end
        end
      end
      @sales_orders.push ["", "", "", "", "", "", "", "", "#{(t 'total').upcase}", delimiter(total), ""]
      @total_rows+=1
    end

    def report_filter
    if params[:start_period].present?
      report_generator
      @can_print = load_additional_resource('/'"#{controller_name}",0)
    else
      @sales_orders = []
      @can_print = false
    end

    respond_to do |format|
      if params[:print]
        if params[:tt].present?
          format.html { redirect_to :action => "report", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount], :tt => params[:tt].to_s }
        else
          format.html { redirect_to :action => "report", :format => "pdf", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount] }
        end
      elsif params[:excel]
        if params[:tt].present?
          format.html { redirect_to :action => "report", :format => "xls", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount], :tt => params[:tt].to_s }
        else
          format.html { redirect_to :action => "report", :format => "xls", :start_period => params[:start_period].to_date, :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount] }
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

      prawnto :prawn => {:top_margin => 35}, :filename => "#{I18n.t 'report'}-#{I18n.t 'sales_order'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true

      respond_to do |format|
        format.pdf { render :layout => false }
        format.csv { send_data @sales_orders.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'report'}-#{I18n.t 'sales_order'} #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
      end
    end

    def unfinish_report_generator
      @sales_order_headers = SalesOrderHeader.posted.so_has_outstanding_qty
      .report_period(params[:start_period], params[:end_period])
      .search_amount(params[:start_amount], params[:end_amount])
      .search_customer(params[:customer].to_i)
      .order(:so_id)

      header_ids=[]
      @sales_order_headers.each do |header|
        header_ids.push [header.id]
      end
      @sales_order_details = SalesOrderDetail.where(:sales_order_header_id => [header_ids])

      @sales_orders = []
      @total_rows = 0
      total = 0
      header_row = 0
      @sales_order_headers.each do |header|
        header_row+=1
        if header.tax==true
          tax="10%"
        else
          tax=""
        end
        @sales_orders.push [header_row, 
          header.so_id, 
          date_without_localtime(header.sales_order_date), 
          header.customer.try(:name), 
          delimiter(header.amount), 
          delimiter(header.discount), 
          delimiter(header.discount_amount), 
          tax, 
          "", 
          delimiter(header.total_amount), 
          header.id]

        @total_rows+=1
        total+=header.total_amount
        @sales_order_details.each do |detail|
          if detail.sales_order_header_id==header.id
            qty = "#{detail.quantity} #{detail.unit_of_measure.try(:name)}"
            @sales_orders.push ["", detail.product.try(:name), qty, "(price:)", delimiter(detail.price), delimiter(detail.discount_item), delimiter(detail.discount_item_price), "", delimiter(detail.amount), "", ""]
            @total_rows+=1
          end
        end
      end
      @sales_orders.push ["", "", "", "", "", "", "", "", "#{(t 'total').upcase}", delimiter(total), ""]
      @total_rows+=1
    end

    def unfinish_report_filter
      if params[:start_period].present?
        unfinish_report_generator
      else
        @sales_orders = []
      end

      respond_to do |format|
        if params[:print]
          format.html { redirect_to :action => "unfinish_report", :format => "pdf", :start_period => params[:start_period], :end_period => params[:end_period], :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount] }
        elsif params[:excel]
          format.html { redirect_to :action => "unfinish_report", :format => "xls", :start_period => params[:start_period], :end_period => params[:end_period], :customer => params[:customer], :start_amount => params[:start_amount], :end_amount => params[:end_amount] }
        else
          format.html
          format.js
        end
      end
    end

    def unfinish_report
      unfinish_report_generator

      @start_period = params[:start_period]
      @end_period = params[:end_period]
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

      prawnto :prawn => {:top_margin => 35}, :filename => "#{I18n.t 'report'}-#{I18n.t 'sales_order'} yang Belum Selesai #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.pdf", :inline => true

      respond_to do |format|
        format.pdf { render :layout => false }
        format.csv { send_data @sales_orders.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'report'}-#{I18n.t 'sales_order'} yang Belum Selesai #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
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

        # .report_period("%02d"%month + "/%02d"%day + "/#{year}", "%02d"%month + "/%02d"%end_day + "/#{year}")
        @sales_order_headers = SalesOrderHeader.posted
        .report_period(params[:start_period].to_date, params[:end_period].to_date).order(:so_id).paginate(:per_page => 20, :page => params[:page])

        header_ids=[]
        @sales_order_headers.each do |header|
          header_ids.push [header.id]
        end
        @sales_orders = SalesOrderDetail.select("EXTRACT(DAY FROM sales_order_date) AS date, EXTRACT(MONTH FROM sales_order_date) AS date_month, EXTRACT(YEAR FROM sales_order_date) AS date_year, product_id, SUM(quantity) AS qty").joins(:sales_order_header).where(:sales_order_header_id => [header_ids]).group(:product_id, "sales_order_headers.sales_order_date").order(:date)
        @sales_orders_distinct = SalesOrderDetail.select("DISTINCT(product_id), unit_of_measure_id").where(:sales_order_header_id => [header_ids]).order(:product_id)

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
        @sales_orders_distinct.each do |distinct_item| # looping distinct product
          @content = [] # array one dimention to collect all temp content
          @content << "#{distinct_item.product.try(:name)}"
          total=0
          (day..end_day).each do |j| # looping date
            blank=0
            @sales_orders.each do |order| # looping all data
              if order.product_id==distinct_item.product_id && order.date.to_i==j && order.date_month.to_i==month && order.date_year.to_i==year # check for qty place
                blank+=1; @qty=order.qty.to_f
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
        @sales_orders = []
        @sales_orders_distinct = []
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
          pdf = CrossTabSalesOrderPdf.new(@models, view_context, ApplicationController.helpers.get_date_print, ApplicationController.helpers.employee_full_name(current_user.id), @start_period, @end_period, ApplicationController.helpers.company_name)
          send_data pdf.render, filename: "#{I18n.t 'report'}-#{I18n.t 'sales_order'} (Cross Tab) #{Time.now.localtime.strftime("%Y-%m-%d %H.%M.%S")}.pdf", 
          type: "application/pdf", disposition: "inline"
        end
        format.csv { send_data @models.to_csv }
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{I18n.t 'report'}-#{I18n.t 'sales_order'} (Cross Tab) #{Time.now.strftime("%Y-%m-%d %H.%M.%S")}.xls" }
      end
    end

    private
    def set_sales_order_header
      @sales_order_header = SalesOrderHeader.find(params[:id])
    end
  end
end
