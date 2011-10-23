class CasesController < ApplicationController

  before_filter :check_settings
  before_filter :find_case,
    :only => [:update, :destroy, :show, :edit, :sip, :report, :quick_info, :update_inventory, :print]

  #-----------------------------------------------------------------------------
  @@fields_for_search = [
    'tags.name',
    'name',
    'code',
    'sale.formated_name',
    'state.name']

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def show
    before_render
    respond_to do |format|
      format.html {
        render :action => :index
      }
      format.js {
        render :action => :show
      }
    end
  end

  #-----------------------------------------------------------------------------
  def new
    code = Case.for_account.count
    code = "#{Time.now.year}-#{code + 1}"
    @case = Case.for_user.new(:code => code)
    before_render
  end

  #-----------------------------------------------------------------------------
  def edit
    before_render
  end

  #-----------------------------------------------------------------------------
  def create
    process_inventory_items :create
  end

  #-----------------------------------------------------------------------------
  def cancel
    before_render
    render :action => :index
  end

  #-----------------------------------------------------------------------------
  def update
    process_inventory_items :update if @case.can_be_edited
  end

  #-----------------------------------------------------------------------------
  def destroy
    @case.destroy if @case.can_be_deleted
    before_render
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    Case.find(params[:cases_ids]).each { |c|
      c.destroy if c.can_be_deleted
    }
    before_render
    render :action => :destroy
  end

  #-----------------------------------------------------------------------------
  def mass_state
    state = CaseState.for_account.find(params[:oper_id])
    if state
      Case.find(params[:cases_ids]).each { |c|
        c.update_attribute(:state, state) if c.can_be_edited
      }
    end
    before_render
    render :action => :destroy
  end

  #-----------------------------------------------------------------------------
  def sip
    return unless @case.can_be_edited
    begin
      f = @case.send(params[:field_name]).class.for_account.find(params[:field_id])
    rescue
      f = nil
    end
    @case.update_attribute(params[:field_name], f) if f
  end

  #-----------------------------------------------------------------------------
  def report
    @events = []

    # создание дела
    log = CrmLog.for_abject(@case).find_creation
    @events << Report::Event.new(
      log.dati.localtime,
      I18n::t(:record_creation),
      log.user_id) if log

    # поиск всех смен статуса дела
    logs = CrmLog.for_abject(@case).find_field_updates('state_id')
    logs.each do |log|
      state = log.value('state_id')
      state = CaseState.find_with_destroyed(state) if state
      state = state ? state.name : ''
      @events << Report::Event.new(
        log.dati.localtime,
        I18n::t(:state_changed) + ": #{state}",
        log.user_id)
    end

    # поиск всех завершенных задач
    @case.tasks.each do |task|
      if task.completed?
        log = CrmLog.for_abject(task).find_last_field_value('completed', 'true')
        @events << Report::Event.new(
          log.dati.localtime,
          I18n::t(:task_completed) + ": #{task.name}",
          log.user_id,
          task.comments.map{|c| "#{I18n::l(c.updated_at.localtime, :format => :long)}, #{c.user.name}: #{c.text}"}) if log
      end
    end

    # сортировка событий по дате
    @events = @events.sort_by{|e| e.dati}
    render :file => 'cases/report.html'
  end

  #-----------------------------------------------------------------------------
  def quick_info
    as = "#{request.protocol}#{request.host}:#{request.port}/images/"
    ic = QuickInfo::Icon.new("#{as}48x48_case.png")
    @qi = QuickInfo::Info.new(@case.formated_name, @case, ic)
    @qi.lines << QuickInfo::Line.new(@case.description)
    @case.tasks.each do |t|
      @qi.lines << QuickInfo::Line.new("#{t.timestamp}: #{t.name}")
    end
    render :template => 'shared/quick_info'
  end

  #-----------------------------------------------------------------------------
  # сортировка позиций элементов спецификации
  def update_inventory
    items = @case.inventory_items
    params[:"case_#{@case.id}_inventory_items_list"].each_with_index do |v,i|
      if (v=v.to_i) != i
        items[v].update_attribute(:position, i+1)
      end
    end
    # сл. строка нужна для того, чтобы обновился порядок элементов
    # описи при отображении в виде
    @case.inventory_items(true)
    render :action => :update_inventory
  end

  #-----------------------------------------------------------------------------
  # создание печатной формы дела
  def print
    render :file => 'cases/print.html'
  end


