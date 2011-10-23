class CrmDigest

  def self.make_users_jobs

    # если запущена другая обработка, выходим
    mutex_file_name = 'crm_digest_working'
    mutex_file = File.new(mutex_file_name, File::CREAT)
    begin
      timeout(1) do
        mutex_file.flock(File::LOCK_EX)
      end
    rescue Timeout::Error
      return
    end

    current_time = Time.now
    begin_of_today = current_time.at_beginning_of_day

    # проверяем необходимость отправки для каждого пользователя
    User.find(:all).each do |user|

      # если не нужно отправлять уведомление - пропускаем этого пользователя
      next if (digest_time = user.settings.digest_time).empty?

      # поместим в dt - во сколько(1) сегодня(2) нужно отправить уведомление
      begin
        digest_time = digest_time.to_time(:local)
        digest_time = begin_of_today + digest_time.hour.hours + digest_time.min.minutes
      rescue
        next
      end

      # время последней отправки
      digest_last = user.settings.digest_last # контрольная точка 1
      digest_last = digest_last.empty? ? nil : digest_last.to_time(:local)

      # если еще ниразу не отправляли или нужна отправка
      if digest_last.nil? or digest_last < digest_time
        user_job = UserDigestJob.new(user.id)
        last_job = Delayed::Job.get(user_job) # контрольная точка 2
        ########################################################################
        # ЗАМЕЧАНИЕ. Если во время между контрольными точками 1 и 2 (КТ)
        # произойдет выполнение задания, то оно будет поставлено в очередь
        # вновь. Т.о. юзер получит два уведомления.
        # ОБЯСНЕНИЕ. Пусть при запросе времени последней отправки (КТ 1)
        # задание еще не выполнено. Тогда digest_last < digest_time и
        # ФИКСИРУЕТСЯ факт необходимости отправки. Допустим, между КТ 1 и 2
        # произошло выполнение задания и тогда оно будет удалено из БД.
        # Тогда при запросе задания из БД (КТ 2) оно не будет найдено и
        # будет поставлено вновь.
        ########################################################################
        job_time = digest_time < current_time ? current_time : digest_time
        # если задача на отправку уже была поставлена ранее
        if last_job
          # если время отправки не изменилось, переходим к сл. пользоватлею
          next if
            last_job.now_working? or
            last_job.run_at == digest_time or
            (last_job.run_at <= current_time and digest_time <= current_time)
          # здесь, если пользователь изменил время своего дайджеста
          # причем, отправка по старому времени еще не производилась
          # меняем время выполнения задачи
          Delayed::Job.requeue(user_job, 0, job_time)
        else
          # ставим задачу на отправку
          Delayed::Job.enqueue(user_job, 0, job_time)
        end
      end

    end # User.find(:all).each

    # освобождаем файл-мьютекс
    mutex_file.flock(File::LOCK_UN)
    File.delete(mutex_file_name)
  end

  #-----------------------------------------------------------------------------
  # задача отправки дайджеста пользователю
  # вызывается delayed_job в то время, когда назначил пользователь
  class UserDigestJob < Struct.new(:user_id)
    def perform
      user = User.find(user_id)
      # отправляем только если есть что отправлять
      tasks = Task.do_group(user.received_tasks)
      to = tasks[:overdue] || []
      tt = tasks[:today] || []
      if to.count + tt.count > 0
        Mailer.deliver_digest(user, to, tt)
      end
      user.settings.digest_last = Time.now
      user.settings.save
    end
  end

end
