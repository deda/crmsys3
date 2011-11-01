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
      t.index     [:user_id, :account_id]
      t.index     :account_id
      t.index     [:owner_id, :owner_type]
      t.index     :owner_type
      t.index     :deleted_at
      t.index     :recipient_id
    end
  end
end
