require 'spec_helper'

describe BikeSearcher do

  describe :initialize do
    it 'deletes the serial gsub expression if it is present' do
      params = { query: 'm_940%2Cs%23sdfc%23%2Cc_1' }
      searcher = BikeSearcher.new(params)
      expect(searcher.params[:serial]).to eq('sdfc')
      expect(searcher.params[:query]).to eq('m_940%2C%2Cc_1')
    end
  end

  describe 'search selectize options' do
    it 'returns the selectized items if passed through the expected things' do
      manufacturer = FactoryGirl.create(:manufacturer)
      color_1 = FactoryGirl.create(:color)
      color_2 = FactoryGirl.create(:color)
      params = { query: "c_#{color_1.id},c_#{color_2.id}%2Cm_#{manufacturer.id}%2Csomething+cool%2Cs%238xcvxcvcx%23" }
      searcher = BikeSearcher.new(params)
      searcher.matching_manufacturer(Bike.scoped)
      searcher.matching_colors(Bike.scoped)
      opts = 
      target = [
        manufacturer.autocomplete_result_hash,
        color_1.autocomplete_result_hash,
        color_2.autocomplete_result_hash,
        { id: 'serial', search_id: "s#8xcvxcvcx#", text: '8xcvxcvcx' },
        { text: 'something+cool', search_id: 'something+cool'}
      ].as_json
      result = searcher.selectize_items
      expect(result).to eq target
      result.each { |t| expect(target.include?(t)).to be_true }
      target.each { |t| expect(result.include?(t)).to be_true }
    end
  end

  describe :find_bikes do 
    it "calls select manufacturers, attributes, stolen and query if stolen is present" do 
      search = BikeSearcher.new(stolen: true)
      search.should_receive(:matching_serial).and_return(Bike)
      search.should_receive(:matching_stolenness).and_return(Bike)
      search.should_receive(:matching_manufacturer).and_return(Bike)
      # search.should_receive(:matching_attr_cache).and_return(true)
      search.should_receive(:matching_query).and_return(Bike)
      search.find_bikes
    end
    it "does not fail if nothing is present" do 
      search = BikeSearcher.new
      search.find_bikes.should_not be_present
    end
  end

  describe :matching_serial do 
    it "finds matching bikes" do 
      bike = FactoryGirl.create(:bike, serial_number: 'st00d-ffer')
      search = BikeSearcher.new(serial: 'STood ffer')
      search.matching_serial.first.should eq(bike)
    end
    it "finds matching bikes" do 
      bike = FactoryGirl.create(:bike, serial_number: 'st00d-ffer')
      search = BikeSearcher.new(serial: 'STood')
      search.matching_serial.first.should eq(bike)
    end
    it "finds bikes with absent serials" do 
      bike = FactoryGirl.create(:bike, serial_number: 'absent')
      search = BikeSearcher.new(serial: 'absent')
      search.matching_serial.first.should eq(bike)
    end
    it "fulls text search" do 
      bike = FactoryGirl.create(:bike, serial_number: 'K10DY00047-bkd')
      search = BikeSearcher.new(serial: 'bkd-K1oDYooo47')
      search.matching_serial.first.should eq(bike)
    end
  end

  describe :matching_manufacturer do 
    it "finds matching bikes from manufacturer without id" do 
      manufacturer = FactoryGirl.create(:manufacturer, name: 'Special bikes co.')
      bike = FactoryGirl.create(:bike, manufacturer: manufacturer)
      bike2 = FactoryGirl.create(:bike)
      search = BikeSearcher.new(manufacturer: 'Special', query: "")
      search.matching_manufacturer(Bike.scoped).first.should eq(bike)
      search.matching_manufacturer(Bike.scoped).pluck(:id).include?(bike2.id).should be_false
    end

    it "does not return any bikes if we can't find the manufacturer" do 
      manufacturer = FactoryGirl.create(:manufacturer, name: 'Special bikes co.')
      bike = FactoryGirl.create(:bike, manufacturer: manufacturer)
      search = BikeSearcher.new(manufacturer: '69696969', query: "")
      search.matching_manufacturer(Bike.scoped).count.should eq(0)
    end

    it "finds matching bikes" do 
      bike = FactoryGirl.create(:bike)
      search = BikeSearcher.new(manufacturer_id: bike.manufacturer_id, query: "something")
      search.matching_manufacturer(Bike.scoped).first.should eq(bike)
    end
  end

  describe 'matching_colors' do 
    it "finds matching colors" do
      color = FactoryGirl.create(:color)
      bike = FactoryGirl.create(:bike, tertiary_frame_color_id: color.id)
      FactoryGirl.create(:bike)
      search = BikeSearcher.new({colors: "something, #{color.name}"}).matching_colors(Bike.scoped)
      search.count.should eq(1)
      search.first.should eq(bike)
    end
  end

  describe :fuzzy_find_serial do 
    it "finds matching serial segments" do 
      bike = FactoryGirl.create(:bike, serial_number: 'st00d-fferd')
      bike.create_normalized_serial_segments
      bike.normalized_serial_segments
      search = BikeSearcher.new(serial: 'fferds')
      result = search.fuzzy_find_serial
      result.first.should eq(bike)
      result.count.should eq(1)
    end
    it "doesn't find exact matches" do 
      bike = FactoryGirl.create(:bike, serial_number: 'K10DY00047-bkd')
      search = BikeSearcher.new(serial: 'bkd-K1oDYooo47')
      search.fuzzy_find_serial.should be_empty
    end
  end

  describe :matching_stolenness do 
    before :each do 
      @non_stolen = FactoryGirl.create(:bike)
      @stolen = FactoryGirl.create(:bike, stolen: true)
    end
    it "selects only stolen bikes if non-stolen isn't selected" do 
      search = BikeSearcher.new({stolen: "on"})
      result = search.matching_stolenness(Bike.scoped)
      result.should eq([@stolen])
    end
    it "selects only non-stolen bikes if stolen isn't selected" do 
      search = BikeSearcher.new({non_stolen: "on"})
      result = search.matching_stolenness(Bike.scoped)
      result.should eq([@non_stolen])
    end
    it "returns all bikes" do 
      search = BikeSearcher.new.matching_stolenness(Bike.scoped)
      search.should eq(Bike.scoped)
    end
  end

  describe :matching_query do 
     it "selects bikes matching the attribute" do 
       search = BikeSearcher.new({query: "something"})
       bikes = Bike.scoped
       bikes.should_receive(:text_search).and_return("booger")
       search.matching_query(bikes).should eq("booger")
     end
   end

end
