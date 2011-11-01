class CreateGroupMemberships < ActiveRecord::Migration
  def change
    create_table(:group_memberships, :id => false) do |t|
      t.integer   :user_id
      t.integer   :user_group_id
      t.integer   :case_id
      t.integer   :sale_id
    end
  end
end
