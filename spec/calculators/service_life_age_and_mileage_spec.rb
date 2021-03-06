require 'rails_helper'
include FiscalYear

RSpec.describe ServiceLifeAgeAndMileage, :type => :calculator do

  before(:each) do
    @organization = create(:organization)
    @test_asset = create(:service_vehicle, :organization => @organization)
    @policy = create(:policy, :organization => @organization)
    create(:policy_asset_type_rule, :policy => @policy, :asset_type => @test_asset.asset_type)
    create(:policy_asset_subtype_rule, :policy => @policy, :asset_subtype => @test_asset.asset_subtype, :fuel_type_id => @test_asset.fuel_type.id)

    @mileage_update_event = create(:mileage_update_event, :asset => @test_asset, :current_mileage => 100000)

  end

  let(:test_calculator) { ServiceLifeAgeAndMileage.new }

  describe '#calculate' do
    it 'calculates if by mileage is max' do
      # set properties of mileage update event so mileage returned
      @mileage_update_event.current_mileage = @test_asset.policy_analyzer.get_min_service_life_miles + 100
      @mileage_update_event.event_date = '2999-01-01' # set it impossibly late in the future
      @mileage_update_event.save

      expect(test_calculator.calculate(@test_asset)).to eq(test_calculator.send(:by_mileage,@test_asset))
    end

    it 'calculates if by age is max' do
      @mileage_update_event.current_mileage = @test_asset.policy_analyzer.get_min_service_life_miles + 100
      @mileage_update_event.save

      expect(test_calculator.calculate(@test_asset)).to eq(test_calculator.send(:by_age,@test_asset))
    end

    it 'calculates if by age and mileage are equal' do
      @test_asset.update!(:purchased_new => false)
      @mileage_update_event.current_mileage = @test_asset.policy_analyzer.get_min_service_life_miles + 100

      age_yr = test_calculator.send(:by_age,@test_asset)

      date_str = "#{SystemConfig.instance.start_of_fiscal_year}-#{age_yr}"
      start_date = Date.strptime(date_str, "%m-%d-%Y")

      @mileage_update_event.event_date = Date.new(age_yr, @test_asset.in_service_date.month, @test_asset.in_service_date.day)
      @mileage_update_event.event_date = @mileage_update_event.event_date + 1.year if @mileage_update_event.event_date < start_date
      @mileage_update_event.save

      service_life = test_calculator.calculate(@test_asset)
      if_equal_age = service_life == age_yr
      if_equal_mileage = service_life == test_calculator.send(:by_mileage,@test_asset)
      expect(if_equal_age && if_equal_mileage).to be true
    end
  end

  describe '#by_mileage' do
    it 'calculates' do
      @mileage_update_event.current_mileage = @test_asset.policy_analyzer.get_min_service_life_miles + 100
      @mileage_update_event.save
      expect(test_calculator.send(:by_mileage,@test_asset)).to eq(fiscal_year_year_on_date(Date.today))
    end

    it 'calculates if current mileage is max service life miles' do
      @mileage_update_event.current_mileage = @test_asset.policy_analyzer.get_min_service_life_miles
      @mileage_update_event.save
      expect(test_calculator.send(:by_mileage,@test_asset)).to eq(fiscal_year_year_on_date(Date.today))
    end

    it 'is by age if current mileage is less than max service life miles' do
      expect(test_calculator.send(:by_mileage,@test_asset)).to eq(test_calculator.send(:by_age,@test_asset))
    end
  end
end