private
  
  #-----------------------------------------------------------------------------
  def find_case
    @case = Case.visible_for_user.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  # Можем придти сюда либо из экшенов create||update. Если пришел новый экземп.
  # Case, то сохраняем его, иначе обновляем существующий. До кучи сохраняем теги
  # и вовлеченные контакты. Если все прошло без ошибок, то начинаем обрабатывать
  # запрос на манипуляции с табличной частью (см. process_subaction). Затем либо
  # добавляем новый элемент к табличной части, либо сохраняем изменения.
  #-----------------------------------------------------------------------------
  def process_inventory_items action
    error = false

    case action
      when :create
        @case = Case.for_user.build(params[:case])
        unless @case.save
          error = true
          action = :new
        end
      when :update
        unless @case.update_attributes(params[:case])
          error = true
          action= :edit
        end
      else
        return
    end

    @case.tags     = find_or_build(CaseTag, :tag)
    @case.contacts = find_involved_contacts

    unless error
      if params[:sub_action]
        action = :edit
        process_subaction params[:sub_action]
      end
      save_inventory_item if params[:inventory_item]
    end

    before_render
    smart_render(action)
  end

  #-----------------------------------------------------------------------------
  # Ищем вовлеченные контакты, которые уже существуют в базе. Новые не создаем
  #-----------------------------------------------------------------------------
  def find_involved_contacts
    array  = params[:contact]
    object = []

    array.each_index do |i|
      object[i] = nil
      if ! array[i][:given_name].blank? and not array[i][:id].blank?
        object[i] = Contact.for_account.find(array[i][:id])
      end
    end

    return object.compact
  end

  #-----------------------------------------------------------------------------
  # add - Добавляем новую пустую строку
  # del - Удаляем строку
  # chg - Забираем строку на редактирование
  # uhg - Забываем о внесенных изменениях
  #-----------------------------------------------------------------------------
  def process_subaction action
    id = params[:sub_action_id]
    case action
      when 'add':
        @case.inventory_items << InventoryItem.for_user.new
      when 'del':
        InventoryItem.for_user.destroy(id) if id
      when 'chg':
        @chg_item = id.to_i
      when 'uhg':
        params.delete(:inventory_item)
    end
  end

  #-----------------------------------------------------------------------------
  # Сохраняем строку таблицы
  #-----------------------------------------------------------------------------
  def save_inventory_item
    if (id=params[:inventory_item_id]).blank?
      item = InventoryItem.for_user.build(params[:inventory_item])
      item.owner = @case
      item.save
    else
      InventoryItem.for_user.find(id).update_attributes(params[:inventory_item])
    end
  end

  #-----------------------------------------------------------------------------
  def smart_render action
    if params[:sub_action]
      render :action => action
    # если форма отправлена нажатием кнопки Сохранить
    else
      responds_to_parent do
        render :action => action
      end
    end
  end

  #-----------------------------------------------------------------------------
  # здесь заполняются переменные экземпляра, необходимые для рендеринга ВИДА,
  # дабы максимально исключить программную логику из ВИДА
  def before_render
    # ответственный менеджер, контрагент, статусы дела
    @states_collection = CaseState.for_account.find(:all)
    @recipients_collection = current_user.account.users.map(&:convert)
    @filter_recipients = Case.visible_for_user.find(:all, :group => :recipient_id).map{|c|[c.recipient_id,c.recipient.name]}
    # обработка фильтра
    @cases = nil
    wp = @_search.empty? ? @_paging : nil
    case @_filter[:type]
      when :tags
        @cases = CaseTag.find(@_filter[:id]).owners.visible_for_user.pfind(wp)
      when :states
        @cases = CaseState.find(@_filter[:id]).cases.visible_for_user.pfind(wp)
      when :recent_records
        case @_filter[:id]
          when 0
            @cases = Case.visible_for_user.recently_created.pfind(wp)
          when 1
            @cases = Case.visible_for_user.recently_updated.pfind(wp)
        end
      when :recipient
        @cases = Case.visible_for_user.find(:all, :conditions => {:recipient_id => @_filter[:id]})
    end
    @cases = Case.visible_for_user.pfind(wp) unless @cases
    # обработка поиска
    Search::and_search(@cases, @@fields_for_search, @_search)
    # обработка пагинации
    unless @_search.empty?
      process_paging(@cases)
    end
  end

  #-----------------------------------------------------------------------------
  def check_settings
    redirect_to root_path unless current_user.account.tariff_plan.with_cases
  end

end
