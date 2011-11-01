# Эта таблица является базовым классом для некоторых других.
# AddressType, PhoneType, EmailType, ImType, UrlType - поле value содержит
#   vcard-значение для экспорта (уже не используется)
# SaleState - поле value содержит процент завершения сделки
# ...Settings - поле value содержит значение настройки
class CreateTypes < ActiveRecord::Migration
  def change
    create_table :types do |t|
      t.string    :type         # тип записи (наследование ActiveRecord)
      t.integer   :account_id   # к какому аккаунту относится тип, статус
      t.integer   :user_id      # автор записи
      t.string    :name         # наименование типа, статуса, тэга
      t.string    :value        # см. коммент в начале файла
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
    add_index :types, :type
    add_index :types, [:user_id, :account_id]
    add_index :types, :account_id
    add_index :types, :name
    add_index :types, :deleted_at
  end
end
