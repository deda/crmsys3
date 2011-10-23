module Settings

  #-----------------------------------------------------------------------------
  # возвращает настройки для данного объекта
  def settings
    @settings ||= Settings.const_get(:"#{self.class.name}Settings").new self
  end

  #-----------------------------------------------------------------------------
  # общий функционал для любых настроек
  class ClassSettings

    #---------------------------------------------------------------------------
    # получение/установка значения одной настройки
    def method_missing *args
      name  = args[0]
      value = args[1].to_s
      case args.size

      # получение значения
      when 1
        begin
          @settings[name][:value]
        rescue
          raise "#{self.class.name}.#{name} not found"
        end

      # установка значения
      when 2
        begin
          name.to_s.match(/^(\w+)(.+)$/i)
          name = $1.to_sym
          oper = $2
          case oper
          when '='
            @settings[name][:value] = value
          else
            raise "Не допустимая для настроек операция #{oper}"
          end
        rescue
          raise "Настройка #{self.class.name}.#{name} не определена"
        end

      # что-то не так
      else
        raise "Неверное кол-во аргументов"

      end
    end

    #---------------------------------------------------------------------------
    # возвращает true, если value было загружено из БД, а не создано вновь
    # (как new_record?, только наоборот)
    def loaded? name
      return false if not @settings[name] or not @settings[name][:id]
      return true
    end

    private

    def get_value record, default_value
        return default_value unless record
        ret = {:id => record.id}
        if default_value[:type] == :bool
          if not record.value or record.value == 'false' or record.value == '0'
            ret[:value] = false
          else
            ret[:value] = true
          end
        else
          ret[:value] = record.value
        end
        return ret
      end

  end

  #-----------------------------------------------------------------------------
  # настройки аккаунта
  class AccountSettings < ClassSettings

    # указываются все настройки со значениями по умолчанию
    @@_settings = {
      :locale      => {:value => 'ru', :id => nil},
      # вкрутка тарифных планов: три настройки ниже идут лесом
      :commodities => {:value => nil,  :id => nil, :type => :bool},
      :cases       => {:value => nil,  :id => nil, :type => :bool},
      :projects    => {:value => nil,  :id => nil, :type => :bool}
    }

    #---------------------------------------------------------------------------
    def initialize account
      @account = account
      @user = account.admins.first
      read
    end

    #---------------------------------------------------------------------------
    # сохранение настроек в базу
    # возвращает ture в случае успеха, иначе false
    def save
      @settings.each_key do |k|
        id = @settings[k][:id]
        vl = @settings[k][:value]
        nm = k.to_s
        if id
          ok = AccountSetting.for_user(@user).update(id, :value => vl)
        else
          ok = AccountSetting.for_user(@user).create(:name => nm, :value => vl)
        end
        return false if not ok
      end
      return true
    end

    #---------------------------------------------------------------------------
    # загрузка настроек из базы
    def read
      @settings = {}
      @@_settings.each_key do |k|
        r = AccountSetting.for_account(@account).find(:first, :conditions => {:name => k.to_s})
        @settings[k] = get_value(r, @@_settings[k])
      end
    end

  end

  #-----------------------------------------------------------------------------
  # настройки пользователя
  class UserSettings < ClassSettings

    # указываются все настройки со значениями по умолчанию
    @@_settings = {
      :locale         => {:value => 'ru', :id => nil},
      :scheme         => {:value => '0',  :id => nil},
      :digest_time    => {:value => '',   :id => nil},
      :digest_last    => {:value => '',   :id => nil},
      :recs_per_page  => {:value => '10', :id => nil},
      :recent_contact => {:value => '7',  :id => nil},
      :recent_task    => {:value => '7',  :id => nil},
      :recent_sale    => {:value => '7',  :id => nil},
      :recent_case    => {:value => '7',  :id => nil},
    }

    #---------------------------------------------------------------------------
    def initialize user
      @user = user
      read
    end

    #---------------------------------------------------------------------------
    # сохранение настроек в базу
    # возвращает ture в случае успеха, иначе false
    def save
      @settings.each_key do |k|
        id = @settings[k][:id]
        vl = @settings[k][:value]
        nm = k.to_s
        if id
          ok = UserSetting.for_user(@user).update(id, :value => vl)
        else
          ok = UserSetting.for_user(@user).create(:name => nm, :value => vl)
        end
        return false if not ok
      end
      return true
    end

    #---------------------------------------------------------------------------
    # загрузка настроек из базы
    def read
      @settings = {}
      @@_settings.each_key do |k|
        r = UserSetting.for_user(@user).find(:first, :conditions => {:name => k.to_s})
        @settings[k] = get_value(r, @@_settings[k])
      end
    end

  end

end

#-------------------------------------------------------------------------------
# классы одиночных настроек вынесены сюда, чтобы ActiveRecord при сохранении
# не устанавливала в type значение навроде Settings::UserSettings::UserSetting,
# а устанавливала просто UserSetting

# одна настройка пользователя
class UserSetting < Type
end

# одна настройка аккаунта
class AccountSetting < Type
end