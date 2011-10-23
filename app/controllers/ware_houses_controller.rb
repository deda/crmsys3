class WareHousesController < ApplicationController

  before_filter :check_additing_to_ware_item_data, :only => [:update_ware_items]

  def index
    unless current_user.account.nil?
      @ware_houses = current_user.account.ware_houses
      @wares = current_user.account.wares
    end
  end

  def show
    @ware_house = WareHouse.find_by_account_id_and_id current_user.account.id, params[:id]
    @ware_items = @ware_house.ware_items
  end

  def new
    @ware_house = WareHouse.new
  end

  def create
    @ware_house = WareHouse.new params[:ware_house]
    @ware_house.account_id = current_user.account.id
    if @ware_house.save
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
    @ware_house = WareHouse.find_by_account_id_and_id(current_user.account.id, params[:id])
  end

  def update
    @ware_house = WareHouse.find_by_id(params[:id])
    if @ware_house.update_attributes( params[:ware_house])
      responds_to_parent do
        render :action => :update
      end
    else
      responds_to_parent do
        render :action => :edit
      end
    end
  end

  def edit_ware_items
    @ware_house = WareHouse.find_by_id(params[:id])
  end

  def update_ware_items
    #    unless params[:ware_house][:ware_items_attributes].nil?
    #      params[:ware_house][:ware_items_attributes] = params[:ware_house][:ware_items_attributes].map{|key,value| value} + params[:new_ware_items].to_a
    #    else
    #      params[:ware_house][:ware_items_attributes] =  params[:new_ware_items].to_a
    #    end
    @ware_house = WareHouse.find_by_id_and_account_id(params[:id],current_user.account.id)
    instance = params[:add_to_ware_item].first
    @ware_item = WareItem.find_by_ware_id_and_ware_house_id(instance[:ware_id],@ware_house.id)
    unless @ware_item.nil?
      params[:add_to_ware_item].each do |value|
        value['id'] = @ware_item.id
        value['quantity'] = (value['quantity'].to_i + @ware_item.quantity).to_s
        @ware_item.quantity = value['quantity']
      end
      #    else
      #      #TODO проверка принадлежнасти склада текущему пользователю в before_filter и заключить в одну транзацию  вмесет с update_attributes
      #      @ware_item = WareItem.new(:quantity => instance[:quantity], :ware_id => instance[:ware_id], :ware_house_id => params[:id])
    end
    params[:ware_house][:ware_items_attributes] =  params[:add_to_ware_item].to_a
    if @ware_house.update_attributes params[:ware_house]
      if @ware_item.nil?
        @ware_item = WareItem.find_by_ware_id_and_ware_house_id(instance[:ware_id],@ware_house.id)
      end
      responds_to_parent do
        render :action => :update_ware_items
      end
    else
      responds_to_parent do
        render :action => :edit_ware_items
      end

    end
  end

  def destroy
    @ware_house = WareHouse.find_by_id_and_account_id(params[:id],current_user.account.id)
    @ware_house.destroy
  end

  def check_additing_to_ware_item_data
    return true
  end
end

