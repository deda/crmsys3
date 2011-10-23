class ContactsController < ApplicationController
  before_filter :find_contact,
    :only => [:show, :edit, :update, :destroy, :quick_info, :update_avatar]

  #-----------------------------------------------------------------------------
  @@fields_for_search = [
    'tags.name',
    'formated_name',
    'title',
    'nick_name',
    'rs',
    'inn',
    'kpp',
    'ogrn',
    'company.formated_name',
    'urls.value',
    'phones.value',
    'emails.value',
    'ims.value',
    'comments.text']

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def show
    respond_to do |format|
      format.html {
        before_render
        render :action => :index
      }
      format.js {
        render :action => :show
      }
    end
  end

  #-----------------------------------------------------------------------------
  def edit
    if @contact.can_be_edited
      render 'contacts/edit'
    else
      render :nothing => true
    end
  end

  #-----------------------------------------------------------------------------
  def destroy
    @contact.destroy if @contact.can_be_deleted
    before_render
    render 'contacts/destroy'
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    Contact.visible_for_user.find(params[:contacts_ids]).each { |contact|
      contact.destroy if contact.can_be_deleted
    }
    before_render
    render 'contacts/destroy'
  end

  #-----------------------------------------------------------------------------
  def imexport
    flash[:notice] = nil
  end

  #-----------------------------------------------------------------------------
  def export
    ids = params[:ids] || :all
    ife = Contact.visible_for_user.find(ids)
    if ife.size == 1
      filename = "#{ife[0].formated_name.gsub(/\s/, '_')}"
    else
      filename = "contacts"
    end
    case params[:type]
    when 'vcf'
      contacts = ''
      ife.each{ |c| contacts += c.to_vcf }
      send_data(contacts, :type => "text/plain", :filename => "#{filename}.vcf")
    when 'xml'
      contacts = "<?xml version='1.0' encoding='UTF-8'?>\n<contacts>\n"
      ife.each{ |c| contacts += c.to_xml(:level => 1) }
      contacts += '</contacts>'
      send_data(contacts, :type => "text/xml", :filename => "#{filename}.xml")
    else
      before_render
      render :action => :index
    end
  end

  #-----------------------------------------------------------------------------
  def import
    error = true
    if defined? params[:import][:file]
      file = params[:import][:file]
      ext = File.extname(file.original_path).delete('.').downcase
      open_file = open(file)
      error =
        case ext
        when 'vcf'
          import_vcf(open_file)
        when 'csv'
          import_csv(open_file)
        when 'xml'
          import_xml(open_file)
        else
          I18n::t(:error_type)
        end
    else
      error = I18n::t(:error_empty)
    end
    responds_to_parent do
      if error
        flash[:notice] = error
        render :action => :imexport
      else
        before_render
        render 'contacts/destroy'
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  def quick_info
    as = "#{request.protocol}#{request.host}:#{request.port}/images/"
    ic = QuickInfo::Icon.new(@contact.avatar_url(:s32x32))
    @qi = QuickInfo::Info.new(@contact.formated_name, @contact, ic)
    # телефоны, мыло, веб, аськи
    [:phones, :emails, :urls, :ims, :addresses, :id_cards].each do |items|
      next unless @contact.respond_to?(items)
      f = true
      @contact.send(items).each do |i|
        line = QuickInfo::Line.new(i.to_s)
        if f
          line.icon = QuickInfo::Icon.new("#{as}qi_#{items.to_s}.png", 16, 16)
          f = false
        end
        @qi.lines << line
      end
    end
    render :template => 'shared/quick_info'
  end

  #-----------------------------------------------------------------------------
  # смена авы контакта
  def update_avatar
    if @contact.can_be_edited
      @contact.avatar = Avatar.new(:photo => params[:image][:photo])
    end
    responds_to_parent do
      render :action => :update_avatar
    end
  end


