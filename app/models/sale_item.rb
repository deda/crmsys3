class SaleItem < ActiveRecord::Base
  is_paranoid

  belongs_to :sale
  belongs_to :ware_item
  belongs_to :discount
  has_one :ware_movement, :dependent => :destroy

  validates_presence_of(
    :sale,
    :ware_item,
    :quantity,
    :price_in,
    :price_out,
    :price_discount
  )
  validates_existence_of :ware_item

  #-----------------------------------------------------------------------------
  # перед сохранением
  # рассчитываем:
  #   цены
  #   скидки
  # проверяем:
  #   цена больше нуля
  #   кол-во больше нуля и не больше остатков на складе
  def before_save
    self.price_in  = ware_item.ware.price_in
    self.price_out = ware_item.ware.price_out
    self.discount_id, self.discount_value, self.price_discount = Discount.calc(
      discount_id,
      discount_value,
      price_out)
    old_quantity = new_record? ? 0 : @changed_attributes['quantity'] || quantity
    errors.add(:quantity)       if quantity <= 0 or quantity > ware_item.quantity + old_quantity
    errors.add(:price_discount) if price_discount <= 0
    return false if errors.count != 0
    self.price_total = price_discount * quantity
  end

  #-----------------------------------------------------------------------------
  # здесь как-бы откатим предыдущую продажу
  def after_update
    old_quantity    = quantity    unless (old_quantity    = @changed_attributes['quantity'])
    old_price_in    = price_in    unless (old_price_in    = @changed_attributes['price_in'])
    old_price_out   = price_out   unless (old_price_out   = @changed_attributes['price_out'])
    old_price_total = price_total unless (old_price_total = @changed_attributes['price_total'])
    sale.update_attributes!(
      :price_in       => sale.price_in       - old_price_in * old_quantity,
      :price_out      => sale.price_out      - old_price_out * old_quantity,
      :price_discount => sale.price_discount - old_price_total)
    if ware_item and ware_item.ware
      ware_item.update_attributes!(
        :quantity => ware_item.quantity + old_quantity)
    end
  end

  #-----------------------------------------------------------------------------
  # после сохранения позиции спецификации:
  #   скорректируем зависящие поля сделки-родителя
  #   уменьшим остатки на складах
  #   создадим уведомление (задачу) о достижении минимального остатка товара
  #   создадим перемещение, если продажа с другого склада
  def after_save
    # обновление зависящих полей сделки-родителя
    sale.update_attributes!(
      :price_in       => sale.price_in       + price_in * quantity,
      :price_out      => sale.price_out      + price_out * quantity,
      :price_discount => sale.price_discount + price_total)
    # уменьшим остатки
    if ware_item and ware_item.ware
      ware_item.update_attributes!(
        :quantity => ware_item.quantity - quantity)
    end
    # создадим уведомление (пока не ясно для кого, поэтому пока - для админа аккаунта)
    if ware_item.quantity <= ware_item.minimum
      sale.tasks.create!(
        :account_id       => sale.account_id,
        :user_id          => sale.user_id,
        :recipient_id     => sale.account.admins[0].id,
        :name             => "На складе '#{ware_item.ware_house.name}' товара '#{ware_item.ware.name}' осталось меньше #{ware_item.minimum} #{ware_item.ware.measure.name}.",
        :completion_time  => Time.now.end_of_day,
        :visible          => true)
    end
    # если нужно перемещение
    if ware_item.ware_house_id != sale.ware_house_id
      # если перемещение уже было, обновим его
      if ware_movement
        ware_movement.update_attributes!(
          :user_id      => sale.user_id,
          :ware_id      => ware_item.ware_id,
          :from_id      => ware_item.ware_house_id,
          :to_id        => sale.ware_house_id,
          :quantity     => quantity)
      # если перемещения не было, создадим его
      else
        WareMovement.create!(
          :user_id      => sale.user_id,
          :ware_id      => ware_item.ware_id,
          :from_id      => ware_item.ware_house_id,
          :to_id        => sale.ware_house_id,
          :sale_item_id => id,
          :quantity     => quantity)
      end
    # если перемещение не нужно, но оно было создано ранее, удалим его
    elsif ware_movement
      ware_movement.destroy
    end
  end

  #-----------------------------------------------------------------------------
  # после удаления:
  #   скорректируем поля сделки-родителя
  #   увеличим остатки товара
  def after_destroy
    # обновление зависящих полей сделки-родителя
    sale.update_attributes!(
      :price_in       => sale.price_in       - price_in * quantity,
      :price_out      => sale.price_out      - price_out * quantity,
      :price_discount => sale.price_discount - price_total)
    # если товар еще не удалили, увеличим его остатки на складе
    if ware_item and ware_item.ware
      ware_item.update_attributes!(
        :quantity => ware_item.quantity + quantity)
    end
  end

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    user.is_admin? or sale.user_id == user.id
  end

  #-----------------------------------------------------------------------------
  def can_be_deleted user=$current_user
    user.is_admin? or sale.user_id == user.id
  end

end
