# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do

  sequence :asset_tag do |n|
    "ABS_TAG#{n}"
  end

  trait :basic_asset_attributes do
    association :organization, :factory => :organization
    asset_tag
    purchase_date { 1.year.ago }
    manufacture_year "2000"
    in_service_date Date.new(2001,1,1)
    created_by_id 1
  end

  factory :sign, :class => :sign do
    basic_asset_attributes
    asset_type_id 1
    asset_subtype_id 1
    purchase_cost 2000.0
    association :sign_standard
    sheeting_type_id 1
    blank_type_id 1
    travel_direction_type_id 1
    facing_direction_type_id 1
    side_of_road_type_id 1
    street_name "123 Main St"
    expected_useful_life 120
  end

end
