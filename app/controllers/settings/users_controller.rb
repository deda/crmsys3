class Settings::UsersController < ApplicationController

  before_filter :admin_only, :except => [:index, :update]
  before_filter :find_user, :only => [:update, :edit, :destroy]

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def new
    @user = User.for_account.new
    @page = :users
    before_render
  end

  #-----------------------------------------------------------------------------
  def create
    avatar = avatar_from_params
    @user = User.for_account.new(params[:user])
    @user.email_confirmed = true
    if (ids = params[:user_group_ids]) and (user_groups = UserGroup.for_account.find(ids))
      @user.user_groups = user_groups
    end
    @user.avatar = avatar
    responds_to_parent do
      if @user.save
        @user.settings.locale = @user.account.settings.locale
        @user.settings.save
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
    if current_user.is_admin? || current_user == @user
      avatar = avatar_from_params
      @user.name = params[:user][:name]
      if current_user.is_admin?
        @user.is_admin = params[:user][:is_admin] == '1' unless current_user == @user
        if (ids = params[:user_group_ids]) and (user_groups = UserGroup.for_account.find(ids))
          @user.user_groups = user_groups
        else
          @user.user_groups.clear
        end
      end
      @user.avatar = avatar if avatar
      responds_to_parent do
        if @user.save
          pass = params[:user][:password]
          pass_conf = params[:user][:password_confirmation]
          @user.update_password(pass, pass_conf) unless pass.blank?
          before_render
          render :action => :update
        else
          render :action => :new
        end
      end
    else
      redirect_to root_path
    end
  end

  #-----------------------------------------------------------------------------
  def destroy
    @user.destroy if @user.can_be_deleted
    before_render
    render :action => :destroy
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    User.for_account.find(params[:ids]).each { |user|
      user.destroy if user.can_be_deleted
    }
    before_render
    render :action => :destroy
  end


private

  #-----------------------------------------------------------------------------
  def find_user
    @user = User.for_account.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  def before_render
    @user ||= current_user
    @users = User.for_account.find(:all)
    @user_groups = UserGroup.for_account.find(:all)
  end

end

