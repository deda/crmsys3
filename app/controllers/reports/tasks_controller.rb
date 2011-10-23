class Reports::TasksController < ReportsController

  #-----------------------------------------------------------------------------
  # соблюдение сроков выполнения поставленных задач
  # строиться массив вида:
  # [кол-во дней на выполнение задачи, кол-во дней реально потраченных, ...]
  def punctuality

    @data = []
    @users = find_recipients(true)
    @user = find_user
    @user = current_user unless @users.include? @user

    # получаю задачи для анализа
    # @user - пользователь, чьи задачи буду анализировать
    # если @user - это не я, то беру только те задачи, которые я ставил этому пользователю
    # если @user - это я, то беру все задачи поставленные мне (мной и другими пользователями)
    conditions = ['created_at >= ? AND created_at <= ?', @from, @to]
    if @user != current_user
      conditions[0] += ' AND user_id = ?'
      conditions << current_user.id
    end
    tasks = @user.received_tasks.for_account.find(
      :all,
      :order => :created_at,
      :conditions => conditions)

    tasks.each do |task|
      next unless task.completion_time # задачи с временем выполнения "позже" не анализируем
      # время отведенное на выполнение задачи
      @data << task.completion_time.to_date - task.created_at.to_date + 1
      if task.completed?
        if log = CrmLog.for_abject(task).find_last_field_value('completed', 'true')
          # если задача выполнена, то используем дату завершения
          @data << log.dati.to_date - task.created_at.to_date + 1
        end
      else
        # если задача не выполнена, то используем текущую дату
        @data << DateTime.now.to_date - task.created_at.to_date + 1
      end
    end

    responds_to_parent do
      render :template => 'reports/canvas_update'
    end if params[:report]

  end

  #-----------------------------------------------------------------------------
  # поставленные задачи другим пользователям
  def outcoming

    @users = find_recipients
    @user = find_user
    @user = current_user unless @users.include? @user

    responds_to_parent do
      render :action => :show_user_tasks
    end if params[:report]

  end

end
