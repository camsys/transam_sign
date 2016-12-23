require 'rails_helper'

RSpec.describe ServiceVehicle, :type => :model do

  let(:test_service_vehicle)   { build_stubbed(:service_vehicle_with_crew) }

  #------------------------------------------------------------------------------
  #
  # Associations
  #
  #------------------------------------------------------------------------------

  describe 'associations' do
    it 'belongs to an organization' do
      expect(test_service_vehicle).to belong_to(:organization)
    end

    it 'has many mileage updates' do
      expect(test_service_vehicle).to have_many(:mileage_updates)
    end

    it 'has a fuel type' do

    end

    it 'has a title owner' do

    end

    it 'has many features' do

    end

    it 'has many crew members' do
      expect(test_service_vehicle).to have_many(:crew_members)
    end

    it 'has many users' do
      expect(test_service_vehicle).to have_many(:users)
    end

    it 'has many comments' do
      expect(test_service_vehicle).to have_many(:comments)
    end

    it 'has many documents' do
      expect(test_service_vehicle).to have_many(:documents)
    end
  end


  #------------------------------------------------------------------------------
  #
  # Validations
  #
  #------------------------------------------------------------------------------

  describe 'validations' do
    it 'must have an organization' do
      test_service_vehicle.organization = nil
      expect(test_service_vehicle.valid?).to be false
    end

    it 'must have a license plate' do
      test_service_vehicle.license_plate = nil
      expect(test_service_vehicle.valid?).to be false
    end
    describe 'seating capacity' do
      it 'must exist' do
        test_service_vehicle.seating_capacity = nil
        expect(test_service_vehicle.valid?).to be false
      end
      it 'must be an integer' do
        test_service_vehicle.seating_capacity = 2.5
        expect(test_service_vehicle.valid?).to be false
      end
      it 'must be at least one' do
        test_service_vehicle.seating_capacity = 0
        expect(test_service_vehicle.valid?).to be false
      end
    end
    it 'must have a fuel type' do
      test_service_vehicle.fuel_type = nil
      expect(test_service_vehicle.valid?).to be false
    end
    it 'must have a VIN' do
      test_service_vehicle.serial_number = nil
      expect(test_service_vehicle.valid?).to be false
    end
    describe 'gross weight' do
      it 'must be as integer' do
        test_service_vehicle.gross_vehicle_weight = 2.5
        expect(test_service_vehicle.valid?).to be false
      end
      it 'cant be negative' do
        test_service_vehicle.gross_vehicle_weight = -2
        expect(test_service_vehicle.valid?).to be false
      end
    end
    it 'must have a manufacturer' do
      test_service_vehicle.manufacturer = nil
      expect(test_service_vehicle.valid?).to be false
    end
    it 'must have a model' do
      test_service_vehicle.manufacturer_model = nil
      expect(test_service_vehicle.valid?).to be false
    end
    it 'must have a title owner' do
      test_service_vehicle.title_owner = nil
      expect(test_service_vehicle.valid?).to be false
    end
    describe 'length' do
      it 'must exist' do
        test_service_vehicle.vehicle_length = nil
        expect(test_service_vehicle.valid?).to be false
      end
      it 'must be an integer' do
        test_service_vehicle.vehicle_length = 2.5
        expect(test_service_vehicle.valid?).to be false
      end
      it 'must be at least one' do
        test_service_vehicle.vehicle_length = 0
        expect(test_service_vehicle.valid?).to be false
      end
    end
  end

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  it '#allowable_params' do
    expect(ServiceVehicle.allowable_params).to eq([
      :seating_capacity,
      :license_plate,
      :serial_number,
      :crew_size,
      :gross_vehicle_weight,
      :fuel_type_id,
      :title_number,
      :title_owner_organization_id,
      :vehicle_feature_ids => []
    ])
  end
  it '#update_methods' do
    expect(ServiceVehicle.update_methods).to eq([:update_mileage])
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  it 'has a crew' do
    test_service_vehicle = create(:service_vehicle_with_crew)
    test_member = create(:crew_member, :supervisor => false, :service_vehicle => test_service_vehicle)
    expect(test_service_vehicle.crew).to include(test_member.user)
  end
  it 'has a supervisor' do
    expect(test_service_vehicle.supervisor).to eq(test_service_vehicle.crew_members.find_by(:supervisor => true))
  end

  it '.as_json' do
    expect(test_service_vehicle.as_json[:license_plate]).to eq(test_service_vehicle.license_plate)
  end

  it '.searchable_fields' do
    expect(test_service_vehicle.searchable_fields).to include(:license_plate)
    expect(test_service_vehicle.searchable_fields).to include(:serial_number)
  end
  it '.cleansable_fields' do
    expect(test_service_vehicle.cleansable_fields).to include(:license_plate)
    expect(test_service_vehicle.cleansable_fields).to include(:serial_number)
  end
  it '.update_methods' do
    expect(test_service_vehicle.update_methods).to include(:update_mileage)
  end
  it '.update_mileage' do
    test_service_vehicle = create(:service_vehicle)
    test_service_vehicle.mileage_updates.create!(attributes_for(:mileage_update_event))
    test_service_vehicle.update_mileage
    expect(test_service_vehicle.mileage_updates.count).to eql(1)
    test_service_vehicle.reload
    expect(test_service_vehicle.reported_mileage_date).to eql(Date.today)
    expect(test_service_vehicle.reported_mileage).to eql(100000)
  end

  it '.cost' do
    expect(test_service_vehicle.cost).to eq(test_service_vehicle.purchase_cost)
  end

  it '.set_description' do
    expect(create(:service_vehicle).description).to eq("#{test_service_vehicle.manufacturer.code} #{test_service_vehicle.manufacturer_model}")
  end
  it '.set_defaults' do
    test_vehicle = ServiceVehicle.new
    expect(test_vehicle.seating_capacity).to eq(2)
    expect(test_vehicle.vehicle_length).to eq(1)
    expect(test_vehicle.gross_vehicle_weight).to eq(0)
    expect(test_vehicle.crew_size).to eq(2)
    expect(test_vehicle.asset_type).to eq(AssetType.find_by(:class_name => 'ServiceVehicle'))
  end
end
