class CreateCasesContacts < ActiveRecord::Migration
  def change
    create_table :cases_contacts, :id => false do |t|
      t.integer   :case_id         # дело
      t.integer   :contact_id      # Вовлеченный контакт
    end
  end
end
