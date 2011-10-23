# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  #-----------------------------------------------------------------------------
  def html_id item
    return '' unless item
    @new_counter ||= 1
    s = item.class.name.underscore
    s += item.new_record? ? "_new_#{@new_counter}" : "_#{item.id}"
    @new_counter += 1
    return s
  end

  #-----------------------------------------------------------------------------
  def breadcrumbs
    html = [];
    #first layer
    html << t(@navi.to_sym)
  end

  #-----------------------------------------------------------------------------
  def complex_breadcrumbs params = nil
    navigate = [];
    #first layer
    navigate << t(@navi.to_sym)
    #second_layer
    if !params.nil?
      navigate << params
    else
      navigate << t(:list)
      navigate << (@filter.nil? ? t(:all) : @filter)
    end
    navigate.join('&nbsp;&gt;&nbsp;')
  end

  #-----------------------------------------------------------------------------
  def get_url_and_method item, pr=nil
    cn = item.class.name.pluralize.underscore
    pr = pr ? "/#{pr}" : ''
    if item.new_record?
      url     = "#{pr}/#{cn}"
      method  = :post
    else
      url     = "#{pr}/#{cn}/#{item.id}"
      method  = :put
    end
    return [url, method]
  end

  #-----------------------------------------------------------------------------
  # Группа функций для получения данных owner`а для JavaScript
  def owner_params owner, need_q=true
    if owner
      s = "owner_id=#{owner.id}&owner_type=#{owner.class.name.camelcase}"
      s = "'#{s}'" if need_q
    else
      s = nil
    end
    return s
  end
  def owner_string owner
    if owner
      "#{owner.class.name.underscore}_#{"#{owner.id}_" if owner.id}"
    else
      ""
    end
  end

  #-----------------------------------------------------------------------------
  # возвращает строку, содержащую сформированный тег <select> со списком
  # <options> из всех элементов collection. при выборе элемента посылается
  # ajax запрос на сервер для контроллера item, действие sip.
  def select_in_place item, collection, field
    sel = item.send(collection).send(field)
    if item.can_be_edited
      req = remote_function :url => send(:"sip_#{item.class.name.underscore}_path"), :with => "'field_name=#{collection}&field_id='+$(this).val()"
      s = "<select class='sip' onchange=\"#{req}\">"
      col = item.send(collection).class.for_account.find(:all)
      col.each do |c|
        v = c.send(field)
        s += "<option value='#{c.id}'#{'selected' if v == sel}>#{v}</option>"
      end
      s += '</select>'
    else
      s = sel
    end
    return s
  end

  #-----------------------------------------------------------------------------
  def tasks_comments_string_for item
    s = Task.string_for(item) + Comment.string_for(item)
    s = "<br />#{s}" unless s == ''
    return s
  end

  #-----------------------------------------------------------------------------
  def comments_string_for item
    s = Comment.string_for(item)
    s = "<br />#{s}" unless s == ''
    return s
  end

  #-----------------------------------------------------------------------------
  def locales_collection
    [['Русский','ru'],['English','en'],['Italiano','it']]
  end
  def locale_name lo
    lo = lo.to_s
    locales_collection.each do |locale|
      return locale[0] if locale[1] == lo
    end
    return ''
  end

  #-----------------------------------------------------------------------------
  def yes_no cond
    t(cond ? :yes_ : :no_)
  end

  #-----------------------------------------------------------------------------
  # локализованный upcase
  def loc_uc str
    if I18n.locale.to_s == 'ru'
      ru = {'а'=>'А','б'=>'Б','в'=>'В','г'=>'Г','д'=>'Д','е'=>'Е','ё'=>'Ё','ж'=>'Ж','з'=>'З','и'=>'И','й'=>'Й','к'=>'К','л'=>'Л','м'=>'М','н'=>'Н','о'=>'О','п'=>'П','р'=>'Р','с'=>'С','т'=>'Т','у'=>'У','ф'=>'Ф','х'=>'Х','ц'=>'Ц','ч'=>'Ч','ш'=>'Ш','щ'=>'Щ','ь'=>'Ь','ы'=>'Ы','ъ'=>'Ъ','э'=>'Э','ю'=>'Ю','я'=>'Я','a'=>'A','b'=>'B','c'=>'C','d'=>'D','e'=>'E','f'=>'F','g'=>'G','h'=>'H','i'=>'I','j'=>'J','k'=>'K','l'=>'L','m'=>'M','n'=>'N','o'=>'O','p'=>'P','q'=>'Q','r'=>'R','s'=>'S','t'=>'T','u'=>'U','v'=>'V','w'=>'W','x'=>'X','y'=>'Y','z'=>'Z'}
      s = ''
      str.each_char { |char| s += (c=ru[char]) ? c : char }
      return s
    else
      return str.upcase
    end
  end
  def loc_tuc p
    loc_uc t(p)
  end
  # локализованный downcase
  def loc_dc str
    if I18n.locale.to_s == 'ru'
      ru = {'А'=>'а','Б'=>'б','В'=>'в','Г'=>'г','Д'=>'д','Е'=>'е','Ё'=>'ё','Ж'=>'ж','З'=>'з','И'=>'и','Й'=>'й','К'=>'к','Л'=>'л','М'=>'м','Н'=>'н','О'=>'о','П'=>'п','Р'=>'р','С'=>'с','Т'=>'т','У'=>'у','Ф'=>'ф','Х'=>'х','Ц'=>'ц','Ч'=>'ч','Ш'=>'ш','Щ'=>'щ','Ь'=>'ь','Ы'=>'ы','Ъ'=>'ъ','Э'=>'э','Ю'=>'ю','Я'=>'я','A'=>'a','B'=>'b','C'=>'c','D'=>'d','E'=>'e','F'=>'f','G'=>'g','H'=>'h','I'=>'i','J'=>'j','K'=>'k','L'=>'l','M'=>'m','N'=>'n','O'=>'o','P'=>'p','Q'=>'q','R'=>'r','S'=>'s','T'=>'t','U'=>'u','V'=>'v','W'=>'w','X'=>'x','Y'=>'y','Z'=>'z'}
      s = ''
      str.each_char { |char| s += (c=ru[char]) ? c : char }
      return s
    else
      return str.downcase
    end
  end
  def loc_tdc p
    loc_dc t(p)
  end

end
