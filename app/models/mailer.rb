class Mailer < ActionMailer::Base

  # отправка поставленной задачи ответственному пользователю
  def task_notice task
    recipients  task.recipient.email
    subject     I18n::t(:you_have_new_task)
    body        :task => task
    # у задач нет вложений
    #task.attachmends.each do |a|
    #  attachments[a.object_file_name] = File.read(a.object.path)
    #end if task.attachmends
  end

  # отправка дайджеста пользователю
  def digest user, to, tt
    recipients  user.email
    subject     I18n::t(:your_digest)
    body        :tasks_overdue => to, :tasks_today => tt
  end

end
