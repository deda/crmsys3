class WareItemsController < ApplicationController
  
  def show
    @ware_item = WareItem.find params[:id]
    respond_to do |type|
      type.html
      type.js {render :json => @ware_item}
    end
  end

  def update
    @ware_item = WareItem.find params[:id]
    @ware_item.update_attributes!(params[:ware_item])
    redirect_to @ware_item, :status => :see_other
  end

end
