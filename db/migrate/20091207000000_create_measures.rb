class CreateMeasures < ActiveRecord::Migration
  def change
    create_table :measures do |t|
      t.integer   :account_id   # к какому аккаунту относится единица измерения
      t.integer   :user_id      # автор единицы измерения
      t.string    :name         # название единицы измерения
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
