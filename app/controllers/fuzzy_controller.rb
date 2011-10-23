# Fuzzy-поиск в БД
# Автор: Алексей Карагичев /aakaragichev@yandex.ru/
class FuzzyController < ApplicationController

  #-----------------------------------------------------------------------------
  # Fuzzy-поиск в БД.
  #   params[:models] - где искать (в каких моделях). Список моделей указывается
  #                     через '|'
  #                     пример: 'model1|model2'
  #   params[:fields] - по каким полям искать. Список полей для одной модели
  #                     указывается через ',', поля других моделей указываются
  #                     через '|'. В списке искомых полей не должно быть id.
  #                     В результаты поиска id будет добавлено автоматически в
  #                     начало каждой строки результата
  #                     пример: 'f1,f2|f3'
  #   params[:value]  - что искать. JavaScript должна передать в нижем регистре,
  #                     чтобы меньше нагружать сервер, и еще в Ruby не работает
  #                     downcase для русских букв. если пусто, вернет все строки
  #                     из модели
  #   params[:mfm]    - multi_field_mode. Если = 'true, то в результатах будут
  #                     значения всех искомых полей. Иначе, в результатах будет
  #                     только поле с совпавшим значением.
  #
  # Если нужно вернуть все строки (params[:value] == '') и не задан
  # multi_field_mode (params[:mfm] != 'true'), то в результатах будут значения
  # только первого поля поиска.
  #
  # На выходе дает двумерный массив:
  # [
  #   [id1, value_of_field1, value_of_field2, ...],
  #   [id2, value_of_field1, value_of_field2, ...],
  #   ...
  # ]
  # 
  # Алгоритм:
  # 1. Из БД выбираются указанные поля (а также поле id) всех записей,
  #    принадлежащих данному аккаунту.
  # 2. Для каждого поля, каждой найденной записи применяется fuzzy-функция,
  #    которая рассчитывает "словарное расстояние" между фразой поиска и
  #    значением данного поля.
  # 3. Если расстояние допустимо, то в зависимости от режима в результаты поиска
  #    попадают любо все поля строки любо одно поле. Обработка данной строки
  #    завершена.
  # 4. Переход к следующей строке
  #
  def search

    # результаты поиска
    @result = []

    # в результатах все поля поиска или только совпавшее поле
    @multi_field_mode = params[:mfm] == 'true'

    # искомое значение и его варианты
    @search = params[:value]
    @trans_search = trans @search

    # все записи или поиск
    @all_records = @search.size == 0

    # массив названий моделей
    arr_models = params[:models].
      split('|')

    # массив полей поиска по каждой моделе
    arr_fields = params[:fields].
      delete("()'\"\+- ").
      gsub(/id,|,id/i,'').
      split('|')

    # поиск и заполнение результатов
    arr_models.each_with_index do |model, i|
      add_to_result(model, arr_fields[i])
    end

    # подготовка ответа
    s = ''
    @result.each do |line|
      s += '<div>'
      line.each_with_index do |col,i|
        s += i == 0 ? "<i>#{col}&nbsp;</i>" : "#{col}&nbsp;"
      end
      s += '</div>'
    end

    # rendering
    render :text => s

  end