private

  #-----------------------------------------------------------------------------
  def find_contact
    @contact = Contact.visible_for_user.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  def before_render
    # обработка фильтра
    @contacts = nil
    wp = @_search.empty? ? @_paging : nil
    case @_filter[:type]
      when :all
        case @_filter[:id]
          when 0
            @contacts = Person.visible_for_user.pfind(wp)
          when 1
            @contacts = Company.visible_for_user.pfind(wp)
        end
      when :tags
        @contacts = ContactTag.find(@_filter[:id]).owners.visible_for_user.pfind(wp)
      when :recent_records
        case @_filter[:id]
          when 0
            @contacts = Contact.visible_for_user.recently_created.pfind(wp)
          when 1
            @contacts = Contact.visible_for_user.recently_updated.pfind(wp)
        end
    end
    @contacts = Contact.visible_for_user.pfind(wp) unless @contacts
    # обработка поиска
    Search::and_search(@contacts, @@fields_for_search, @_search)
    # обработка пагинации
    unless @_search.empty?
      process_paging(@contacts)
    end
    @contacts.sort!{|a,b| a.formated_name <=> b.formated_name}
  end

  #-----------------------------------------------------------------------------
  def import_vcf file
    begin
      contacts = Vpim::Vcard.decode(file)
    rescue
      return I18n::t(:error_format)
    end
    contacts.each { |c| Contact.from_vcf(c).save }
    return false
  end

  #-----------------------------------------------------------------------------
  def import_xml file
    begin
      contacts = Hash.from_xml(file)['contacts']['contact']
      contacts = [contacts] unless contacts.is_a?(Array)
    rescue
      return I18n::t(:error_format)
    end
    contacts.each { |c| Contact.from_xml(c).save }
    return false
  end

  #-----------------------------------------------------------------------------
  def import_csv file
    begin

      contacts = []

      # список полей, значения которых должны быть коллекцией
      array_fields = [
        :phone,
        :email,
        :url,
        :im,
        :addr,
        :comment,
        :tag]

      # первая строка:
      #   названия полей,
      #   очередность полей,
      #   разделитель полей,
      #   разделитель текста
      fields = file.readline
      # разделитель текста
      if fields =~ /(["|'])/
        tsep = $1
      else
        tsep = ''
      end
      # разделитель полей
      if fields =~ /#{tsep}[a-zA-Z_]+#{tsep}([\t|;|,|.|:])/
        fsep = $1
      else
        raise I18n::t(:error_separator)
      end
      # названия полей в символы
      fields = fields.split(fsep).map do |i|
        if i =~ /^#{tsep}([a-zA-Z_]+)#{tsep}$/
          i = $1
        end
        i.strip.to_sym
      end

      # цикл по остальным строкам
      ln = 0
      file.each do |line|

        # пропустим строку если это комментарий или она пустая
        ln += 1
        next if line[0,1] == '#' or  line[0,2] == "#{tsep}#" or line.strip.blank?

        # получим все значения
        values = values_from_csv(line, tsep, fsep)

        # кол-во значений должно быть = кол-ву полей
        if (vs = values.size) != (fs = fields.size)
          raise I18n::t(:error_string_values_count, :ln => ln, :must => fs, :is => vs)
        end

        # получим хэш: h['поле'] = 'значение' или массив(значений)
        h = {}
        values.each_with_index do |v,i|
          s = v.strip
          next if s.blank?
          k = fields[i]
          if array_fields.include?(k)
            if h[k]
              h[k] << s
            else
              h[k] = [s]
            end
          else
            h[k] = s
          end
        end

        # пропустим строку, если все значения пусты
        next if h.empty?

        # given_name должно быть всегда
        raise I18n::t(:error_string_field_requare, :ln => ln, :field => 'given') unless given_name = h[:given]

        # создаем персону или компанию
        type = h[:type] || '0'
        if type == '1'
          contact = Company.find_or_new({
            :given_name => given_name})
        else
          contact = Person.find_or_new({
            :given_name       => given_name,
            :family_name      => h[:family]||'',
            :additional_name  => h[:additional]||''})
          contact.pref      = h[:pref]
          contact.suff      = h[:suff]
          contact.title     = h[:title]
          contact.bday      = h[:bday]
          contact.nick_name = h[:nick]
          # для персоны создадим компанию, если она указана
          if co = h[:company]
            contact.company = Company.find_or_new({
              :given_name => co})
          end
        end

        h[:phone].each   { |i| contact.phones << Phone.new(:value => i) }
        h[:email].each   { |i| contact.emails << Email.new(:value => i) }
        h[:url].each     { |i| contact.urls << Url.new(:value => i) }
        h[:im].each      { |i| contact.ims << Im.new(:value => i) }
        h[:addr].each    { |i| contact.addresses << Address.new(:street_address => i) }
        h[:comment].each { |i| contact.comments << Comment.for_user.new(:text => i) }

        # теги
        h[:tag].each do |i|
          unless contact.tags.find(:first, :conditions => {:name => i})
            tag = ContactTag.find_or_create(:name => i)
            contact.tags << tag
          end
        end

        contacts << contact
      end

      # сохраняем созданные контакты
      contacts.each{ |c| c.save }

    rescue => err
      return err ? err.to_s : I18n::t(:error_format)
    end
    return false
  end

  #-----------------------------------------------------------------------------
  # возвращает значения полей из csv строки
  # str   - сканируемая строка
  # tsep  - разделитель текста
  # fsep  - разделитель полей
  def values_from_csv str, tsep, fsep
    v = ''
    values = []
    out_of_tsep = true
    inner_tsep = false
    str.each_char do |char|
      case char
        when tsep
          if out_of_tsep
            if inner_tsep
              v += tsep
              inner_tsep = false
            end
            out_of_tsep = false
          else
            inner_tsep = true
            out_of_tsep = true
          end
        when fsep
          if out_of_tsep
            values << v
            v = ''
            inner_tsep = false
          else
            v += fsep
          end
        else
          v += char
      end
    end
    values << v
    return values
  end

end
