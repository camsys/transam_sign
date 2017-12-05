#------------------------------------------------------------------------------
#
# Sign
#
# Sign asset class. Models a sign asset in the system
#
#------------------------------------------------------------------------------
class Sign < Asset

  # ----------------------------------------------------
  # Behaviors
  # ----------------------------------------------------

  # ----------------------------------------------------
  # Callbacks
  # ----------------------------------------------------
  after_initialize :set_defaults
  before_update   :update_if_was_on_same_support, :except => :create

  # ----------------------------------------------------
  # Associations
  # ----------------------------------------------------
  # Every sign has a sign_standard (SMO)
  belongs_to  :sign_standard

  # Type of sheeting used on the face of the sign
  belongs_to  :sheeting_type

  # Type of backing material
  belongs_to  :blank_type

  # legend color
  belongs_to  :sign_legend_color_type, :class_name => 'ColorType', :foreign_key => :sign_legend_color_type_id

  # background color
  belongs_to  :sign_background_color_type, :class_name => 'ColorType', :foreign_key => :sign_background_color_type_id

  # Type of support
  belongs_to  :support_type

  # Size of the post in inches
  belongs_to  :support_size_type

  # Type of support
  belongs_to  :support_condition_type,  :class_name => 'ConditionType', :foreign_key => :support_condition_type_id

  # Direction of travel with respect to mileposts, markers, etc.
  belongs_to  :travel_direction_type,  :class_name => "DirectionType", :foreign_key => :travel_direction_type_id

  # Compass direction for the face of the sign
  belongs_to  :facing_direction_type,  :class_name => "DirectionType", :foreign_key => :facing_direction_type_id

  # Compass direction for the face of the sign
  belongs_to  :arrow_direction_type,  :class_name => "DirectionType", :foreign_key => :arrow_direction_type_id

  # Side of the road for the sign w/r/t the direction of travel
  belongs_to  :side_of_road_type,      :class_name => "SideType",      :foreign_key => :side_of_road_type_id

  # ----------------------------------------------------
  # Validations
  # ----------------------------------------------------

  validates :sign_standard,               :presence => true
  #validates :sheeting_type,               :presence => true
  #validates :blank_type,                  :presence => true
  #validates :sign_legend_color_type,      :presence => true
  #validates :sign_background_color_type,  :presence => true
  #validates :support_type,                :presence => true
  #validates :support_size_type,           :presence => true
  #validates :travel_direction_type,       :presence => true
  #validates :facing_direction_type,       :presence => true
  #validates :side_of_road_type,           :presence => true

  validates :distance_from_intersection,  :presence => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}
  validates :lateral_offset,              :presence => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}

  validates :street_name,                 :presence => true

  #------------------------------------------------------------------------------
  # Lists. These lists are used by derived classes to make up lists of attributes
  # that can be used for operations like full text search etc. Each derived class
  # can add their own fields to the list
  #------------------------------------------------------------------------------

  SEARCHABLE_FIELDS = [
    :sign_standard,
    :sheeting_type,
    :blank_type,
    :street_name
  ]

  FORM_PARAMS = [
    :sign_standard_id,
    :blank_type_id,
    :sheeting_type_id,
    :sign_legend_color_type_id,
    :sign_background_color_type_id,
    :street_name,
    :lateral_offset,
    :distance_from_intersection,
    :side_of_road_type_id,
    :facing_direction_type_id,
    :travel_direction_type_id,
    :arrow_direction_type_id,
    :support_type_id,
    :support_size_type_id,
    :support_condition_type_id,
    :support_in_service_date
  ]

  CLEANSABLE_FIELDS = [

  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #-----------------------------------------------------------------------------
  def self.allowable_params
    FORM_PARAMS
  end

  def transfer new_organization_id
    org = Organization.where(:id => new_organization_id).first

    transferred_asset = self.copy false
    transferred_asset.object_key = nil

    transferred_asset.disposition_date = nil
    transferred_asset.fta_funding_type = nil
    transferred_asset.fta_ownership_type = FtaOwnershipType.find_by(:name => 'Unknown')
    transferred_asset.in_service_date = nil
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

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Override the age calculation. If a sign has been refaced (rehabilitated) it
  # resets the clock
  def age(on_date=Date.today)
    if last_rehabilitation_date.nil?
      age_in_years = months_in_service(on_date) / 12.0
    else
      age_in_years = months_since_rehabilitation(on_date) / 12.0
    end
    [(age_in_years).floor, 0].max
  end

  def smo
    sign_standard.smo_code unless sign_standard.blank?
  end
  def legend
    sign_standard.sign_description unless sign_standard.blank?
  end
  def size
    sign_standard.size_description unless sign_standard.blank?
  end

  def description
    sign_standard.to_s
  end
  # Install date is modeled as the in-service-date for the sign
  def install_date
    in_service_date
  end

  # Creates a duplicate that has all asset-specific attributes nilled
  def copy(cleanse = true)
    a = dup
    a.cleanse if cleanse
    a
  end

  # Override the name property
  def name
    description
  end

  # override the cost property
  def cost
    purchase_cost
  end

  def searchable_fields
    a = []
    a << super
    SEARCHABLE_FIELDS.each do |field|
      a << field
    end
    a.flatten
  end

  def cleansable_fields
    a = []
    a << super
    CLEANSABLE_FIELDS.each do |field|
      a << field
    end
    a.flatten
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new generic sign
  def set_defaults
    super
    self.distance_from_intersection ||= 0
    self.lateral_offset ||= 0
  end

  # was_on_same_support: flag if current sign's previous support type was SAME
  def update_if_was_on_same_support
    # was_on_same_support: is only updated behind-the-scene as part of sign deleting process
    #   e.g., two signs share same support, first with 'DR' and second with 'SAME', user deleted 'DR' sign,
    #         so second sign support changes from 'SAME' to 'DR', at this moment the system would 
    #         mark :was_on_same_support as true; then if user directly changes the sign support from `DR` 
    #         to anything else, system would reset :was_on_same_support as false.
    self.was_on_same_support = false if self.changes.include?(:support_type_id) && !self.changes.include?(:was_on_same_support)

    # need to make sure always return true, otherwise record wont be saved
    true
  end

end
