class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales do |t|
      t.integer   :account_id         # чья это сделка
      t.integer   :user_id            # инициатор сделки
      t.integer   :recipient_id       # ответственный за сделку (ссылка на таблицу users)
      t.integer   :contact_id         # контрагент (кому продаем)
      t.integer   :ware_house_id      # на каком складе сделка
      t.string    :name               # название сделки
      t.text      :description        # описание сделки
      t.integer   :state_id           # статус сделки
      t.boolean   :is_sale,           # true: продажа, false: покупка
        :default    => true
      t.integer     :discount_id      # примененная скида
      t.decimal     :discount_value,  # значение скидки в %
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal   :price_in,          # = сумма всех SaleItem.price_in * SaleItem.quantity этой Sale (средства, затраченные на совершение этой сделки)
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal   :price_out,         # = сумма всех SaleItem.price_out * SaleItem.quantity этой Sale
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal   :price_discount,    # = сумма всех SaleItem.price_discount * SaleItem.quantity этой Sale
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal   :price_total,       # = price_discount * (1 - discount_value / 100)
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.integer :visibility,          # режим видимости
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
