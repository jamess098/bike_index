require 'spec_helper'

describe Api::V1::BikesController do
  
  describe :index do
    it "should load the page and have the correct headers" do
      FactoryGirl.create(:bike)
      get :index, format: :json
      response.code.should eq('200')
    end
  end

  describe :show do
    it "should load the page" do
      bike = FactoryGirl.create(:bike)
      get :show, id: bike.id, format: :json
      response.code.should eq("200")
    end
  end

  describe :create do 
    before :each do
      @organization = FactoryGirl.create(:organization)
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:membership, user: user, organization: @organization)
      @organization.save
      FactoryGirl.create(:cycle_type, name: "Bike")
      FactoryGirl.create(:propulsion_type, name: "Foot pedal")
    end

    it "should return correct code if not logged in" do 
      c = FactoryGirl.create(:color)
      post :create, { :bike => { serial_number: '69', color: c.name } }
      response.code.should eq("401")
    end

    it "should return correct code if bike has errors" do 
      c = FactoryGirl.create(:color)
      post :create, { :bike => { serial_number: '69', color: c.name }, organization_slug: @organization.slug, access_token: @organization.access_token }
      response.code.should eq("422")
    end

    it "should email us if it can't create a record" do 
      c = FactoryGirl.create(:color)
      lambda {
        post :create, { :bike => { serial_number: '69', color: c.name }, organization_slug: @organization.slug, access_token: @organization.access_token }
      }.should change(Feedback, :count).by(1)
    end

    it "should create a record and not email us" do
      manufacturer = FactoryGirl.create(:manufacturer)
      f_count = Feedback.count
      bike = { serial_number: "69",
        cycle_type_id: FactoryGirl.create(:cycle_type).id,
        manufacturer_id: manufacturer.id,
        rear_tire_narrow: "true",
        rear_wheel_size_id: FactoryGirl.create(:wheel_size).id,
        primary_frame_color_id: FactoryGirl.create(:color).id,
        handlebar_type_id: FactoryGirl.create(:handlebar_type).id,
        owner_email: "fun_times@examples.com"
      }
      OwnershipCreator.any_instance.should_receive(:send_notification_email)
      lambda { 
        post :create, { bike: bike, organization_slug: @organization.slug, access_token: @organization.access_token }
      }.should change(Ownership, :count).by(1)
      response.code.should eq("200")
      Bike.last.creation_organization_id.should eq(@organization.id)
      f_count.should eq(Feedback.count)
    end

    it "should create an example bike if the bike is from example" do
      org = FactoryGirl.create(:organization, name: "Example organization")
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:membership, user: user, organization: org)
      manufacturer = FactoryGirl.create(:manufacturer)
      org.save
      bike = { serial_number: "69 example bike",
        cycle_type_id: FactoryGirl.create(:cycle_type).id,
        manufacturer_id: manufacturer.id,
        rear_tire_narrow: "true",
        rear_wheel_size_id: FactoryGirl.create(:wheel_size).id,
        primary_frame_color_id: FactoryGirl.create(:color).id,
        handlebar_type_id: FactoryGirl.create(:handlebar_type).id,
        owner_email: "fun_times@examples.com"
      }
      Resque.should_not_receive(:enqueue).with(OwnershipInvitationEmailJob, 1)
      lambda { 
        post :create, { bike: bike, organization_slug: org.slug, access_token: org.access_token }
      }.should change(Ownership, :count).by(1)
      response.code.should eq("200")
      Bike.unscoped.where(serial_number: "69 example bike").first.example.should be_true
    end
  end
    
end
