class Measure < ActiveRecord::Base
  is_paranoid
  account_and_user_protected

  has_many    :wares
end
