class FeedbackController < ApplicationController

  def create
    message = UserMessage.for_user.new(:text => params[:feedback][:message])
    if message.save and a = params[:attachmend]
      attachmend = Attachmend.for_user.new(a)
      attachmend.owner = message
      attachmend.save
    end
    responds_to_parent do
      render :update do |page|
        page << "feedback.show_message()"
      end
    end
  end

end
