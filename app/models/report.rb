module Report

  class Event

    attr_reader :dati, :title, :data, :user

    def initialize dati, title, user, data=[]
      @dati = I18n.l(dati, :format => :long)
      @title = title
      @data = data
      @user = user.is_a?(User) ? user.name : User.find(user).name
    end

  end
  
end
