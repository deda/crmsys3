class Task < ActiveRecord::Base
  extend Paging
  is_paranoid :order => :completion_time
  account_and_user_protected
  has_many_attachmends
  def_recently_scopes
  has_many_tags TaskTag

  belongs_to  :recipient, :class_name => 'User'
  belongs_to  :owner,     :polymorphic => true
  has_many    :comments,  :as => :owner, :dependent => :destroy

  validates_presence_of :name, :recipient

  acts_as_list :scope => :owner_id

  # acts as tree
  belongs_to  :parent,
              :class_name   => 'Task'
  has_many    :children,
              :class_name   => 'Task',
              :foreign_key  => :parent_id,
              :dependent    => :destroy

  before_save :check_recipient
  before_save :check_parent

  # задачи, связанные с каким-либо объектом
  scope :nested, lambda{ |owt|
    conditions = owt ? ['owner_type=?', owt] : 'NOT owner_id IS NULL'
    {:conditions => conditions}
  }
  # задачи, не связанные ни с каким объектом
  scope :freed,
    {:conditions => {:owner_id => nil}}
  # задачи, не имеющие родителя
  scope :wo_parent,
    {:conditions => {:parent_id => nil}}

  def ends_at_current_week_or_earlier?
    completion_time <= Date.today.end_of_week.end_of_day
  end

  def ends_at_next_week?
    completion_time > Date.today.end_of_week.end_of_day and
      completion_time <= Date.today.end_of_week.tomorrow.end_of_week.end_of_day
  end

  #-----------------------------------------------------------------------------
  def move_to state
    if Task::TimeStampsArray.include?(state)
      self.completion_time = Task.send(state)
      self.save
    else
      return false
    end
  end

  #-----------------------------------------------------------------------------
  # завершение задачи
  def complete!
    self.completed = true
    self.save
  end

  #-----------------------------------------------------------------------------
  # отмена завершения задачи
  def uncomplete!
    self.completed = false
    self.save
  end

  #-----------------------------------------------------------------------------
  # обработка временных интервалов
  # для добавления нового временного интервала "xxx":
  #   1. добавить строку "xxx" в TimeStampsArray
  #   2. добавить одноименный метод self.xxx
  TimeStampsArray = ["today", "tomorrow", "this_week", "next_week", "this_month", "next_month", "later"]
  def self.now
    Time.utc(*Time.now.to_a)
  end
  def self.today
    Time.utc(*Date.today.end_of_day.to_a)
  end
  def self.tomorrow
    Time.utc(*Date.tomorrow.end_of_day.to_a)
  end
  def self.this_week
    Time.utc(*Date.today.end_of_week.end_of_day.to_a)
  end
  def self.next_week
    Task.this_week + 7.days
  end
  def self.this_month
    Time.utc(*Date.today.end_of_month.end_of_day.to_a)
  end
  def self.next_month
    Time.utc(*Date.today.next_month.end_of_month.end_of_day.to_a)
  end
  def self.later
    nil
  end
  def timestamps
    col = []
    bts = false
    Task::TimeStampsArray.each do |ts|
      dati = Task.send(ts)
      bts = true if not bts and completion_time == dati
      col << [I18n.t("activerecord.task.#{ts}"), dati]
    end
    col << [I18n.l(completion_time.to_date), completion_time] unless bts
    col << [I18n.t('activerecord.task.pick_date'), -1]
    return col
  end
  def belongs_to_timestamps?
    Task::TimeStampsArray.each do |ts|
      return true if completion_time == Task.send(ts)
    end
    return false
  end
  def timestamp
    timestamps.each do |ts|
      return ts[0] if completion_time == ts[1]
    end
  end

  # возвращает true если задача просроченна
  def overdue?
    completion_time < Task.now
  end
  # возвращает true если задача должна быть выполнена сегодня
  def today?
    completion_time >= Task.now and completion_time <= Task.today
  end
  # возвращает true если задача должна быть выполнена завтра
  def tomorrow?
    completion_time > Task.today and completion_time <= Task.tomorrow
  end
  # возвращает true если задача должна быть выполнена на этой неделе
  def this_week?
    completion_time > Task.tomorrow and completion_time <= Task.this_week
  end
  # возвращает true если задача должна быть выполнена на следующей неделе
  def next_week?
    completion_time > Task.this_week and completion_time <= Task.next_week
  end
  # возвращает true если задача должна быть выполнена "когда-нибудь"
  def later?
    completion_time.nil?
  end


  #-----------------------------------------------------------------------------
  # возвращает хэш массивов, содержащих задачи, сгруппированные по времени выполнения
  def self.do_group tasks
    h = {
      :overdue    => [],
      :today      => [],
      :tomorrow   => [],
      :this_week  => [],
      :next_week  => [],
      :other      => [],
      :completed  => []}
    tasks ||= []
    tasks.each do |task|
      if task.completed?
        h[:completed] << task
      elsif task.later?
        h[:other] << task
      elsif task.overdue?
        h[:overdue] << task
      elsif task.today?
        h[:today] << task
      elsif task.tomorrow?
        h[:tomorrow] << task
      elsif task.this_week?
        h[:this_week] << task
      elsif task.next_week?
        h[:next_week] << task
      else
        h[:other] << task
      end
    end
    return h
  end

  #-----------------------------------------------------------------------------
  # возвращает true если эту задачу я поставил сам себе
  def self_me
    user_id == $current_user.id && recipient_id == $current_user.id
  end
  # возвращает true если эту задачу поставил кто-то мне
  def some_me
    user_id != $current_user.id && recipient_id == $current_user.id
  end
  # возвращает true если эту задачу поставил я кому-то
  def from_me
    user_id == $current_user.id && recipient_id != $current_user.id
  end
  # возвращает true если эта задача меня не касается вообще
  def not_me
    user_id != $current_user.id && recipient_id != $current_user.id
  end
  # возвращает true если эта задача поставлена мне
  def for_me
    recipient_id == $current_user.id
  end
  # возвращает строку: кто кому поставил эту задачу
  def who_to_whom
    if some_me
      return I18n::t(:task_some_me, :user => user.name)
    elsif from_me
      return I18n::t(:task_from_me, :recipient => recipient.name)
    elsif not_me
      return I18n::t(:task_not_me1, :user => user.name) if user_id == recipient_id
      return I18n::t(:task_not_me2, :user => user.name, :recipient => recipient.name)
    else
      return ''
    end
  end

  #-----------------------------------------------------------------------------
  def completion_time_string
    return '' if belongs_to_timestamps?
    I18n.l(completion_time.to_date)
  end

  #-----------------------------------------------------------------------------
  def self.string_for item
    c = item.tasks.count
    c > 0 ? "<div class='tasks_string'><b>#{I18n.t(:tasks)}:</b>#{c}</div>" : ''
  end

  #-----------------------------------------------------------------------------
  def empty?
    name.blank?
  end

  #-----------------------------------------------------------------------------
  def formated_name
    "#{timestamp}: #{name}"
  end

  #-----------------------------------------------------------------------------
  def check_recipient
    if account_id and recipient.account_id != account_id
      errors.add_to_base(I18n.t('activerecord.errors.messages.tasks.recipient'))
      return false
    end
    return true
  end

  #-----------------------------------------------------------------------------
  # ограничение на создание задач с уровнем вложенности больше 1
  def check_parent
    if parent_id and (id == parent_id or parent.parent_id or children.count > 0)
      return false
    end
  end

end
