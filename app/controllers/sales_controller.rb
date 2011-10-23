class SalesController < ApplicationController

  before_filter :set_appropriate_accept_header,
    :only => :show
  before_filter :find_sale,
    :only => [:update, :destroy, :cancel, :show, :edit, :sip, :quick_info]
  before_filter :set_time_for_canceling,
    :only => [:create, :edit]

  #-----------------------------------------------------------------------------
  @@fields_for_search = [
    'tags.name',
    'name',
    'price_total',
    'description',
    'contact.formated_name',
    'state.name']

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def new
    @sale = Sale.sales.for_user.build(
      :recipient_id => current_user.id)
    before_render
  end

  #-----------------------------------------------------------------------------
  def create
    action = :create
    session[:basic_action] = :new
    @sale = Sale.sales.for_user.build(params[:sale])
    @sale.tags = find_or_build(SaleTag, :tag)
    if @sale.save
      if params[:sub_action_id]
        new_item
        action = :new
      end
    else
      action = :new
    end
    before_render
    smart_render(action)
  end

  #-----------------------------------------------------------------------------
  # из-за нашей специфики создания спецификации, в этот метод можем попадать из
  # двух разных мест: или после create или после edit. откуда именно -
  # запоминается в session[:basic_action]
  # params[:sub_action] - ну ваще не рельсовый подход... но посмотрите как это
  # замечательно удобно работает. в общем эта переменная содержит то действие,
  # которое мы хотим на самом деле выполнить: либо запросили товар для
  # добавления новой позиции спецификации, либо удаялем позицию спецификации,
  # либо хотим редактировать позицию спецификации и т.д. сохранение новой
  # (запрошенной ранее) позиции спецификации и сохранение полей сделки - это
  # как-бы побочные действия при выполнении sub_action
  # возможно в будущем можно будет как-то сделать правильно, не меняя логики
  # представления
  def update
    basic_action = session[:basic_action]
    sub_action = params[:sub_action] || nil
    action = :update
    error = false
    # если есть заполненная новая строка спецификации, сохраним ее
    if params[:sale][:new_item]
      if create_item
        @new_item = nil
      else
        error = true
        action = basic_action
      end
      params[:sale].delete(:new_item)
    end
    # если есть отредактированная строка спецификации, сохраним ее
    if params[:sale][:chg_item]
      # если следующим шагом будет удаление или отмена редактирования
      # этой позиции, то сохранять ее не будем
      unless sub_action == 'uch_item' or (sub_action == 'del_item' and params[:sub_action_id] == params[:chg_item_id])
        if update_item
          @chg_item = nil
        else
          error = true
          action = basic_action
        end
      end
      params[:sale].delete(:chg_item)
    end
    if sub_action and error == false
      action = basic_action
      case sub_action
        when 'new_item':
            new_item
        when 'del_item':
            del_item
        when 'chg_item':
          @chg_item = SaleItem.find(params[:sub_action_id])
        when 'uhg_item':
            ;
      end
      action = basic_action
    end
    @sale.tags = find_or_build(SaleTag, :tag, :name)
    if ! @sale.update_attributes(params[:sale])
      action = basic_action
    end
    before_render
    smart_render(action)
  end

  #-----------------------------------------------------------------------------
  def destroy
    try_destroy @sale
    render_after_destroy
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    Sale.sales.find(params[:sales_ids]).each{ |sale| try_destroy sale }
    render_after_destroy
  end

  #-----------------------------------------------------------------------------
  def mass_state
    state = SaleState.for_account.find(params[:oper_id])
    if state
      Sale.sales.find(params[:sales_ids]).each { |sale|
        sale.update_attribute(:state, state) if sale.can_be_edited
      }
    end
    before_render
    render :action => :destroy
  end

  #-----------------------------------------------------------------------------
  def cancel
    if @sale.created_at.to_i >= session[:operation_start_time].to_i
      @sale.destroy
    else
      @sale.sale_items.each { |sale_item|
        if sale_item.created_at.to_i >= session[:operation_start_time].to_i
          sale_item.destroy
        end
      }
    end
    before_render
    render :action => :destroy
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
  def edit
    session[:basic_action] = :edit
    before_render
  end

  #-----------------------------------------------------------------------------
  # select in place
  def sip
    return unless @sale.can_be_edited
    begin
      f = @sale.send(params[:field_name]).class.for_account.find(params[:field_id])
    rescue
      f = nil
    end
    @sale.update_attribute(params[:field_name], f) if f
  end

  #-----------------------------------------------------------------------------
  def quick_info
    as = "#{request.protocol}#{request.host}:#{request.port}/images/"
    ic = QuickInfo::Icon.new("#{as}48x48_sale.png")
    @qi = QuickInfo::Info.new(@sale.formated_name, @sale, ic)
    @qi.lines << QuickInfo::Line.new(@sale.description)
    @sale.tasks.each do |t|
      @qi.lines << QuickInfo::Line.new("#{t.timestamp}: #{t.name}")
    end
    render :template => 'shared/quick_info'
  end


