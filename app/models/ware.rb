class Ware < Commodity

  belongs_to :company
  belongs_to :discount
  belongs_to :measure
  has_many :images, :as => :owner, :dependent => :destroy
  has_many :ware_items, :dependent => :destroy
  has_many :ware_houses, :through => :ware_items
  has_many :ware_movements, :dependent => :destroy

  accepts_nested_attributes_for :images,
    :allow_destroy => true

  #-----------------------------------------------------------------------------
  named_scope :for_select, lambda{ |array|
    {:conditions => ['id NOT IN (?)', array]}
  }

  #-----------------------------------------------------------------------------
  # возвращает коллекцию размещений на складах данного товара
  def ware_items_collection sale_item=nil
    ware_items.map{ |i|
      # ниже следующая вилка пока не используется, т.к. есть спорная ситуация:
      # при редактировании позиции спецификации показывать менеджеру
      # доступное кол-во товара на складе С или БЕЗ учета кол-ва в
      # редактируемой позиции?
      # ПРИМЕР. было 100, купили 20. потом редактируем покупку. сколько нужно
      # показывать доступного товара 100 или 80? если нужно показывать 100,
      # то при редактировании при вызове ware_items_collection нужно
      # указать sale_item
      if sale_item and i.id == sale_item.ware_item_id
        q = sale_item.quantity
      else
        q = 0.0
      end
      ["#{i.ware_house.name} (#{i.quantity + q} #{i.ware.measure.name})", i.id]
    }
  end

end
