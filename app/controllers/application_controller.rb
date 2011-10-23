# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include Search
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  helper_method :signed_in_as_admin?
  helper_method :signed_in_as_account_admin?

  before_filter :set_current_user
  before_filter :authenticate
  before_filter :initialize_navi
  before_filter :director_fork
  before_filter :after_login

  # формирование параметров поиска, фильтра, пагинации
  before_filter :process_search
  before_filter :process_filter
  before_filter :process_paging
  before_filter :process_locale


private

  def initialize_navi
    @navi = self.class.name.sub(/::.+Controller/, 'Controller')
  end

  def set_appropriate_accept_header
    if request.headers['X-Requested-With'] == "XMLHttpRequest"
      request.env["HTTP_ACCEPT"] = "text/javascript,text/html,application/xml,text/xml,*/*"
    end
  end

  #-----------------------------------------------------------------------------
  def admin_only
    redirect_to root_path unless current_user.is_admin?
  end

  #-----------------------------------------------------------------------------
  def accounts_admin_only
    redirect_to root_path unless current_user.is_accounts_admin?
  end

  #-----------------------------------------------------------------------------
  # создает объект класса params[:owner_type] и возвращает его (или nil в случае неудачи)
  def find_owner
    if owner_type = params[:owner_type] and owner_id = params[:owner_id]
      model = Object.const_get(owner_type.camelize)
      if owner_id.blank?
        @owner = model.new
      else
        @owner = model.find(owner_id)
      end
    else
      @owner = nil
    end
  end

  #-----------------------------------------------------------------------------
  # Возвращает существующий объект модели или создает новый
  # Пример использования:
  #   @contact.parent = find_or_build(Person, :parent, :given_name)
  # 1. если params[:parent][:id] не пусто, ищем запись в Person с этим id
  # 2. если params[:parent][:id] пусто, ищем запись в Person с given_name = params[:parent][:name]
  # 3. если предыдущие пункты неудачны, создаем запись в Person с given_name = params[:parent][:name]
  # 4. при поиске и создании используются for_account и for_user
  # 5. если params[:parent] - массив, то будет возвращен массив найденных/созданных объектов
  def find_or_build model, item, name_field = :name, array = params
    array  = array[item]
    object = []

    if array.is_a?(Array)
      is_array = true
    else
      array = [array]
      is_array = false
    end

    array.each_index do |i|
      id   = array[i][:id]
      name = array[i][name_field]
      object[i] = nil
      if ! name.blank?
        begin
          if id.blank?
            object[i] = model.for_account.find(:first, :conditions => {name_field => name})
          else
            object[i] = model.for_account.find(id)
          end
        rescue
        end
        if ! object[i]
          object[i] = model.for_user.build(name_field => name)
        end
      end
    end

    return object.compact if is_array
    return object[0]
  end

  #-----------------------------------------------------------------------------
  # Обработка поиска, фильтра, пагинаци, локали
  #-----------------------------------------------------------------------------
  # Строится @_search - массив из строк, которые нужно искать
  def process_search
    if sv = params[:s]
      @_search = sv.uniq
      @_search.delete('')
    else
      @_search = []
    end
  end
  #-----------------------------------------------------------------------------
  # Создает @_filter{:type => ..., :id => ...}
  def process_filter
    @_filter = { :type => nil, :id => nil }
    if f = params[:f]
      f = f.split('!')
      if not f.blank?
        @_filter[:type] = f[0].to_sym
        @_filter[:id] = f[1].to_i
      else
        @_filter[:type] = nil
        @_filter[:id] = nil
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Создает @_paging{:page => ..., :recs => ..., :from => ..., :to => ..., :pages => ...}
  # Если передан array, он будет усечен в соответствии с параметрами пагинации
  def process_paging array=nil

    if array

      as = array.size
      if @_paging[:from] >= as
        @_paging[:page] = 0
        @_paging[:from] = 0
        @_paging[:to] = @_paging[:recs] - 1
      end
      if (r = @_paging[:recs]) != 0
        @_paging[:pages] = as / r + (as % r == 0 ? 0 : 1)
        x = @_paging[:to] + 1
        array.slice!(x..-1) if x < as
        x = @_paging[:from] - 1
        array.slice!(0..x) if x >= 0
      end

    else

      @_paging = session[:paging] || { :page => 0, :recs => 10, :from => 0, :to => 10, :pages => 0 }

      if r = params[:r]
        begin
          r = r.to_i
        rescue
          r = 10
        end
        r = 0 if r < 0
        @_paging[:recs] = r
        @_paging[:page] = 0
        # запомним для данного пользователя смену кол-ва записей на страницу
        current_user.settings.recs_per_page = r
        current_user.settings.save
      else
        r = @_paging[:recs]
      end

      if p = params[:p] and r != 0
        begin
          p = p.to_i
        rescue
          p = 0
        end
        p = 0 if p < 0
        @_paging[:page] = p
      else
        p = 0
        @_paging[:page] = 0
      end

      @_paging[:from] = p * r
      @_paging[:to] = @_paging[:from] + r - 1

    end

    if @_paging[:recs] == 0
      @_paging[:page] = 0
      @_paging[:from] = 0
      @_paging[:pages] = 1
    end

    session[:paging] = @_paging
  end
  #-----------------------------------------------------------------------------
  # смена локали
  def process_locale
    if l = params[:locale]
      l = l.to_sym
      if I18n.available_locales.include?(l)
        session[:locale] = l
        current_user.settings.locale = l
        current_user.settings.save
      end
    end
    I18n.locale = session[:locale]
  end

  #-----------------------------------------------------------------------------
  # в режиме директора могут вызываться только определенные контроллеры.
  # аналогично для нормального режима: не могу вызываться контроллеры,
  # специфичные для режима директора
  def director_fork
    return if not current_user
    controller = params[:controller]
    return if controller == 'clearance/sessions'
    if current_user.account.director?
      redirect_to root_path unless [
        'accounts',
        'settings/users',
        'settings/recent_records',
        'settings/sale_states',
        'settings/case_states',
        'settings/tariff_plans/account_tariff_plans',].include? controller
    else
      redirect_to root_path if [
        'accounts'].include? controller
    end
  end

  #-----------------------------------------------------------------------------
  # При старте сессии и логине применяются настройки пользователя
  def after_login
    unless current_user
      session[:current_user_id] = nil
      return
    end
    if not session[:current_user_id] or session[:current_user_id] != current_user.id
      unless current_user.settings.loaded?(:locale)
        current_user.settings.locale = current_user.account.settings.locale
        current_user.settings.save
      end
      I18n.locale = current_user.settings.locale
      session[:locale] = I18n.locale
      session[:current_user_id] = current_user.id
      rpp = current_user.settings.recs_per_page.to_i
      session[:paging] = { :page => 0, :recs => rpp, :from => 0, :to => rpp, :pages => 0 }
    end
  end

  #-----------------------------------------------------------------------------
  # определение текущего пользователя в глобальной переменной
  def set_current_user
    $current_account = ($current_user = current_user) ? $current_user.account : nil
  end

  #-----------------------------------------------------------------------------
  def avatar_from_params base=:image
    avatar = nil
    if params[base] and p=params[base][:photo]
      avatar = Avatar.new(:photo => p)
      params[base].delete(:photo)
    end
    return avatar
  end

end
