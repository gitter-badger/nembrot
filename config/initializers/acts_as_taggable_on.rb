ActsAsTaggableOn.remove_unused_tags = true

ActsAsTaggableOn::Tag.class_eval do

  attr_accessor :diff_status, :obsolete

  default_scope :order => 'slug'

  def to_param
    slug
  end

	extend FriendlyId
		friendly_id :name, use: :slugged
end
