# app/controllers/oauth/applications_controller.rb
class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  include AuthenticationHelper
  helper_method :current_user, :current_organization
  before_filter :authenticate_user!
  before_filter :set_current_user_instance

  def index
    @applications = current_user.oauth_applications
  end

  # only needed if each application must have some owner
  def create
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_user if Doorkeeper.configuration.confirm_application_owner?
    if @application.save
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :create])
       respond_with( :oauth, @application, location: oauth_application_url( @application ) )
    else
      render :new
    end
  end

  def set_current_user_instance
    @current_user = current_user
  end

end