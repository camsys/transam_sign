#-------------------------------------------------------------------------------
#
# CrewMember
#
# Map relation that maps a Service Vehicle to a set of 0 or more users (the crew).
#
#-------------------------------------------------------------------------------
class CrewMember < ActiveRecord::Base
  #-----------------------------------------------------------------------------
  # Callbacks
  #-----------------------------------------------------------------------------
  after_initialize  :set_defaults

  #-----------------------------------------------------------------------------
  # Associations
  #-----------------------------------------------------------------------------
  # Every crew member belongs to a service vehicle
  belongs_to  :service_vehicle, :foreign_key => :asset_id

  # Every cre member is a user
  belongs_to  :user

  #-----------------------------------------------------------------------------
  # Scopes
  #-----------------------------------------------------------------------------

  # All crew members who are marked as supervisors
  scope :supervisors, -> { where(:supervisor => true) }
  # All crew members who are not marked as supervisors
  scope :crew, -> { where(:supervisor => false) }

  #-----------------------------------------------------------------------------
  # Validations
  #-----------------------------------------------------------------------------
  validates     :service_vehicle, :presence => true
  validates     :user,            :presence => true

  #-----------------------------------------------------------------------------
  # Constants
  #-----------------------------------------------------------------------------

  # List of allowable form param hash keys
  FORM_PARAMS = [
    :asset_id,
    :user_id
  ]

  #-----------------------------------------------------------------------------
  #
  # Class Methods
  #
  #-----------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  #-----------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #-----------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #-----------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new instance
  def set_defaults

  end
end
