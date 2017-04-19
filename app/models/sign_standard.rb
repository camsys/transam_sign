#------------------------------------------------------------------------------
#
# SignStandard
#
# SignStandard represents a MUTCD standard sign configuration that is used by
# signs. Each SMO has the following characteristic:
#
#   object_key        --  TransAM identifier
#   smo_code          --  the SMO code eg R-116, SI-134G, etc.
#   size_description  --  A description of the size of the sign eg, "24 x 36". The
#                         size description is normally in inches
#   sign_description  --  A description of the sign text
#   external_id       --  A link to an external system
#   superseded_by_id  --  a foreign key of a SMO that has superseded the current
#                         SMO
#   superseded_date   --  the date that the SMO was superseded
#   voided_on_date    --  the date that the SMO was voided, nil if the SMO is still
#                         active
#
#------------------------------------------------------------------------------
class SignStandard < ActiveRecord::Base

  #-----------------------------------------------------------------------------
  # Behaviors
  #-----------------------------------------------------------------------------
  include TransamObjectKey

  #-----------------------------------------------------------------------------
  # Callbacks
  #-----------------------------------------------------------------------------
  after_initialize  :set_defaults

  #-----------------------------------------------------------------------------
  # Associations
  #-----------------------------------------------------------------------------
  # Every SignStandard can be implemented by 0 or more signs
  has_many    :signs, :class_name => 'Sign'

  # A sign standard can be superceded
  belongs_to  :superseded_by,  :class_name => 'SignStandard',  :foreign_key => :superseded_by_id

  # A sign standard is always associated with an asset subtype
  belongs_to  :asset_subtype

  # A sign standard is always associated with an sign standard type
  belongs_to  :sign_standard_type

  # Has 0 or more comments. Using a polymorphic association, These will be removed if the sign standard is removed
  has_many    :comments,    :as => :commentable,  :dependent => :destroy

  # ----------------------------------------------------
  # Transient Properties
  # ----------------------------------------------------
  attr_accessor :new_comment
  # Identifies the SMO that this SMO will replace
  attr_accessor :replace_smo
  # ----------------------------------------------------
  # Validations
  # ----------------------------------------------------
  before_validation :remove_spaces_from_smo_code
  
  validates   :smo_code,            :length => { :in => 1..16 }, :uniqueness => true
  validates   :size_description,    :length => { :in => 1..16 }
  validates   :sign_description,    :length => { :in => 1..254 }
  validates   :asset_subtype,       :presence => true
  validates   :sign_standard_type,  :presence => true

  #------------------------------------------------------------------------------
  # Lists. These lists are used by derived classes to make up lists of attributes
  # that can be used for operations like full text search etc. Each derived class
  # can add their own fields to the list
  #------------------------------------------------------------------------------

  FORM_PARAMS = [
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
  ]

  SEARCHABLE_FIELDS = [
    :smo_code
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  def self.active
    where('voided_on_date IS NULL OR voided_on_date > ?', Date.today)
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Returns the SMO that this SMO supersedes if there is one
  def superseded_smo
    SignStandard.find_by(:superseded_by_id => id)
  end

  # Returns true if the SMO has been superseded (deprecated)
  def deprecated?
    superseded_by.present?
  end

  # Returns true if the sign standard can be deleted
  def deleteable?
    if smo_code == 'SPECIAL'
      # Can't delete the special code
      false
   elsif signs.exists?
     # Can't delete if there are assets using the code
     false
   else
     true
   end
  end

  # Returns true if the sign has been voided
  def voided?
    if voided_on_date.nil?
      false
    else
      (voided_on_date <= Date.today)
    end
  end

  def one_way_sign?
    (sign_standard_type_id == SignStandardType.where(name: "One Way").pluck(:id).first)
  end

  def reference_line?
    (sign_standard_type_id == SignStandardType.where(name: "Reference Line").pluck(:id).first)
  end
  
  def legend
    sign_description
  end

  # Override default to_s
  def to_s
    name
  end

  # Provide a SMO description
  def description
    if voided?
      "#{smo_code}(Void)  #{sign_description}"
    else
      "#{smo_code}  #{sign_description}"
    end
  end

  # Override the name property
  def name
    description
  end

  def searchable_fields
    SEARCHABLE_FIELDS
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new generic sign
  def set_defaults
    self.imagepath ||= Rails.application.config.missing_sign_image
  end

  def remove_spaces_from_smo_code
    self.smo_code = self.smo_code.gsub(' ', '').strip
  end
end
