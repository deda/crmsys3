class CreateContactItems < ActiveRecord::Migration
  def change
    create_table :contact_items do |t|
      t.string    :type         # тип записи: Email, Im, Phone, Url
      t.integer   :contact_id   # к какому контакту относится запись
      t.integer   :type_id      # тип почты, месседжера, телефона, урла
      t.integer   :protocol_id  # тип протокола для Im (ссылка на таблицу Types)
      t.string    :value        # содержимое: электронный адрес, телефон...
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
      t.string    :crc
      t.index     [:contact_id, :deleted_at]
      t.index     [:contact_id, :type]
      t.index     [:contact_id, :deleted_at, :type]
      t.index     :type
      t.index     :contact_id
      t.index     :deleted_at
      t.index     :crc
    end
  end
end
