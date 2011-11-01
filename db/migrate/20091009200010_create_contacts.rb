class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      # поля персоны, компании, банка
      t.string    :type             # тип записи: Person(персона), Company(компания), Bank(банк)
      t.integer   :account_id       # аккаунт контакта
      t.integer   :user_id          # автор контакта
      t.integer   :parent_id        # начальник персоны, вышестоящая компания
      t.string    :given_name       # имя персоны (сокращенное наименование организации)
      t.string    :family_name      # фамилия персоны (полное наименование организации)
      t.boolean   :visible,         # =true, если контакт могут видеть все пользователи аккаунта
        :default    => true
      # поля персоны
      t.integer   :company_id       # компания персоны (ссылка на контакт)
      t.string    :title            # должность персоны
      t.string    :additional_name  # отчество персоны
      t.string    :nick_name        # ник персоны
      t.string    :pref             # префикс уважительного обращения персоны
      t.string    :suff             # суффикс уважительного обращения персоны
      t.string    :bday             # дата рождения персоны
      # поля компании
      t.integer   :bank_id          # банк компании (ссылка на контакт)
      t.string    :rs               # рассчетный счет компании в банке
      t.integer   :discount_id      # скидка для этого контрагента
      t.decimal   :discount_value,  # значение скидки в %
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      # поля компании, банка
      t.string    :inn              # ИНН
      t.string    :kpp              # КПП
      t.string    :ogrn             # ОГРН
      # поля банка
      t.string    :bic              # БИК банка
      t.string    :cs               # корр счет банка
      # общие поля
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
    add_index :contacts, [:user_id, :account_id]
    add_index :contacts, :account_id
    add_index :contacts, :type
    add_index :contacts, :deleted_at
  end
end
