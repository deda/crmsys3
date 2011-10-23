class Reports::ContactsController < ReportsController

  def problem_clients

    @clients_ts = [] # клиенты без задач и без сделок
    @clients_t  = [] # клиенты без задач
    @clients_s  = [] # клиенты без сделок

    Contact.for_account.all.sort{ |a,b| a.formated_name <=> b.formated_name }.each do |contact|
      data = {
        :contact     => contact,
        :tasks_count => (tc = contact.tasks.count),
        :sales_count => (sc = contact.sales.count)}
      if tc == 0 and sc == 0
        @clients_ts << data
      elsif tc == 0
        @clients_t << data
      elsif sc == 0
        @clients_s << data
      end
    end

  end

end
