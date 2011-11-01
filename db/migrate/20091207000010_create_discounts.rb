class CreateDiscounts < ActiveRecord::Migration
  def change
    create_table :discounts do |t|
      t.integer     :account_id     # к какому аккаунту относится скидка
      t.integer     :user_id        # автор скидки
      t.string      :name           # название скидки
      t.decimal     :value,         # процент скидки
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.boolean     :is_makrup,     # = true, если это наценка, а не скидка
        :default    => false
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
