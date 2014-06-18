class BikeNotSavedError < StandardError
end

class Admin::BikesController < Admin::BaseController
  before_filter :find_bike, only: [:edit, :destroy, :update]

  def index
    if params[:email]
      bikes = Bike.admin_text_search(params[:email])
    else 
      bikes = Bike.unscoped.order("created_at desc")
    end
    bikes = bikes.paginate(page: params[:page]).per_page(100)
    @bikes = bikes.decorate
  end

  def missing_manufacturer
    bikes = Bike.unscoped.where(manufacturer_id: Manufacturer.find_by_slug('other').id).order('manufacturer_other ASC')
    bikes = bikes.paginate(page: params[:page]).per_page(100)
    @bikes = bikes.decorate
  end

  def update_manufacturers
    if params[:manufacturer_id].present? && params[:bikes_selected].present?
      manufacturer_id = params[:manufacturer_id]
      params[:bikes_selected].keys.each do |bid|
        Bike.find(bid).update_attributes(manufacturer_id: manufacturer_id, manufacturer_other: nil)
      end
      flash[:notice] = 'Success. Bikes updated'
      redirect_to :back and return
    end
    flash[:notice] = 'Sorry, you need to add bikes and a manufacturer'
    redirect_to :back
  end

  def duplicates
    @bike_groups = []
    serials = Bike.all.map(&:serial_number)
    new_ary = serials.select {|item| serials.count(item) > 1}
    new_ary.uniq.each do |serial|
      @bike_groups << Bike.where(serial_number: serial)
    end
  end

  def destroy
    @bike.destroy
    flash[:notice] = "Bike deleted!"
    redirect_to admin_bikes_url
  end

  def show
    redirect_to edit_admin_bike_url
  end

  def edit
    @bike = @bike.decorate
  end

  def update
    BikeUpdator.new(user: current_user, b_params: params).update_ownership
    @bike = @bike.decorate
    if @bike.update_attributes(params[:bike])
      SerialNormalizer.new({serial: @bike.serial_number}).save_segments(@bike.id)
      redirect_to edit_admin_bike_url(@bike), notice: 'Bike was successfully updated.'
    else
      render action: "edit"
    end
  end

  protected

  def find_bike
    @bike = Bike.unscoped.find(params[:id])
  end
end
