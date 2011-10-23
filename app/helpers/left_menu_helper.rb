module LeftMenuHelper

  # рендерит контекстные кнопки элемента (заданные в options) в левое меню
  def self.render page, options
    page.replace_html "left_menu_item_buttons",
      :partial => 'shared/buttons',
      :locals => options
    page << 'left_menu.correct();'
  end

end
