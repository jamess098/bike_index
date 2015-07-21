require 'spec_helper'

describe ApproveStolenListingWorker do
  it { should be_processed_in :notify }

  it "enqueues another awesome job" do
    bike = FactoryGirl.create(:bike)
    ApproveStolenListingWorker.perform_async(bike.id)
    expect(ApproveStolenListingWorker).to have_enqueued_job(bike.id)
  end

  it "calls stolen twitterbot integration" do 
    StolenTwitterbotIntegration.any_instance.should_receive(:send_tweet).with(111)
    ApproveStolenListingWorker.new.perform(111)
  end

end
