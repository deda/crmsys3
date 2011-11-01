class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.integer   :type_id
      t.integer   :owner_id
      t.string    :owner_type
      t.string    :post_office_box
      t.string    :extended_address
      t.string    :street_address
      t.string    :region
      t.string    :locality
      t.string    :postal_code
      t.string    :country_name
      t.decimal   :latitude,
        :precision  => 10,
        :scale      => 6
      t.decimal   :longitude,
        :precision  => 10,
        :scale      => 6
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
      t.string    :crc
    end
  end
end
