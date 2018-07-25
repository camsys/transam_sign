FactoryBot.define do

  factory :service_vehicle do
    association :organization
    asset_type AssetType.find_by(:name => 'Service Vehicle') rescue Rails.logger.info "ERROR: No seed data."
    asset_subtype AssetSubtype.find_by(:name => 'Utility Truck') rescue Rails.logger.info "ERROR: No seed data."
    created_by_id 1
    purchased_new true
    purchase_cost 10000
    purchase_date Date.today - 1.year
    sequence(:asset_tag) { |n| "TRUCK#{n}" }
    fuel_type_id 1
    association :manufacturer
    manufacturer_model "Silverado"
    manufacture_year 2010
    association :title_owner, :factory => :organization
    vehicle_length 20
    expected_useful_life 120
    service_status_type_id 1

    license_plate "LISC123"
    sequence(:serial_number) { |n| "ABCDE#{n}" }

    factory :service_vehicle_with_crew do
      after(:create) do |service_vehicle|
        create(:crew_member, service_vehicle: service_vehicle)
      end
    end
  end

  factory :manufacturer do
    filter 'ServiceVehicle'
    name 'Chevrolet'
    code 'CMD'
    active true
  end

end
