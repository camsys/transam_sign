FactoryBot.define do

  factory :sign_standard do
    asset_subtype_id 1
    sequence(:smo_code) { |n| "R-116_#{n}" }
    size_description '24 x 36'
    sign_description 'Railroad crossing sign'
    association :sign_standard_type
  end

end
