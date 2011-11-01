class CreateCases < ActiveRecord::Migration
  def change
    create_table :cases do |t|
      t.integer   :account_id         # чье это дело
      t.integer   :user_id            # инициатор дела
      t.integer   :recipient_id       # ответственный за дело
      t.string    :code               # номер дела
      t.string    :name               # название дела
      t.text      :description        # описание дела
      t.integer   :sale_id            # сделка
      t.integer   :state_id           # статус дела
      t.integer   :visibility,        # режим видимости
        :default => 0                 # 0 - видно только создателю и ответственному
                                      # 1 - видно всем
                                      # 2 - видно создателю, ответственному и
                                      #     выбранным группам. использовать связь
                                      #     многие-ко-многим Cases <-> UserGroups
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
