class Reports::UsersController < ReportsController

  #-----------------------------------------------------------------------------
  # активность пользователя: кол-во заведенных контактов, задач, сделок и т.п.
  def activity

    @data = []
    @users = User.for_account.all if current_user.is_admin?
    @user = find_user

    # контакты:
    # [
    #   общее кол-во контактов аккаунта,
    #   кол-во контактов, созданных пользователем
    # ]
    @data << Contact.for_account.all.count
    @data << @user.contacts.count

    # задачи:
    # [ 
    #   общее кол-во задач аккаунта,
    #   кол-во задач, поставленных пользователем (исходящие),
    #   кол-во задач, поставленных пользователю (входящие),
    #   кол-во выполненных задач (входящие, выполненные)
    # ]
    @data << Task.for_account.all.count
    @data << @user.posted_tasks.count
    @data << @user.received_tasks.count
    @data << @user.received_completed_tasks.count

    # сделки:
    # [
    #   общее кол-во сделок аккаунта,
    #   кол-во сделок, в которых пользователь ответственный,
    #   общая сумма сделок аккаунта,
    #   сумма сделок пользователя
    # ]
    sales = Sale.for_account.all
    user_sales = @user.received_sales.all
    summ = 0
    user_summ = 0
    sales.each { |sale| summ += sale.price_total }
    user_sales.each { |sale| user_summ += sale.price_total }
    @data << sales.count
    @data << user_sales.count
    @data << summ
    @data << user_summ

    # дела:
    # [
    #   общее кол-во дел аккаунта,
    #   кол-во дел, в которых пользователь ответственный
    # ]
    @data << Case.for_account.all.count
    @data << @user.received_cases.count

    responds_to_parent do
      render :template => 'reports/canvas_update'
    end if params[:report]

  end

end
