require 'crm_log'

module CrmLogger

  MAX_VALUE = 100
  EXCLUDED_FIELDS = [
    'id',
    'crc',
    'type',    
    'created_at',
    'updated_at',
    'deleted_at']

  #-----------------------------------------------------------------------------
  module OperType
    CREATE = 0
    UPDATE = 1
    DELETE = 2
    def self.[](i)
      [ I18n.t(:creation), I18n.t(:updating), I18n.t(:deletion) ][i]
    end
  end

  #-----------------------------------------------------------------------------
  def self.extend_object obj
    return if obj.instance_variable_defined?(:@crm_logger_installed)
    obj.after_create(:write_log_create)
    obj.after_update(:write_log_update)
    obj.after_destroy(:write_log_delete)
    obj.instance_variable_set(:@crm_logger_installed, true)
  end


private

  #-----------------------------------------------------------------------------
  def write_log_create
    return if self.is_a?(CrmLog) or not $current_user
    write_log(OperType::CREATE, attributes)
  end

  #-----------------------------------------------------------------------------
  def write_log_update
    return if self.is_a?(CrmLog) or not $current_user
    h = {}
    (attributes.keys & changed_attributes.keys).each{|k| h[k] = attributes[k]}
    write_log(OperType::UPDATE, h)
  end

  #-----------------------------------------------------------------------------
  def write_log_delete
    return if self.is_a?(CrmLog) or not $current_user
    write_log(OperType::DELETE, nil)
  end

  #-----------------------------------------------------------------------------
  def write_log oper_type, attrs

    if attrs
      fields = []
      values = []
      attrs.each_key do |k|
        next if EXCLUDED_FIELDS.include? k
        v = attrs[k].to_s
        if (l = v.length) > MAX_VALUE
          v = "#{v[0, MAX_VALUE]}...(#{l})"
        end
        fields << k
        values << v
      end
      fields = fields.join(',')
      values = values.join(',')
    else
      fields = nil
      values = nil
    end

    return true if fields.blank?

    CrmLog.create(
      :user_id    => $current_user.id,
      :account_id => $current_account.id,
      :record_id  => id,
      :oper_type  => oper_type,
      :object     => self.class.name,
      :fields     => fields,
      :values     => values,
      :dati       => Time.now)

  end

end

ActiveRecord::Base.send(:extend, CrmLogger)