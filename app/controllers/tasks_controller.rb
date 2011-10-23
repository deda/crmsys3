class TasksController < ApplicationController

  before_filter :set_appropriate_accept_header, :only => [:show, :new]
  before_filter :get_recipients, :only => [:new, :edit]
  before_filter :find_task, :only =>
    [:show, :edit, :update, :destroy, :accept, :move, :quick_info]
  before_filter :find_owner
  before_filter :find_mass_new_data, :only => [:new, :create, :mass_new]

  #-----------------------------------------------------------------------------
  @@fields_for_search = [
    'tags.name',
    'name',
    'user.name',
    'recipient.name',
    'owner.name',
    'owner.formated_name']

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def show
    respond_to do |format|
      format.html {
        before_render
        render :action => :index
      }
      format.js {
        render :action => :show
      }
    end
  end

  #-----------------------------------------------------------------------------
  def edit
    unless @task.can_be_edited
      render :action => :show
    end
  end

  #-----------------------------------------------------------------------------
  def new
    if @owner
      @task = @owner.tasks.for_user.build(:completion_time => Task.today)
    else
      @task = Task.for_user.build(:completion_time => Task.today)
    end
  end

  #-----------------------------------------------------------------------------
  def mass_new
    before_render
    render :action => :index
  end

  #-----------------------------------------------------------------------------
  def create
    ok = true
    if @mass_new_items.any?
      @mass_new_items.delete_if do |item|
        break if not (ok = create_task_for item)
        true
      end
    else
      ok = create_task_for @owner
    end

    if ok
      before_render
      responds_to_parent do
        render :action => :create
      end
    else
      responds_to_parent do
        render :action => :new
      end
    end
  end

  #-----------------------------------------------------------------------------
  def update
    if @task.can_be_edited
      @task.tags = find_or_build(TaskTag, :tag)
      @task.children = children_from_params(@task)
      if @task.update_attributes(params[:task])
        before_render
        responds_to_parent do
          render :action => :update
        end
      else
        responds_to_parent do
          render :action => :edit
        end
      end
    else
      responds_to_parent do
        render :nothing => true
      end
    end
  end

  #-----------------------------------------------------------------------------
  def destroy
    @task.destroy if @task.can_be_deleted
    before_render
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    Task.find(params[:tasks_ids]).each { |task|
      task.destroy if task.can_be_deleted
    }
    before_render
    render :action => :destroy
  end

  #-----------------------------------------------------------------------------
  def accept
    if @task.can_be_accepted
      @task.completed? ? @task.uncomplete! : @task.complete!
    end
    before_render
    respond_to do |format|
      format.html{}
      format.js
    end
  end

  #-----------------------------------------------------------------------------
  def mass_accept
    @accepted_ids = []
    Task.find(params[:tasks_ids]).each { |task|
      if task.can_be_accepted
        task.completed? ? task.uncomplete! : task.complete!
        @accepted_ids << task.id
      end
    }
    before_render
    respond_to do |format|
      format.html{}
      format.js
    end
  end

  #-----------------------------------------------------------------------------
  def move
    if @task.can_be_deleted
      if @task.move_to(params[:time_binding])
          before_render
      else
        render :nothing => true
      end
    else
      render :nothing => true
    end
  end

  #-----------------------------------------------------------------------------
  def quick_info
    as = "#{request.protocol}#{request.host}:#{request.port}/images/"
    ic = QuickInfo::Icon.new("#{as}48x48_task.png")
    @qi = QuickInfo::Info.new(@task.name, @task, ic)
    @qi.lines << QuickInfo::Line.new(@task.description)
    render :template => 'shared/quick_info'
  end


private

  #-----------------------------------------------------------------------------
  def find_task
    @task = Task.visible_for_user.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  def get_recipients
    @recipients = current_user.account_id ? current_user.account.users : User.all
  end

  #-----------------------------------------------------------------------------
  def before_render
    @filter_recipients = Task.visible_for_user.find(:all, :group => :recipient_id).map{|c|[c.recipient_id,c.recipient.name]}
    # обработка фильтра
    @tasks = nil
    wp = @_search.empty? ? @_paging : nil
    case @_filter[:type]
      when :all
        case @_filter[:id]
          when 0
            @tasks = Task.visible_for_user.wo_parent.nested.pfind(wp)
          when 1
            @tasks = Task.visible_for_user.wo_parent.freed.pfind(wp)
        end
      when :tags
        @tasks = TaskTag.find(@_filter[:id]).owners.wo_parent.visible_for_user.pfind(wp)
      when :recent_records
        case @_filter[:id]
          when 0
            @tasks = Task.visible_for_user.wo_parent.recently_created.pfind(wp)
          when 1
            @tasks = Task.visible_for_user.wo_parent.recently_updated.pfind(wp)
        end
      when :nesteds
        case @_filter[:id]
          when 0
            @tasks = Task.visible_for_user.wo_parent.nested('Contact').pfind(wp)
          when 1
            @tasks = Task.visible_for_user.wo_parent.nested('Sale').pfind(wp)
        end
      when :recipient
        @tasks = Task.visible_for_user.wo_parent.find(:all, :conditions => {:recipient_id => @_filter[:id]})
    end
    @tasks = Task.visible_for_user.wo_parent.pfind(wp) unless @tasks
    # обработка поиска
    Search::and_search(@tasks, @@fields_for_search, @_search)
    # обработка пагинации
    unless @_search.empty?
      process_paging(@tasks)
    end
  end

  #-----------------------------------------------------------------------------
  def find_mass_new_data
    @mass_new_cn    = params[:cn] || ''
    @mass_new_ids   = []
    @mass_new_items = []
    @mass_new_data  = ''

    unless @mass_new_cn.blank?
      begin
        @mass_new_items = Object.const_get(@mass_new_cn.singularize.camelcase).for_account.find(params[:ids])
      rescue
      end
    end
    
    if @mass_new_items.any?
      @mass_new_ids = @mass_new_items.map{ |i| i.id }
      @mass_new_data = "cn=#{@mass_new_cn}"
      @mass_new_ids.each{ |id| @mass_new_data += "&ids[]=#{id}" }
      @mass_new_data = "'#{@mass_new_data}'"
    end
  end

  #-----------------------------------------------------------------------------
  def create_task_for owner
    if owner
      @task = owner.tasks.for_user.build(params[:task])
    else
      @task = Task.for_user.build(params[:task])
    end
    @task.tags = find_or_build(TaskTag, :tag)
    if @task.save
      @task.children = children_from_params(@task)
      Mailer.send_later(:deliver_task_notice, @task) if @task.recipient != @task.user
      return true
    else
      return false
    end
  end

  #-----------------------------------------------------------------------------
  def children_from_params parent
    children = []
    if p=params[:children]
      p.each do |child|
        id = child[:id]
        name = child[:name]
        unless id.blank?
          t = Task.for_account.find(id)
          if name.blank? and t
            t.destroy
            t = nil
          end
        else
          t = Task.for_user.create(
            :owner_id         => parent.owner_id,
            :owner_type       => parent.owner_type,
            :name             => name,
            :completion_time  => parent.completion_time,
            :recipient_id     => parent.recipient_id,
            :completed        => parent.completed,
            :visible          => parent.visible)
        end
        children << t if t
      end
    end
    return children
  end

end
