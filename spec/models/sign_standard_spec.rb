require 'rails_helper'

RSpec.describe SignStandard, :type => :model do

  let(:org)                     { build_stubbed(:organization) }
  let(:test_sign_standard)      { build_stubbed(:sign_standard, :smo_code => "sign_spec_test")}
  let(:persisted_sign_standard) { create(:sign_standard) }

  describe 'associations' do
    it 'has many signs' do
      expect(test_sign_standard).to have_many(:signs)
    end
    it 'can have a superseded standard' do
      expect(test_sign_standard).to belong_to(:superseded_by)
    end
    it 'has an asset subtype' do
      expect(test_sign_standard).to belong_to(:asset_subtype)
    end
    it 'has a type' do
      expect(test_sign_standard).to belong_to(:sign_standard_type)
    end
    it 'has many comments' do
      expect(test_sign_standard).to have_many(:comments)
    end
  end

  describe 'validations' do
    it 'should have a SMO code' do
      persisted_sign_standard.smo_code = nil
      expect(persisted_sign_standard).not_to be_valid

      persisted_sign_standard.smo_code = "R-116"
      expect(persisted_sign_standard).to be_valid
    end

    it 'should have a size description' do
      persisted_sign_standard.size_description = nil
      expect(persisted_sign_standard).not_to be_valid

      persisted_sign_standard.size_description = "24 x 36"
      expect(persisted_sign_standard).to be_valid
    end

    it 'should have a sign description' do
      persisted_sign_standard.sign_description = nil
      expect(test_sign_standard).not_to be_valid

      persisted_sign_standard.sign_description = "Railroad crossing sign"
      expect(persisted_sign_standard).to be_valid
    end

    it 'should have an asset subtype' do
      persisted_sign_standard.asset_subtype = nil
      expect(persisted_sign_standard).not_to be_valid

      persisted_sign_standard.asset_subtype_id = 1
      expect(persisted_sign_standard).to be_valid
    end

  end

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  it '#allowable_params' do
    expect(SignStandard.allowable_params).to eq([
      :smo_code,
      :asset_subtype_id,
      :sign_standard_type_id,
      :size_description,
      :sign_description,
      :superseded_by_id,
      :voided_on_date,
      :new_comment,
      :replace_smo,
      :prs_indicator_type_id
    ])
  end
  describe '#active' do
    it 'no voided date' do
      test_standard = create(:sign_standard)
      expect(SignStandard.active).to include(test_standard)
    end
    it 'voided date' do
      test_standard1 = create(:sign_standard, :voided_on_date => Date.today)
      test_standard2 = create(:sign_standard, :voided_on_date => Date.today+1.day)

      expect(SignStandard.active).not_to include(test_standard1)
      expect(SignStandard.active).to include(test_standard2)
    end
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  it '.superseded_smo' do
    current_standard = create(:sign_standard)
    superseded_standard = create(:sign_standard, :superseded_by => current_standard)
    expect(current_standard.superseded_smo).to eq(superseded_standard)
  end
  describe '.deprecated?' do
    it 'should be false by default' do
      expect(test_sign_standard.deprecated?).to be false
    end

    it 'should be true if has superseded_by' do
      test_sign_standard.superseded_by = build_stubbed(:sign_standard)
      expect(test_sign_standard.deprecated?).to be true
    end
  end
  describe '.deleteable?' do
    it 'special' do
      test_sign_standard.smo_code = 'SPECIAL'
      expect(test_sign_standard.deleteable?).to be false
    end
    it 'has signs' do
      create(:sign, :sign_standard => persisted_sign_standard)
      expect(persisted_sign_standard.deleteable?).to be false
    end
    it 'elsewise' do
      expect(test_sign_standard.deleteable?).to be true
    end
  end
  describe '.voided?' do
    it 'no date' do
      expect(test_sign_standard.voided?).to be false
    end
    it 'date' do
      test_sign_standard.voided_on_date = Date.today
      expect(test_sign_standard.voided?).to be true
    end
  end
  it '.one_way_sign?' do
    one_way_standard_type = create(:sign_standard_type, name: "One Way")
    expect(test_sign_standard.one_way_sign?).to be false
    test_sign_standard.sign_standard_type = one_way_standard_type
    expect(test_sign_standard.one_way_sign?).to be true
  end
  it '.legend' do
    expect(test_sign_standard.legend).to eq(test_sign_standard.sign_description)
  end
  it '.to_s' do
    expect(test_sign_standard.to_s).to eq(test_sign_standard.name)
  end
  describe '.description' do
    it 'should be a standard SMO description' do
      expect(test_sign_standard.description).to eq("sign_spec_test  Railroad crossing sign")
    end
  end
  it '.name' do
    expect(test_sign_standard.name).to eq(test_sign_standard.description)
  end
  it '.searchable_fields' do
    expect(test_sign_standard.searchable_fields).to eq([
      :smo_code
    ])
  end

  it '.set_defaults' do
    expect(SignStandard.new.imagepath).to eq(Rails.application.config.missing_sign_image)
  end

end
