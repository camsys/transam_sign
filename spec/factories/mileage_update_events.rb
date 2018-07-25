FactoryBot.define do
  factory :mileage_update_event, :class => :mileage_update_event do
    association :asset, factory: :service_vehicle
    current_mileage 100000
  end
end
