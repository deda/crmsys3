class PeopleController < ContactsController

  #-----------------------------------------------------------------------------
  def new
    @contact = Person.for_user.new
    render 'contacts/new'
  end

  #-----------------------------------------------------------------------------
  def create
    avatar = avatar_from_params(:person)
    @contact = Person.for_user.build(params[:person])
    @contact.avatar = avatar
    @contact.company = find_or_build(Company, :company, :given_name)
    @contact.parent = find_or_build(Person, :parent, :given_name)
    @contact.tags = find_or_build(ContactTag, :tag)
    @contact.set_types_for(:addresses, params[:address_type_names])
    @contact.set_types_for(:phones, params[:phone_type_names])
    @contact.set_types_for(:emails, params[:email_type_names])
    @contact.set_types_for(:urls, params[:url_type_names])
    @contact.set_types_for(:ims, params[:im_type_names], params[:im_protocol_names])
    responds_to_parent do
      if @contact.save
        before_render
        render 'contacts/create'
      else
        render 'contacts/new'
      end
    end
  end

  #-----------------------------------------------------------------------------
  def update
    if @contact.can_be_edited
      avatar = avatar_from_params(:person)
      @contact.company = find_or_build(Company, :company, :given_name)
      @contact.parent = find_or_build(Person, :parent, :given_name)
      @contact.tags = find_or_build(ContactTag, :tag)
      responds_to_parent do
        if @contact.update_attributes(params[:person])
          @contact.set_types_for(:addresses, params[:address_type_names])
          @contact.set_types_for(:phones, params[:phone_type_names])
          @contact.set_types_for(:emails, params[:email_type_names])
          @contact.set_types_for(:urls, params[:url_type_names])
          @contact.set_types_for(:ims, params[:im_type_names], params[:im_protocol_names])
          @contact.avatar = avatar if avatar
          before_render
          render 'contacts/update'
        else
          render 'contacts/edit'
        end
      end
    else
      render :nothing => true
    end
  end

end