private

  #-----------------------------------------------------------------------------
  def new_item
    # вновь запрошенный товар для продажи
    @ware = Ware.find(params[:sub_action_id])
    # создание новой позиции спецификации
    @new_item = SaleItem.new(
      :sale_id    => @sale.id,
      :price_in   => @ware.price_in,
      :price_out  => @ware.price_out,
      :quantity   => 1)
    # если при поступлении товара была указана скидка
    if @ware.discount
      @new_item.discount       = @ware.discount
      @new_item.discount_value = @ware.discount.value
      @new_item.price_discount = @ware.price_out * (1.0 - @new_item.discount_value / 100.0)
    else
      @new_item.price_discount = @ware.price_out
    end
    @new_item.price_total = @new_item.price_discount
  end

  #-----------------------------------------------------------------------------
  def del_item
    sale_item = SaleItem.find(params[:sub_action_id])
    if sale_item.can_be_deleted
      sale_item.destroy
    end
  end

  #-----------------------------------------------------------------------------
  def create_item
    @new_item = SaleItem.new(params[:sale][:new_item])
    @new_item.sale_id = @sale.id
    # сохраним позицию спецификации со всеми вытекающими:
    #  - обновление итоговых полей сделки-родителя
    #  - перемещение товара;
    #  - корректировка остатков;
    #  - формирование задачи по перемещению;
    if ! @new_item.save
      @ware = @new_item.ware_item.ware
      return false
    end
    # ниже следующая строка необходима для того, чтобы перечитать новые
    # значения сделки из базы. новые значения установились в результате
    # сохранения позиции спецификации (@new_item.save)
    @sale = Sale.find(@sale.id)
    return true
  end

  #-----------------------------------------------------------------------------
  def update_item
    @chg_item = SaleItem.find(params[:chg_item_id])
    if ! @chg_item.update_attributes(params[:sale][:chg_item])
      return false
    end
    @sale = Sale.find(@sale.id)
    return true
  end

  #-----------------------------------------------------------------------------
  def smart_render action
    # при на жатии на кнопку Сохранить, форма отсылается с указанием target_frame.
    # при запросе нового товара, форма отсылается ajax (см. sale.js sale.new_item)
    # поэтому, как я понимаю, нужно по разному возвращать ответ:
    # либо в target_frame (с помощью responds_to_parent), либо обычный ответ
    # если форма отправлена в виде запроса нового товара
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
  def find_sale
    @sale = Sale.sales.visible_for_user.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  # здесь заполняются переменные экземпляра, необходимые для рендеринга ВИДА,
  # дабы максимально исключить программную логику из ВИДА
  def before_render
    # склад, с которого будет совершена сделка
    if current_user.ware_house_id
      @sale_ware_houses_collection = [[current_user.ware_house.name, current_user.ware_house_id]]
    else
      @sale_ware_houses_collection = current_user.account.ware_houses.map{|i|[i.name,i.id]}
    end
    # ответственный менеджер, статусы сделки
    @states_collection = SaleState.for_account.find(:all)
    @recipients_collection = current_user.account.users.map(&:convert)
    @filter_recipients = Sale.sales.visible_for_user.find(:all, :group => :recipient_id).map{|c|[c.recipient_id,c.recipient.name]}
    # скидка на товар
    @discounts_collection = current_user.account.discounts.map{|i|["#{i.value}% #{i.name}",i.id]}
    @discounts_collection << [I18n::t(:set_discount),-1]
    # итоговые скидки сделки (только для отображения)
    if @sale && @sale.price_total != 0 && @sale.price_out >= @sale.price_total
      @summ_discount_cur = (@sale.price_out - @sale.price_total).round(2)
      @summ_discount_per = (@summ_discount_cur / (@sale.price_total + @summ_discount_cur) * 100.0).round(2)
    else
      @summ_discount_cur = 0
      @summ_discount_per = 0
    end
    # обработка фильтра
    @sales = nil
    wp = @_search.empty? ? @_paging : nil
    case @_filter[:type]
      when :tags
        @sales = SaleTag.find(@_filter[:id]).owners.sales.visible_for_user.pfind(wp)
      when :states
        @sales = SaleState.find(@_filter[:id]).sales.visible_for_user.pfind(wp)
      when :recent_records
        case @_filter[:id]
          when 0
            @sales = Sale.sales.visible_for_user.recently_created.pfind(wp)
          when 1
            @sales = Sale.sales.visible_for_user.recently_updated.pfind(wp)
        end
      when :recipient
        @sales = Sale.sales.visible_for_user.find(:all, :conditions => {:recipient_id => @_filter[:id]})
    end
    @sales = Sale.sales.visible_for_user.pfind(wp) unless @sales
    # обработка поиска
    Search::and_search(@sales, @@fields_for_search, @_search)
    # обработка пагинации
    unless @_search.empty?
      process_paging(@sales)
    end
  end

  #-----------------------------------------------------------------------------
  # из-за специфики создания сделки/элементов спецификации при отмене необходимо
  # знать какие элементы спецификации (а возможно и саму сделку) необходимо
  # удалить. для этого здесь устанавливается время начала изменяющей операции,
  # чтобы при отмене удалить добавленные записи с временем создания большим,
  # чем время начала операции (create или edit).
  # т.о. отмена понимается только в виде УДАЛЕНИЯ вновь ДОБАВЛЕННЫХ записей,
  # а не отмена внесенных изменений в существующие записи
  def set_time_for_canceling
    # помним, что в БД все хранится без указания смещения временной зоны
    # поэтому работаем так, как будто мы находимся на нулевом меридиане
    session[:operation_start_time] = Time.now.getutc
  end

  #-----------------------------------------------------------------------------
  # здесь item удаляется, если на него нет ссылок из других объектов, либо
  # разрешили удалять ссылающиеся объекты, либо перенаправлять ссылающиеся
  # объекты.
  # иначе item помещается в массив @nested
  def try_destroy item
    @nested ||= []
    action = params[:"action_for_#{item.id}"]
    new_id = params[:"new_id_for_#{item.id}"]
    if item.can_be_deleted
      if item.cases.any?
        case action
        when '0' # не удалять запись
          return
        when '1' # удалить запись и все ссылающиеся
          item.destroy
        when '2' # удалить запись и перенаправить ссылки
          begin
            new_item = Sale.sales.for_account.find(new_id)
          rescue
            new_item = nil
          end
          if new_item and new_item != item
            new_item.cases << item.cases
            item.reload_with_autosave_associations
            item.destroy
          else
            @nested << item
          end
        else
          @nested << item
        end
      else
        item.destroy
      end
    end
  end

  #-----------------------------------------------------------------------------
  def render_after_destroy
    before_render
    if @nested.any?
      @new_items = Sale.sales.for_account.find(:all)
      render :action => :confirm_mass_destroy
    else
      render :action => :destroy
    end
  end

end
