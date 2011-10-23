class Project < ActiveRecord::Base
  is_paranoid 

  belongs_to  :account
  has_many :tasks, :as => :owner, :dependent => :destroy, :order => :position
  
  validates_presence_of :name, :account

  named_scope :for_user, lambda{ |user|
    conditions = user.is_admin? ? '': {:account_id => user.account.id}
    {:conditions=> conditions}
  }
  named_scope :by_name, lambda{ |search|
    conditions = search.blank? ? "" : ['projects.name LIKE (?) OR tasks.name LIKE (?)', "%#{search}%","%#{search}%"]
    {:include => :tasks, :conditions => conditions}
  }
  named_scope :incomplete,
    :include => :tasks,
    :conditions => ['tasks.state = (?)',"incomplete"]
  # обратить внимание на неудалённость задач в условии
  # офигенная тема..если вызвать метод tasks для любого элемента набора,
  #  найдутся только задачи, которые удовлетворяют conditions..неожиданно
  named_scope :current_week_projects, lambda{
    {:include => :tasks, :conditions => ['tasks.completion_time <= ? AND tasks.state = ? AND tasks.deleted_at IS ?', Task.end_of_current_week,"incomplete",nil]}
  }
  named_scope :next_week_projects, lambda{
    {:include => :tasks, :conditions => ['tasks.completion_time BETWEEN ? AND ? AND tasks.state = ? AND tasks.deleted_at IS ?', Task.end_of_current_week, Task.end_of_next_week, "incomplete", nil]}
  }
  named_scope :other_projects, lambda{
    {:include => :tasks, :conditions => ['tasks.completion_time > ? AND tasks.state = ? AND tasks.deleted_at IS ?',Task.end_of_next_week, "incomplete", nil]}
  }

  def convert
    [ name , id ]
  end

  def incomplete?
    reload.tasks.each do |task|
      if task.incomplete?
        return true
      end
    end
    return false
  end

  def complete!
    transaction do
      reload.tasks.each do |task|
        unless task.completed?
          task.complete!
        end
      end
    end
  end

  def ends_at_current_week_or_earlier?
    tasks.each do |task|
      return true if (task.ends_at_current_week_or_earlier? and task.incomplete?)
    end
    return false
  end

  def ends_at_next_week?
    unless ends_at_current_week_or_earlier?
      tasks.each do |task|
        return true if (task.ends_at_next_week? and task.incomplete?)
      end
    end
    return false
  end

  def self.time_bindings
    ["current_week","next_week","other"]
  end
  
end
