class DashboardController < ApplicationController

  def show
    @recent_contacts = Contact.visible_for_user.recent
    @overdue_tasks = Task.visible_for_user.overdue_scope
  end

end
