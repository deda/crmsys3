class CommoditiesController < ApplicationController

  def tab
    if signed_in_as_admin?
      @commodities = Commodity.all
    else
      @commodities = current_user.account.commodities
    end
  end

  def index
    @commodities = current_user.account.send params[:class]
    @class_name = params[:class]
  end

  def show
    @commodity = Commodity.find(params[:id])
  end

  def new
    # ересь полная написана
    object_class = class_eval(params[:name].capitalize)
    @commodity = object_class.new
    if @commodity.class == Ware
      1.times do
        @commodity.images.build
      end
    end   
  end

  def create
    unless params[:ware].nil?
      params[:ware][:images_attributes] = params[:new_images] unless params[:new_images].nil?
      @commodity = Ware.new params[:ware]
    else
      @commodity = Service.new params[:service]
    end
    @commodity.account_id = current_user.account.id
    if @commodity.save
      responds_to_parent do
        render :action => :create
      end
    else
      unless params[:ware].nil?
        1.times do
          @commodity.images.build
        end
      end
      responds_to_parent do
        render :action => :new
      end
    end
  end

  def edit
    @commodity = Commodity.find params[:id]
    if @commodity.class == Ware
      unless @commodity.images.any?
        @commodity.images.build
      end
    end
  end

  def update
    @commodity = Commodity.find params[:id]

    if @commodity.class == Ware
      unless params[:ware][:images_attributes].nil?
        params[:ware][:images_attributes] = params[:ware][:images_attributes].map{|key,value| value} + params[:new_images].to_a
      else
        params[:ware][:images_attributes]= params[:new_images].to_a
      end
    end

    if @commodity.class == Ware
      if @commodity.update_attributes params[:ware]
        responds_to_parent do
          render :action => :update
        end
      else
        responds_to_parent do
          render :action => :edit
        end
      end
    else
      if @commodity.update_attributes params[:service]
        responds_to_parent do
          render :action => :update
        end
      else
        responds_to_parent do
          render :action => :edit
        end
      end
    end
  end

  def destroy
    @commodity = Commodity.find(params[:id])
    @commodity.destroy
  end
end
