class Reports::LogsController < ReportsController

  before_filter :admin_only

  def logs_view
    @from = DateTime.now.beginning_of_week unless params[:report]
    @user = find_user(User.new(:name => I18n.t(:any_he)))
    @users = [@user]
    @users += User.for_account.all
    @opers = [
      [I18n.t(:any_she), ''],
      [I18n.t(:creation), 0],
      [I18n.t(:updating), 1],
      [I18n.t(:deletion), 2]
    ]

    # получение списка моделей
    @models = CrmLog.for_account.all(
      :select => 'object',
      :group => 'object',
      :order => 'object'
    ).map{ |i| i.object }

    # получение массива списков полей для каждой модели
    @fields = {}
    @models.each do |model|
      @fields[model] = eval("#{model}.column_names") - CrmLogger::EXCLUDED_FIELDS
    end

    # преобразование списка моделей и полей для использования в хелпере select
    @models = [[I18n.t(:any_he), '']] + @models.map{ |i| [i,i] }
    @fields.each_pair do |k, v|
      @fields[k] = [[I18n.t(:any_it), '']] + v.map{ |i| [i,i] }
    end

    conditions = ['dati>=? AND dati<=?', @from, @to]
    if p=params[:report]
      unless (@oper=p[:oper]).blank?
        conditions[0] += ' AND oper_type=?'
        conditions << @oper
      end
      unless (@model=p[:model]).blank?
        conditions[0] += ' AND object=?'
        conditions << @model
      end
      unless (@record_id=p[:record_id]).blank?
        conditions[0] += ' AND record_id=?'
        conditions << @record_id
      end
      unless (@field=p[:field]).blank?
        conditions[0] += ' AND fields LIKE ?'
        conditions << "%#{@field}%"
      end
      unless @user.id.blank?
        conditions[0] += ' AND user_id=?'
        conditions << @user.id
      end
      @logs = CrmLog.for_account.all(:conditions => conditions)
      # если указано конкретное поле, то корректировка списка полей:
      # оставляем только это поле и его значение
      @logs.each do |log|
        next unless i = log.fields.split(',').index(@field)
        log.fields = @field
        log.values = log.values.split(',')[i]
      end unless @field.blank?
      responds_to_parent do
        render :action => :update_report_container
      end
    else
      @logs = CrmLog.for_account.all(:conditions => conditions)
    end

    x = 1

  end

end
