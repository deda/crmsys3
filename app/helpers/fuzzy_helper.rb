module FuzzyHelper

  # Рендерит поле ввода/выбора с Fuzzy поиском
  # Параметры:
  #   object  - экземпляр текущей модели
  #   method  - поле модели для которой ввод
  #   models  - модели поиска (через "|")
  #   fields  - поля поиска (через "," для модели, через "|" по моделям)
  #   name    - атрибут name для fuzzy-input
  #   id_name - атрибут name для input, содержащего id выбранной записи
  #   prompt  - приглашение к вводу
  #   value   - атрибут value для fuzzy-input
  #   on_sel   - JavaScript-функция, которая будет вызвана после выбора одного
  #             из найденных вариантов. в функцию первым параметром передается
  #             массив вида: [id,f1,f2...]. где:
  #             id      - id из БД найденной записи
  #             f1..fn  - значения заданных полей поиска
  #   mfm     - multi_field_mode - если задан, то в результатах будут значения
  #             всех полей поиска, иначе, значение только совпавшего поля (если
  #             выводится список по поиску) или только первое поле (если
  #             выводится весь список)
  #   label   - название перед полем ввода
  #
  # Допустимы сл. комбинации параметров object, method, models, fields:
  #   1a object  1b object
  #      method     method
  #      models     ------
  #      fields     fields
  #
  #   2a object  2b object
  #      method     method
  #      models     ------
  #      ------     ------
  #
  #   3a object  3b object
  #      ------     ------
  #      models     ------
  #      fields     fields
  #
  #   4  ------
  #      ------
  #      models
  #      fields
  #
  # Правила вычисления недостающих параметров:
  #   1* Задан параметр fields
  #      models     ||= <method>
  #      id_name    ||= <method>[id]
  #      input_name ||= <method>[<fields>]
  #      value      ||= <object.method.fields>
  #      item_id      = object.method.id
  #
  #   2* Параметр fields не задан
  #      models     ||= <object.class_name>
  #      fields     ||= <method>
  #      id_name    ||= <models>[id]
  #      input_name ||= <models>[<fields>]
  #      value      ||= <object.method>
  #      item_id      = object.id
  #
  #   3* Параметр method не задан при заданных object и fields
  #      models     ||= <object.class_name>
  #      id_name    ||= <models>[id]
  #      input_name ||= <models>[<fields>]
  #      value      ||= <object.method.fields>
  #      item_id      = object.id
  #
  #   4  Параметры object и method не заданы. Чистый поиск строки.
  #      id_name      = nil
  #      input_name ||= <models>[<fields>]
  #
  def self.input_tag options

    # инициализация
    object = options[:object]
    method = options[:method]
    models = options[:models]
    fields = options[:fields]
    prompt = options[:prompt]
    value  = options[:value] || ''
    name   = options[:name]
    on_sel = options[:on_sel]
    mfm    = options[:mfm] ? 'true' : 'false'
    label  = options[:label]

    models = models.underscore if models
    fields = fields.underscore.delete("()'\"\+- ").gsub(/id,|,id/i,'') if fields

    if object

      item_id = ''
      object_s = object.class.name.underscore
      need_browse = true

      if method
        method_s = method.to_s.underscore
        item = object.send(method)
      else
        method_s = models
        item = object
      end

      # заполнение value и item_id
      if fields

        if models and models.index('|')
          if item
            item_type = item.attributes['type']
            fields_index =
              models.
              split('|').
              map{|e| e.camelcase}.
              index(item_type ? item_type : item.class.name)
            work_fields = fields.split('|')[fields_index] if fields_index
          end
        else
          models ||= method_s
          work_fields = fields
        end

        if item and work_fields
          value = ''
          work_fields.split(',').each do |f|
            if s = item.send(f)
              value += s + ' '
            end
          end
          item_id = item.id
        end

        name = generate_input_name(method_s, fields) unless name
        id_name = generate_id_name(options, method_s)

      else

        models ||= object_s
        fields = method_s
        if item
          value = item.to_s
          item_id = object.id
        end
        id_name = generate_id_name(options, models)

      end

      # обработка ошибок
      if object.respond_to?(:errors) and not object.errors[method].blank?
        error = object.errors.on(method)
      else
        error = nil
      end

    else

      error = false
      need_browse = false
      id_name = nil

    end

    value.strip!
    name = generate_input_name(models, fields) unless name
    params = "this,'#{models}','#{fields}','#{on_sel}',#{mfm}"

    s = ''
    if label
      s += "<label class='fuzzy_label'>#{label}</label>"
      labeled = ' labeled'
    else
      labeled = ''
    end
    s += "<input class='fuzzy_query#{' error' if error}' type='text' name='#{name}' autocomplete='off' value='#{value}' onfocus=\"fuzzy.init(#{params})\" />"
    s += "<div class='fuzzy_browse' onclick=\"fuzzy.browse(#{params})\">&#9662;</div>" if need_browse
    s += "<div class='fuzzy_result'></div>"
    s += "<input class='fuzzy_id' type='hidden' name='#{id_name}' value='#{item_id}' />" if id_name
    s += "<p class='fuzzy_prompt#{labeled}'>#{prompt}</p>" if prompt
    s += "<p class='fuzzy_error#{labeled}'>#{error}</p>" if error

    return "<div class='fuzzy_wrapper'>#{s}</div>"

  end

  def self.generate_input_name prefix, fields
    "#{prefix}[#{fields.gsub(',','_')}]"
  end

  def self.generate_id_name options, prefix
    options.has_key?(:id_name) ? options[:id_name] : "#{prefix}[id]"
  end

end
