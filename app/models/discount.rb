class Discount < ActiveRecord::Base
  is_paranoid
  account_and_user_protected

  has_many    :wares
  has_many    :sale_items
  has_many    :companies

  # Рассчитывает скидку и цену со скидкой
  # На входе:
  #   id - идентификатор выбранной скидки. может быть
  #         0 - нет скидки,
  #        -1 - значение value указано в ручную,
  #        хх - id существующей скидки
  # На выходе:
  #   массив [new_id, new_value, new_price]
  #   Интерпритация:
  #   1. [0,0,p] - скидки нет, цена не изменилась
  #   2. [0,v,p] - значение скидки v введено в ручную, p=цена_со_скидкой_v
  #   3. [i,v,p] - выбрана скидка с id=i, v=Discount(id).value, p=цена_со_скидкой_v
  def self.calc (id,value,price)
    id    = id ? id.to_i : nil
    value = value ? value.to_f : 0
    price = price ? price.to_f : 0
    if id == nil
      value = 0
    elsif id != -1
      begin
        value = find(id).value
      rescue
        value = 0
        id = nil
      end
    else
      id = nil
    end
    price = price * (1.0 - value / 100.0)
    return [id, value.to_f.round(2), price.to_f.round(2)]
  end
end
