class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string    :name
      t.boolean   :is_director,   # признак управляющего аккаунта
        :default => false
      t.integer   :tariff_plan_id # тарифный план аккаунта
      t.datetime  :end_time
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
