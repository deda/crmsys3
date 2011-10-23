class AttachmendsController < ApplicationController

  before_filter :find_attachmend, :only => :destroy
  before_filter :find_owner

  #-----------------------------------------------------------------------------
  def create
    @attachmend = Attachmend.for_user.new(params[:attachmend])
    @attachmend.owner = @owner
    @attachmend.owner_type = @owner.class.name.camelize
    @attachmend.save
    @uid = params[:uid]
    responds_to_parent do
      render :action => :create
    end
  end

  #-----------------------------------------------------------------------------
  def destroy
    @attachmend.destroy if @attachmend.can_be_deleted
  end


private

  #-----------------------------------------------------------------------------
  def find_attachmend
    @attachmend = Attachmend.for_user.find(params[:id])
  end

end
