class PurchasesController < ApplicationController

  before_filter :find_sale,
    :only => [:show, :edit, :update, :destroy, :edit_sale_items, :update_sale_items]

  def index
    @sales = Sale.purchases.for_user
    @sale = @sales.build
  end

  def show
    @sale_items = @sale.sale_items
    sales_in_list = @sale_items.map{|s| s.ware_id}
    sales_in_list = 0 if sales_in_list.blank?

    if Ware.for_account.for_select(sales_in_list).blank?
      @hide_add_button = true
    else
      @hide_add_button = false
    end
  end

  def new
    @sale = Sale.purchases.for_user.build
  end

  def create
    @sale = Sale.purchases.for_user.build params[:sale]
    if @sale.save
      responds_to_parent do
        render :action => :create
      end
    else
      responds_to_parent do
        render :action => :new
      end
    end
  end

  def edit
  end

  def update
    if @sale.update_attributes(params[:sale])
      responds_to_parent do
        render :action => :update
      end
    else
      responds_to_parent do
        render :action => :edit
      end
    end
  end

  def edit_sale_items
    @sale_items = @sale.sale_items
    @sales_in_list = @sale_items.map{|s| s.ware_id}
    @sales_in_list = 0 if @sales_in_list.blank?
  end

  def update_sale_items
    instance = params[:add_to_sale_item].first
    @sale_item = SaleItem.find_by_ware_id_and_sale_id(instance[:ware_id],@sale.id)
    unless @sale_item.nil?
      params[:add_to_sale_item].each do |value|
        value['id'] = @sale_item.id
        value['quantity'] = (value['quantity'].to_i + @sale_item.quantity).to_s
        @sale_item.quantity = value['quantity']
      end
      #    else
      #      #TODO проверка принадлежнасти склада текущему пользователю в before_filter и заключить в одну транзацию  вмесет с update_attributes
      #      @ware_item = WareItem.new(:quantity => instance[:quantity], :ware_id => instance[:ware_id], :ware_house_id => params[:id])
    end
    params[:sale][:sale_items_attributes] =  params[:add_to_sale_item].to_a
    if @sale.update_attributes params[:sale]
      if @sale_item.nil?
        @sale_item = SaleItem.find_by_ware_id_and_sale_id(instance[:ware_id],@sale.id)
      end
      responds_to_parent do
        render :action => :update_sale_items
      end
    else
      responds_to_parent do
        render :action => :edit_sale_items
      end
    end
  end

  def destroy
    @sale.destroy
  end

  def find_sale
    @sale = Sale.purchases.for_user.find(params[:id])
  end
end
