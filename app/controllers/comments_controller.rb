class CommentsController < ApplicationController

  before_filter :find_comment, :only => [:update, :destroy]
  before_filter :find_owner

  #-----------------------------------------------------------------------------
  def create
    @comment = @owner.comments.for_user.build(:text => params[:text])
    @comment.save
  end

  #-----------------------------------------------------------------------------
  def destroy
    @comment.destroy if @comment.can_be_deleted
    render :action => :create
  end

  #-----------------------------------------------------------------------------
  def update
    @comment.update_attributes(:text => params[:text]) if @comment.can_be_edited
    render :action => :create
  end


private

  #-----------------------------------------------------------------------------
  def find_comment
    @comment = Comment.find(params[:id])
  end

end
