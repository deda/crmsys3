class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.integer   :account_id
      t.integer   :user_id        # кто поставил задачу
      t.integer   :recipient_id   # кому поставлена задача
      t.integer   :owner_id       # привязка задачи к...
      t.string    :owner_type     # ...другому объекту
      t.integer   :position
      t.integer   :parent_id      # для вложенных задач
      t.string    :name           # название задачи
      t.text      :description    # описание задачи
      t.datetime  :completion_time
      t.integer   :expended_hours
      t.boolean   :completed      # =true, если задача завершена
      t.boolean   :visible
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
    add_index :tasks, [:user_id, :account_id]
    add_index :tasks, :account_id
    add_index :tasks, [:owner_id, :owner_type]
    add_index :tasks, :owner_type
    add_index :tasks, :deleted_at
    add_index :tasks, :recipient_id
  end
end
