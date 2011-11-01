class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :account_id                 # аккаунт пользователя
      t.integer :ware_house_id              # склад менеджера по умолчанию
      t.string  :name                       # имя пользователя
      t.string  :email                      # мыло (логин)
      t.string  :encrypted_password,        # хэш пароля
        :limit    => 128
      t.string  :salt,                      # добавка к алгоритму шифрования
        :limit    => 128
      t.string  :confirmation_token,
        :limit    => 128
      t.string  :remember_token,
        :limit    => 128
      t.boolean :email_confirmed,
        :default  => false
      t.boolean :is_admin,                  # =true, если это админ аккаунта
                                            #   (если account_id=0, то это
                                            #   главный админ)
        :default  => false
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at

      t.index   [:id, :confirmation_token]
      t.index   :email
      t.index   :remember_token
    end
  end
end
