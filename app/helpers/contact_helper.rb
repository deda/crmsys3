module ContactHelper

  #-----------------------------------------------------------------------------
  # возвращает строку
  # для Person:  "ДОЛЖНОСТЬ в компании НАЗВАНИЕ КОМПАНИИ \n непосредственно подчиняется ИМЯ НАЧАЛЬНИКА \n МЕТКИ"
  # для Company: "ПОЛНОЕ НАЗВАНИЕ КОМПАНИИ \n вышестоящая компания НАЗВАНИЕ КОМПАНИИ \n МЕТКИ"
  def sub_title contact, with_parent=false
    s = ''
    if contact
      if contact.is_a?(Person)
        # должность персоны
        s = "<span>#{contact.title}</span> "
        # из какой компании персона
        if contact.company
          s += t(:from_company) + ' ' +
            link_to_remote(
              h(contact.company.formated_name),
              :url    => contact_path(contact.company),
              :method => :get,
              :html   => {:class => :link_class})
        end
      else
        s = "<span>#{contact.family_name}</span> "
      end
      # начальник персоны, вышестоящая компания
      if with_parent and contact.parent
        s += '<br />' +
          (contact.is_a?(Person) ? t(:top_manager) : t(:top_company)) + ' ' +
          link_to_remote(
            h(contact.parent.formated_name),
            :url    => contact_path(contact.parent),
            :method => :get,
            :html   => {:class => :link_class})
      end
      # метки (тэги)
      s += '<br />' + Tag.string_for(contact)
    end
    return s
  end

  #-----------------------------------------------------------------------------
  # возвращает строку РС <номер_счета> в банке <наименование_банка>
  def rs_in_bank contact
    s = ''
    if contact.rs or (contact.bank_id and contact.bank)
      if contact.rs
        s += t(:rs) + ' ' + contact.rs + ' '
      end
      if contact.bank_id and contact.bank
        s += t(:bank) + ' ' + link_to_remote(
          h(contact.bank.formated_name),
          :url    => contact_path(contact.bank),
          :method => :get,
          :html   => {:class => :link_class})
      end
      s += '<br />'
    end
    return s
  end

  #-----------------------------------------------------------------------------
  # возвращает ссылку на контакт
  # если need_title=true, добавляется должность персоны
  def link_to_contact contact, need_title=false
    s = link_to_remote(h(contact.formated_name),
          :url    => contact_path(contact),
          :method => :get,
          :html   => {:class => :link_class})
    s += ', ' + contact.title if need_title and contact.title
    return s
  end

end
