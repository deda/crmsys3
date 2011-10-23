module QuickInfo

  #-----------------------------------------------------------------------------
  class Icon
    attr_accessor :url
    attr_accessor :width
    attr_accessor :height
    def initialize u, w=32, h=32
      @url    = u
      @width  = w
      @height = h
    end
    def img_tag
      "<img src='#{@url}' />"
    end
  end

  #-----------------------------------------------------------------------------
  class Line
    attr_accessor :icon
    attr_accessor :data
    def initialize d, i=nil
      @data = d
      @icon = i
    end
  end

  #-----------------------------------------------------------------------------
  class Info
    attr_accessor :icon
    attr_accessor :name
    attr_accessor :lines
    attr_accessor :item
    attr_reader   :html_id
    attr_reader   :item_path
    def initialize n, it, ic=nil
      @name = n
      @icon = ic
      @lines = []
      self.item = it
    end
    def item= i
      @item = i
      @html_id = "qi_#{i.class.base_class.name.underscore}_#{i.id}"
      @item_path = "/#{i.class.base_class.name.underscore.pluralize}/#{i.id}"
    end
    def lines
      @lines.delete_if { |l| l.nil? or l.data.blank? }
    end
  end

end
