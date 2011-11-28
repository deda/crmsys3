# Расширение функционала для моделей

<<<<<<< HEAD
require 'active_record' # вот тут разве не надо 'active_record' вместо 'activerecord'? --Alaxender Melnikov
=======
require 'active_record'
>>>>>>> 4199d70f2f26ed8db7cde14dd8ad9d82d524c03c
require 'lib/visibility'

module ModelExtensions

  #-----------------------------------------------------------------------------
  def self.extend_object obj
    # подключение рассчета crc
    obj.before_save :set_crc
  end

  #-----------------------------------------------------------------------------
  # Защищает указанные атрибуты от массового присвоения (вызовом attr_protected)
  # и создает scope для данного атрибута.
  # Например вызов user_protected защитит атрибут user и
  # создаст scope :for_user
  def account_and_user_protected
    account_protected
    user_protected
  end
  def account_protected
    belongs_to :account
    attr_protected :account_id
    validates :account, :presence => true
    # записи данного аккаунта
    scope :for_account, lambda{ |account|
      account ||= $current_account
      {:conditions => account ? {:account_id => account.id} : ''}
    }
  end
  def user_protected
    belongs_to :user
    attr_protected :user_id
    validates :user, :presence => true
    # записи данного пользователя
    scope :for_user, lambda{ |user|
      user ||= $current_user
      conditions = {:user_id => user.id}
      conditions[:account_id] = user.account_id if column_names.include?('account_id')
      {:conditions => conditions}
    }
    # записи, видимые данным пользователем
    scope :visible_for_user, lambda{ |user|
      user ||= $current_user
      if user.is_admin?
        conditions = {:account_id => user.account_id}
      else
        s = 'user_id=?'
        a = [user.id]
        if column_names.include?('recipient_id')
          s += ' OR recipient_id=?'
          a << user.id
        end
        if column_names.include?('visible')
          s += ' OR visible=?'
          a << TRUE
        end
        if column_names.include?('visibility')
          m = name.underscore
          s += " OR visibility=? OR (visibility=? AND (user_id=? OR recipient_id=?)) OR (visibility=? AND (user_id=? OR recipient_id=? OR (SELECT COUNT(*) FROM group_memberships gm WHERE gm.#{m}_id=#{m.pluralize}.id AND gm.user_group_id IN (SELECT gm.user_group_id FROM group_memberships gm WHERE gm.user_id=?)) > 0))"
          a += [
            Visibility::FOR_ALL,
            Visibility::FOR_ME_RECIPIENT,
            user.id,
            user.id,
            Visibility::FOR_ME_RECIPIENT_GROUPS,
            user.id,
            user.id,
            user.id]
        end
        conditions = ["account_id=? AND (#{s})", user.account_id] + a
      end
      {:conditions => conditions}
    }
  end

  #-----------------------------------------------------------------------------
  # Проверка возможности редактирования, удаления, выполнения(завершения) записи
  def can_be_edited user=$current_user
    account_id == user.account_id and (user.is_admin? or user.id == user_id)
  end
  def can_be_deleted user=$current_user
    account_id == user.account_id and (user.is_admin? or user.id == user_id)
  end
  def can_be_accepted user=$current_user
    account_id == user.account_id and (user.is_admin? or user.id == user_id or user.id == recipient_id)
  end

  #-----------------------------------------------------------------------------
  # Блок обработки вложений.
  # Вызов has_many_attachmends объявит в моделе "имение многих вложений" и при
  # сохранении объекта модели к нему будут присоединяться неприсоединенные
  # вложения
  def has_many_attachmends
    has_many :attachmends, :as => :owner, :dependent => :destroy
    after_create :attache_attachmends
    define_method(:attache_attachmends) { Object.const_get(:Attachmend).attache_attachmends_for self }
    define_method(:attachmends) { Object.const_get(:Attachmend).attachmends_for self }
  end

  #-----------------------------------------------------------------------------
  # 1. объявляет "имение многих тэгов через TagsRel с именем класса model"
  # 2. после сохранения владельца тэгов, будут удаляться неиспользованные тэги,
  #    принадлежащие классу владельца (например, все неиспользованные тэги
  #    контактов)
  # Пример использования:
  #   has_many_tags ContactTag
  def has_many_tags model
    has_many :tags_rels, :as => :owner, :dependent => :delete_all
    has_many :tags, :through => :tags_rels, :class_name => model.name
    after_destroy :delete_unused_tags
    after_update :delete_unused_tags
    define_method(:delete_unused_tags) {
      model.delete_all([
        'account_id=? AND id NOT IN (SELECT tag_id FROM tags_rels)',
        $current_account])
    }
  end

  #-----------------------------------------------------------------------------
  # определяет недавно созданные и недавно обновленные записи
  def def_recently_scopes
    # недавно созданные
    scope :recently_created, lambda {
      rc = $current_user.settings.send(:"recent_#{name.underscore}").to_i.days.ago
      {:conditions => ['created_at > ?', rc], :order => :created_at}
    }
    # недавно обновленные
    scope :recently_updated, lambda {
      rc = $current_user.settings.send(:"recent_#{name.underscore}").to_i.days.ago
      {:conditions => ['updated_at > ?', rc], :order => :created_at}
    }
  end

  #-----------------------------------------------------------------------------
  def process_visibility
    has_and_belongs_to_many :contacts
    has_and_belongs_to_many :user_groups, :join_table => :group_memberships
    before_save :correct_visibility
    define_method(:correct_visibility){
      if visibility == Visibility::FOR_ME_RECIPIENT_GROUPS
        if user_groups.empty?
          self.visibility = Visibility::FOR_ME_RECIPIENT
          user_groups.clear
        end
      else
        user_groups.clear
      end
    }
  end

  #-----------------------------------------------------------------------------
  # рассчет и сохранение crc
  def set_crc
    return unless respond_to?(:fields_for_crc)
    self.crc = new_crc
  end
  def new_crc
    s = ''
    fields_for_crc.each { |f| s += (send(f) || 'nil').to_s + '=' }
    return Digest::SHA1.hexdigest(s)
  end
  
  #-----------------------------------------------------------------------------
  def has_one_avatar
    has_one :avatar, :dependent => :destroy, :as => :owner
    class_eval do
      def avatar_url size
        if avatar
          return avatar.photo.url(size)
        else
          size.to_s.match(/(\d+)x(\d+)/i);
          return "/images/#{$1}x#{$2}_#{self.class.name.underscore}.png"
        end
      end
    end
  end

end

ActiveRecord::Base.send(:extend, ModelExtensions)
