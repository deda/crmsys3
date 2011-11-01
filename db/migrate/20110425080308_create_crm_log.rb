class CreateCrmLog < ActiveRecord::Migration
  def change
    create_table :crm_logs do |t|
      t.integer   :account_id   # к какому аккаунту относится лог
      t.integer   :user_id      # пользователь, внесший изменения
      t.integer   :record_id    # id измененной записи
      t.integer   :oper_type    # 0-create, 1-change, 2-destroy
      t.string    :object       # измененный объект
      t.string    :fields       # список изменяемых полей (через ',')
      t.string    :values       # значения полей (через ',')
      t.datetime  :dati         # дата/время внесения изменений
    end
  end
end