private

  #-----------------------------------------------------------------------------
  # Ищет @search и его варианты в model_name по полям fields_str и добавляет
  # подходящие результаты в @result
  def add_to_result model_name, fields_str

    # массив из названий полей
    return if fields_str.empty?
    fields_arr = fields_str.split(',').compact

    # подготовим модель, от имени которой будем осуществлять поиск
    begin
      model = Object.const_get(model_name.camelize.singularize)
    rescue
      model = nil
    end
    return if model.nil?

    # подготовка условий поиска
    conditions = ['']
    if @all_records
      fields_str = fields_arr[0] unless @multi_field_mode
    else
      # чтобы сократить объем выборки, будем выбирать поля, длина значений в
      # которых больше либо равна длине искомого значения.
      # строим строку вида:
      # LENGTH(fname1)>=LENGTH(search) OR LENGTH(fname2)>=LENGTH(search) ...
      # нельзя использовать заранее расчитанную длину, ибо кодировка
      fields_str = ''
      fields_arr.each do |field|
        conditions[0] += "LENGTH(#{field})>=LENGTH(?) OR "
        conditions << @search
        fields_str += "LOWER(#{field}) AS #{field},"
      end
      conditions[0] = conditions[0][0..-5]
      fields_str = fields_str[0..-2]
    end

    # здесь добавляем id
    fields_str = 'id,' + fields_str;

    # выборка из БД
    selection = model.for_account.find(
      :all,
      :select => fields_str,
      :conditions => conditions)
    return if selection.empty?

    # по каждой выбранной записи
    selection.each do |item|

      # по каждому выбранному полю
      fields_arr.each do |fname|
        v = item.attributes[fname]

        if @all_records or fuzzy_same(v)
          @result << [item.id]
          i = @result.size - 1
          all_blank = true

          # в результат - значения всех искомых полей
          if @multi_field_mode
            fields_arr.each do |fn|
              v = item.attributes[fn]
              @result[i] << v
              all_blank = false unless v.blank?
            end
          # в результат - значение только совпавшего поля
          else
            unless v.blank?
              @result[i] << v
              all_blank = false
            end
          end

          @result.delete_at(i) if all_blank
          break
        end

      end

    end

  end

  #-----------------------------------------------------------------------------
  # определяет "похожесть" слов
  # возвращает true, если value и @search похожи
  def fuzzy_same value
    return false if !value
    value = value.to_s
    return true if value.index @search
    return true if value.index @trans_search
  end

  #-----------------------------------------------------------------------------
  # транскодирование: DFcz => вася, екФТы => trans
  def trans string
    s = ''
    h = {
      'f' => 'а', 'F' => 'а',
      ',' => 'б', '<' => 'б',
      'd' => 'в', 'D' => 'в',
      'u' => 'г', 'U' => 'г',
      'l' => 'д', 'L' => 'д',
      't' => 'е', 'T' => 'е',
      '`' => 'ё', '~' => 'ё',
      ';' => 'ж', ':' => 'ж',
      'p' => 'з', 'P' => 'з',
      'b' => 'и', 'B' => 'и',
      'q' => 'й', 'Q' => 'й',
      'r' => 'к', 'R' => 'к',
      'k' => 'л', 'K' => 'л',
      'v' => 'м', 'V' => 'м',
      'y' => 'н', 'Y' => 'н',
      'j' => 'о', 'J' => 'о',
      'g' => 'п', 'G' => 'п',
      'h' => 'р', 'H' => 'р',
      'c' => 'с', 'C' => 'с',
      'n' => 'т', 'N' => 'т',
      'e' => 'у', 'E' => 'у',
      'a' => 'ф', 'A' => 'ф',
      '[' => 'х', '{' => 'х',
      'w' => 'ц', 'W' => 'ц',
      'x' => 'ч', 'X' => 'ч',
      'i' => 'ш', 'I' => 'ш',
      'o' => 'щ', 'O' => 'щ',
      'm' => 'ь', 'M' => 'ь',
      's' => 'ы', 'S' => 'ы',
      ']' => 'ъ', '}' => 'ъ',
      "'" => 'э', '"' => 'э',
      '.' => 'ю', '>' => 'ю',
      'z' => 'я', 'Z' => 'я',
      'ф' => 'a', 'Ф' => 'a',
      'и' => 'b', 'И' => 'b',
      'с' => 'c', 'С' => 'c',
      'в' => 'd', 'В' => 'd',
      'у' => 'e', 'У' => 'e',
      'а' => 'f', 'А' => 'f',
      'п' => 'g', 'П' => 'g',
      'р' => 'h', 'Р' => 'h',
      'ш' => 'i', 'Ш' => 'i',
      'о' => 'j', 'О' => 'j',
      'л' => 'k', 'Л' => 'k',
      'д' => 'l', 'Д' => 'l',
      'ь' => 'm', 'Ь' => 'm',
      'т' => 'n', 'Т' => 'n',
      'щ' => 'o', 'Щ' => 'o',
      'з' => 'p', 'З' => 'p',
      'й' => 'q', 'Й' => 'q',
      'к' => 'r', 'К' => 'r',
      'ы' => 's', 'Ы' => 's',
      'е' => 't', 'Е' => 't',
      'г' => 'u', 'Г' => 'u',
      'м' => 'v', 'М' => 'v',
      'ц' => 'w', 'Ц' => 'w',
      'ч' => 'x', 'Ч' => 'x',
      'н' => 'y', 'Н' => 'y',
      'я' => 'z', 'Я' => 'z'}
    string.each_char { |c| (hc = h[c]) ? s += hc : s += c }
    return s
  end

end

#o = [
#  0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,
#  0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,
#  0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F,
#  0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3E,0x3F,
#  0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4A,0x4B,0x4C,0x4D,0x4E,0x4F,
#  0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5A,0x5B,0x5C,0x5D,0x5E,0x5F,
#  0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6E,0x6F,
#  0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7A,0x7B,0x7C,0x7D,0x7E,0x7F,
#  0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8A,0x8B,0x8C,0x8D,0x8E,0x8F,
#  0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9A,0x9B,0x9C,0x9D,0x9E,0x9F,
#  0xA0,0xA1,0xA2,0xA3,0xA4,0xA5,0xA6,0xA7,0xA8,0xA9,0xAA,0xAB,0xAC,0xAD,0xAE,0xAF,
#  0xB0,0xB1,0xB2,0xB3,0xB4,0xB5,0xB6,0xB7,0xB8,0xB9,0xBA,0xBB,0xBC,0xBD,0xBE,0xBF,
#  0xC0,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7,0xC8,0xC9,0xCA,0xCB,0xCC,0xCD,0xCE,0xCF,
#  0xD0,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6,0xD7,0xD8,0xD9,0xDA,0xDB,0xDC,0xDD,0xDE,0xDF,
#  0xE0,0xE1,0xE2,0xE3,0xE4,0xE5,0xE6,0xE7,0xE8,0xE9,0xEA,0xEB,0xEC,0xED,0xEE,0xEF,
#  0xF0,0xF1,0xF2,0xF3,0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0xFA,0xFB,0xFC,0xFD,0xFE,0xFF]
