# Методы поиска
module Search

  #-----------------------------------------------------------------------------
  # Поиск в массиве из элементов модели
  # На входе: массив элементов модели, массив полей поиска (массив строк),
  #           массив искомых значений (массив строк)
  # На выходе: массив models с элементами, содержащими все искомые значения
  # Метод реализует сл. алгоритм:
  #   1. на первом шаге удаляются все элементы models, неудовлетворяющие первому
  #      условию поиска
  #   2. на втором шаге, из оставшихся элементов в models, удаляются элементы,
  #      неудовлетворяющие второму условию поиска
  #   3. и т.д.
  # Т.о. каждое условие поиска включается по принципу 'AND'
  # Т.е. чем больше искомых значений, тем меньше элементов останется
  def self.and_search models, fields, search
    value_included = false
    search.each do |search_value|
      models.delete_if do |item|
        fields.each do |field|
          value_included = search_include?(item, field, search_value)
          break if value_included
        end
        not value_included
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Вспомогательный метод для поиска. Рекурсивный алгоритм.
  # Возвращает true, если field содержит search
  def self.search_include? models, field, search
    models.to_a.each do |item|
      # если поле составное (например tags.name), вызываем рекурсию
      if i = field.index('.')
        method = :"#{field[0,i]}"
        model = item.respond_to?(method) ? item.send(method) : nil
        return true if model and search_include?(model, [field[i+1..-1]], search)
      # если поле обычное, ищем в нем search_value
      else
        method = :"#{field}"
        v = item.respond_to?(method) ? item.send(method).to_s : nil
        return true if v and v.include?(search)
      end
    end
    return false
  end

end
