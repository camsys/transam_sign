#-------------------------------------------------------------------------------
#
# ServiceVehicle
#
# Implementation class for a Service Vehicle asset
#
#-------------------------------------------------------------------------------
class ServiceVehicle < Asset

  # Include the maintenance asset mixin
  include MaintainableAsset

  # Callbacks
  after_initialize    :set_defaults
  before_validation   :set_description

  # Clean up any HABTM associations before the asset is destroyed
  before_destroy { vehicle_features.clear }

  #-----------------------------------------------------------------------------
  # Associations common to all Service Vehicles
  #-----------------------------------------------------------------------------

  # each asset has zero or more mileage updates. Only for vehicle assets.
  has_many    :mileage_updates, -> {where :asset_event_type_id => MileageUpdateEvent.asset_event_type.id }, :foreign_key => :asset_id, :class_name => "MileageUpdateEvent"

  # each service vehicle has a type of fuel
  belongs_to  :fuel_type

  # each service vehicle's title is owned by an organization
  belongs_to  :title_owner,         :class_name => "Organization", :foreign_key => 'title_owner_organization_id'

  # Each service vehicle has a set (0 or more) of vehicle features
  has_and_belongs_to_many   :vehicle_features,    :foreign_key => 'asset_id'

  # Each service vehicle has a crew that is assigned to it
  has_many    :crew_members,  :foreign_key => :asset_id, :dependent => :destroy

  #-----------------------------------------------------------------------------
  # Service Vehicle Physical Characteristics
  #-----------------------------------------------------------------------------
  validates :license_plate,               :presence => true
  validates :seating_capacity,            :presence => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => 1}
  validates :fuel_type,                   :presence => true
  validates :serial_number,               :presence => true
  validates :gross_vehicle_weight,        :allow_nil => true, :numericality => {:only_integer => true,   :greater_than_or_equal_to => 0}
  validates :manufacturer_id,             :presence => true
  validates :manufacturer_model,          :presence => true
  validates :title_owner_organization_id, :presence => true
  validates :vehicle_length,              :presence => true, :numericality => {:only_integer => true, :greater_than => 0}

  #-----------------------------------------------------------------------------
  # Scopes
  #-----------------------------------------------------------------------------
  # set the default scope
  default_scope { where(:asset_type_id => AssetType.find_by_class_name(self.name).id) }

  #-----------------------------------------------------------------------------
  #
  # Class Methods
  #
  #-----------------------------------------------------------------------------

  def self.allowable_params
    [
      :seating_capacity,
      :license_plate,
      :serial_number,
      :crew_size,
      :gross_vehicle_weight,
      :fuel_type_id,
      :title_number,
      :title_owner_organization_id,
      :vehicle_feature_ids => []
    ]
  end
  def self.update_methods
    [
      :update_mileage
    ]
  end

  #-----------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #-----------------------------------------------------------------------------

  # Crew members not including the supervisor
  def crew
    a = []
    crew_members.crew.each {|x| a << x.user}
    a
  end

  # Returns the crew member who is designated as the supervisor
  def supervisor
    crew_members.supervisors.first.user unless crew_members.supervisors.empty?
  end

  # Render the asset as a JSON object -- overrides the default json encoding
  def as_json(options={})
    super.merge(
    {
      :reported_mileage => self.reported_mileage,
      :crew_size => self.crew_size,
      :seating_capacity => self.seating_capacity,
      :license_plate => self.license_plate,
      :serial_number => self.serial_number,
      :vehicle_length => self.vehicle_length,
      :gross_vehicle_weight => self.gross_vehicle_weight,
      :description => self.description,
      :title_number => self.title_number,
      :title_owner_organization_id => self.title_owner.present? ? self.title_owner.to_s : nil,
      :fuel_type_id => self.fuel_type.present? ? self.fuel_type.to_s : nil
    })
  end


  def seating_capacity=(num)
    self[:seating_capacity] = sanitize_to_int(num)
  end

  # Creates a duplicate that has all asset-specific attributes nilled
  def copy(cleanse = true)
    a = dup
    a.cleanse if cleanse
    a
  end

  def searchable_fields
    a = []
    a << super
    a += [:license_plate,:serial_number]
    a.flatten
  end

  def cleansable_fields
    a = []
    a << super
    a += [:license_plate,:serial_number]
    a.flatten
  end

  def update_methods
    a = []
    a << super
    a += [:update_mileage]
    a.flatten
  end

  # Forces an update of an assets mileage. This performs an update on the record. If a policy is passed
  # that policy is used to update the asset otherwise the default policy is used
  def update_mileage(save_asset = true, policy = nil)

    Rails.logger.info "Updating the recorded mileage method for asset = #{object_key}"

    # can't do this if it is a new record as none of the IDs would be set
    unless new_record?
      # Update the reported mileage
      begin
        if mileage_updates.empty?
          self.reported_mileage = 0
          self.reported_mileage_date = nil
        else
          event = mileage_updates.last
          self.reported_mileage = event.current_mileage
          self.reported_mileage_date = event.event_date
        end
        save if save_asset
      rescue Exception => e
        Rails.logger.warn e.message
      end
    end

  end

  def cost
    purchase_cost
  end

  def transfer new_organization_id
    org = Organization.where(:id => new_organization_id).first

    transferred_asset = self.copy false
    transferred_asset.object_key = nil

    transferred_asset.disposition_date = nil
    transferred_asset.fta_funding_type = nil
    transferred_asset.fta_ownership_type = FtaOwnershipType.find_by(:name => 'Unknown')
    transferred_asset.in_service_date = nil
    transferred_asset.license_plate = nil
    transferred_asset.organization = org
    transferred_asset.purchase_cost = nil
    transferred_asset.purchase_date = nil
    transferred_asset.purchased_new = false
    transferred_asset.service_status_type = nil
    transferred_asset.title_owner_organization = nil

    transferred_asset.generate_object_key(:object_key)
    transferred_asset.asset_tag = transferred_asset.object_key

    transferred_asset.save(:validate => false)
    return transferred_asset
  end

  #-----------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #-----------------------------------------------------------------------------
  protected

  # Set the description field
  def set_description
    self.description = "#{self.manufacturer.code} #{self.manufacturer_model}" unless self.manufacturer.nil?
  end

  # Set resonable defaults for a new service vehicle
  def set_defaults
    super
    self.seating_capacity ||= 2
    self.vehicle_length ||= 1
    self.gross_vehicle_weight ||= 0
    self.crew_size ||= 2
    self.asset_type ||= AssetType.find_by_class_name(self.name)
  end

end
