class ReportsController < ApplicationController

  before_filter :set_period

  
protected

  #-----------------------------------------------------------------------------
  # устанавливает начальную и конечную дату из параметров, если они переданы
  # иначе - период = от начала года до текущей даты
  def set_period
    if p=params[:report]
      @from = DateTime.new(p[:"from(1i)"].to_i, p[:"from(2i)"].to_i, p[:"from(3i)"].to_i).beginning_of_day
      @to   = DateTime.new(p[:"to(1i)"].to_i, p[:"to(2i)"].to_i, p[:"to(3i)"].to_i).end_of_day
    else
      @from = DateTime.now.beginning_of_year
      @to   = DateTime.now.utc # т.к. в БД время задач хранится в utc
    end
  end

  #-----------------------------------------------------------------------------
  # возвращается массив пользователей, которым я ставил задачи
  def find_recipients need_include_current_user = false
    tasks = Task.for_user.find(
      :all,
      :conditions => ['created_at >= ? AND created_at <= ?', @from, @to])
    current_user_included = false
    users = tasks.map do |task|
      current_user_included = true if current_user == task.recipient
      task.recipient
    end
    users << current_user if need_include_current_user and not current_user_included
    return users.uniq
  end

  #-----------------------------------------------------------------------------
  # возвращает пользователя id которого передан в params
  # иначе - возвращает current_user
  def find_user default=current_user
    user = nil
    if (p=params[:report] and uid=p[:user_id]) or uid=params[:user_id]
      user = User.for_account.find(uid) unless uid.blank?
    end
    return user || default
  end

end