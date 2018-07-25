FactoryBot.define do
  factory :crew_member do
    association :service_vehicle
    association :user, :factory => :admin
    supervisor true
  end
end
