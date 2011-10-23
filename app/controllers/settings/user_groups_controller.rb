class Settings::UserGroupsController < ApplicationController

  before_filter :admin_only
  before_filter :find_group, :only => [:update, :edit, :destroy]

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def new
    @user_group = UserGroup.for_account.new
    before_render
  end

  #-----------------------------------------------------------------------------
  def create
    @user_group = UserGroup.for_account.new(params[:user_group])
    if (ids = params[:user_ids]) and (users = User.for_account.find(ids))
      @user_group.users = users
    end
    responds_to_parent do
      if @user_group.save
        before_render
        render :action => :update
      else
        render :action => :new
      end
    end
  end

  #-----------------------------------------------------------------------------
  def edit
    before_render
    render :action => :new
  end

  #-----------------------------------------------------------------------------
  def update
    responds_to_parent do
      if (ids = params[:user_ids]) and (users = User.for_account.find(ids))
        @user_group.users = users
      else
        @user_group.users.clear
      end
      if @user_group.update_attributes(params[:user_group])
        before_render
        render :action => :update
      else
        before_render
        render :action => :new
      end
    end if @user_group.can_be_edited
  end

  #-----------------------------------------------------------------------------
  def destroy
    @user_group.destroy if @user_group.can_be_deleted
    before_render
    render :action => :destroy
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    UserGroup.for_account.find(params[:ids]).each do |group|
      group.destroy if group.can_be_deleted
    end
    before_render
    render :action => :destroy
  end


private

  #-----------------------------------------------------------------------------
  def find_group
    @user_group = UserGroup.for_account.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  def before_render
    @user_groups = UserGroup.for_account.find(:all)
    @users = User.for_account.find(:all)
  end

end

