class AccountsController < ApplicationController

  before_filter :accounts_admin_only, :except => [:index, :show]
  before_filter :find_account, :only => [:show, :edit, :update, :destroy]

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def new
    @account = Account.new(:end_time => Time.now + 1.month)
    @account.admins[0] = User.new
  end

  #-----------------------------------------------------------------------------
  def create
    settings = params[:account][:settings]
    params[:account].delete(:settings)
    @account = Account.new(params[:account])
    @account.admins[0].email_confirmed = true
    @account.admins[0].is_admin = true
    responds_to_parent do
      if @account.save
        # копируем записи директора во вновь созданный аккаунт
        # установка локали нужна для локализации при копировании
        save_locale = I18n.locale
        I18n.locale = settings[:locale]
        clone_items(:types)
        clone_items(:measures)
        I18n.locale = save_locale
        # настройки по умолчанию
        @account.settings.locale = settings[:locale]
        @account.settings.save
        @account.admins[0].settings.locale = settings[:locale]
        @account.admins[0].settings.save
        # рендер
        before_render
        render :action => :create
      else
        render :action => :new
      end
    end
  end

  #-----------------------------------------------------------------------------
  def update
    settings = params[:account][:settings]
    params[:account].delete(:settings)
    responds_to_parent do
      if @account.update_attributes(params[:account])
        @account.settings.locale = settings[:locale]
        @account.settings.save
        before_render
        render :action => :update
      else
        render :action => :edit
      end
    end
  end

  #-----------------------------------------------------------------------------
  def destroy
    @account.destroy
    before_render
  end


private

  #-----------------------------------------------------------------------------
  def find_account
    @account = Account.find(params[:id])
    @statistic = params[:statistic] ? @account.statistic : nil
  end

  #-----------------------------------------------------------------------------
  def before_render
    @accounts = Account.find(:all)
  end

  #-----------------------------------------------------------------------------
  def clone_items items
    clone_items = []
    current_user.account.send(items).each do |item|
      clone = item.clone
      clone.user_id = @account.admins[0].id
      clone.created_at = nil
      clone.updated_at = nil
      # теперь проходим по всем строковым полям клона и, если значение поля
      # начинается с 't(:', то выполняем локализацию
      clone.attributes.each_key do |k|
        v = clone.attributes[k]
        if v.is_a?(String) and v.match(/^t\(:([a-z_]+)\)$/i)
          begin
            clone.send(:"#{k}=", I18n::t($1))
          rescue
          end
        end
      end
      clone_items << clone
    end
    @account.send(:"#{items}=", clone_items)
  end

end
