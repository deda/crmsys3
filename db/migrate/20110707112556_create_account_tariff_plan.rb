class CreateAccountTariffPlan < ActiveRecord::Migration
  def change
    create_table :account_tariff_plans do |t|
      t.integer   :user_id
      t.string    :name
      t.integer   :price,
        :default => 0
      t.integer   :max_users
      t.integer   :max_mbytes
      t.integer   :max_contacts
      t.boolean   :with_commodities,
        :default => false
      t.boolean   :with_cases,
        :default => false
      t.boolean   :with_projects,
        :default => false
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
