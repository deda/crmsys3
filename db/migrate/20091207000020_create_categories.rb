class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.integer   :account_id   # к какому аккаунту относится категория
      t.integer   :user_id      # автор категории
                                # Если 0, то эта единица общая для всех
      t.integer   :parent_id,   # ссылка на категорию, чьей подкатегорией
                                # является данная категория :)
        :default  => 0
      t.string    :name         # название категории
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
