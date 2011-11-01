class CreateIdCards < ActiveRecord::Migration
  def change
    create_table :id_cards do |t|
      t.integer   :account_id   # к какому аккаунту принадлежит
      t.integer   :user_id      # какой пользователь создал запись
      t.integer   :contact_id   # чье это удостоверение
      t.integer   :ctype        # тип: паспорт, загран. паспорт, права...
      t.string    :series       # серия
      t.string    :number       # номер
      t.string    :code         # код
      t.string    :whom         # кем выдан
      t.string    :when         # когда выдан
      t.string    :expiry       # срок действия
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
      t.string    :crc
    end
  end
end
