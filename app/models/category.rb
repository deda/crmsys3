class Category < ActiveRecord::Base
  is_paranoid

  belongs_to  :parent,
              :class_name   => "Category"
  has_many    :children,
              :class_name   => "Category",
              :foreign_key  => :parent_id,
              :order        => :name,
              :dependent    => :destroy
end
