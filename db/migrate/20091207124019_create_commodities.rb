class CreateCommodities < ActiveRecord::Migration
  def change
    create_table :commodities do |t|
      t.string    :type             # тип записи: Ware(товар), Service(услуга)
      t.integer   :account_id       # к какому аккаунту относится этот товар
      t.integer   :user_id          # автор товара
      t.integer   :measure_id       # единица измерения товара
      t.integer   :category_id      # категория товара
      t.integer   :discount_id      # скидка по умолчанию для товара
      t.integer   :company_id       # контрагент (у кого покупаем товар)
      t.string    :name             # наименование товара
      t.string    :art              # артикул
      t.decimal   :price_in,        # цена покупки товара
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal   :price_out,       # цена реализации товара
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.string    :country          # страна-производитель товара(перенести в отельную таблицу)
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
