# Методы пагинации
module Paging

  #-----------------------------------------------------------------------------
  # поиск с пагинацией
  # если передан paging, то будут возвращены записи paging[:from]..paging[:to]
  # и будет рассчитано paging[:pages]
  def pfind paging
    if paging and (r = paging[:recs]) > 0
      c = count
      paging[:pages] = c / r + (c % r == 0 ? 0 : 1)
      find(:all, :offset => paging[:from], :limit => paging[:recs])
    else
      find(:all)
    end
  end

end
