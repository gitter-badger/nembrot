# encoding: utf-8

class Resource < ActiveRecord::Base

  include Evernotable
  include Syncable

  belongs_to :note

  scope :attached_images, -> { where('mime LIKE ? AND dirty = ?', 'image%', false).where(attachment: nil).where('width > ?', Setting['style.images_min_width'].to_i) }
  scope :attached_files, -> { where('mime = ? AND dirty = ?', 'application/pdf', false) }

  validates_presence_of :cloud_resource_identifier, :note
  validates_uniqueness_of :cloud_resource_identifier, scope: :note_id

  validates_associated :note

  before_validation :make_local_file_name
  before_destroy :delete_binaries

  def self.sync_all_binaries
    need_syncdown.each { |resource| resource.sync_binary }
  end

  def sync_binary
    unless File.file?(raw_location)
      increment_attempts
      Constant.stream_binaries ? stream_binary : download_binary
      # Check that the resource has been downloaded correctly. If so, unflag it.
      undirtify if Digest::MD5.file(raw_location).digest == data_hash
    end
  end

  def stream_binary
    require 'net/http'
    require 'uri'

    uri = URI.parse("#{ evernote_auth.url_prefix }/res/#{ cloud_resource_identifier }")
    connection = Net::HTTP.new(uri.host)
    connection.use_ssl = true if uri.scheme == 'https'

    connection.start do |http|
      response = connection.post_form(uri.path, { 'auth' => oauth_token })
      File.open(raw_location, 'wb') do |file|
        file.write(response.body)
      end
    end
  end

  def download_binary
    # This way the whole file is downloaded into memory -
    #  see http://dev.evernote.com/start/core/resources.php#downloading
    cloud_resource_data = note_store.getResourceData(oauth_token, cloud_resource_identifier)
    File.open(raw_location, 'wb') do |file|
      file.write(cloud_resource_data)
    end
  end

  def evernote_auth
    EvernoteNote.find_by_note_id(note.id).evernote_auth
  end

  def file_ext
    (Mime::Type.file_extension_of mime).parameterize
  end

  def raw_location
    File.join(Rails.root, 'public', 'resources', 'raw', "#{ mime == 'application/pdf' ? local_file_name : id }.#{ file_ext }")
  end

  def template_location(aspect_x, aspect_y)
    File.join(Rails.root, 'public', 'resources', 'templates', "#{ id }-#{ aspect_x }-#{ aspect_y }.#{ file_ext }")
  end

  def cut_location(aspect_x, aspect_y, width, snap, gravity, effects = '0')
    File.join(Rails.root, 'public', 'resources', 'cut', "#{ local_file_name }-#{ aspect_x }-#{ aspect_y }-#{ width }-#{ snap }-#{ gravity }-#{ effects }-#{ id }.#{ file_ext }")
  end

  def blank_location
    File.join(Rails.root, 'public', 'resources', 'cut', "blank.#{ file_ext }")
  end

  def gmaps4rails_title
    caption
  end

  # private

  def make_local_file_name
    if mime && mime !~ /image/
      new_name = File.basename(file_name, File.extname(file_name))
    elsif caption && !caption[/[a-zA-Z\-]{5,}/].blank? # Ensure caption is in Latin script and at least 5 characters
      new_name = caption[0..Setting['style.images_name_length'].to_i]
    elsif description && !description[/[a-zA-Z\-]{5,}/].blank?
      new_name = description[0..Setting['style.images_name_length'].to_i]
    elsif file_name && !file_name.empty?
      new_name = File.basename(file_name, File.extname(file_name))
    end
    new_name = cloud_resource_identifier if new_name.blank?
    self.local_file_name = new_name.parameterize
  end

  # REVIEW: Put this in EvernoteNote? and mimic Books?
  def update_with_evernote_data(cloud_resource, caption, description, credit)
    binary_not_downloaded = (cloud_resource.data.bodyHash != data_hash)
    update_attributes!(
      altitude: cloud_resource.attributes.altitude,
      attachment: cloud_resource.attributes.attachment,
      attempts: 0,
      camera_make: cloud_resource.attributes.cameraMake,
      camera_model: cloud_resource.attributes.cameraModel,
      caption: caption,
      credit: credit,
      data_hash: cloud_resource.data.bodyHash,
      description: description,
      dirty: binary_not_downloaded,
      external_updated_at: cloud_resource.attributes.timestamp ? Time.at(cloud_resource.attributes.timestamp / 1000).to_datetime : nil,
      file_name: cloud_resource.attributes.fileName,
      height: cloud_resource.height,
      latitude: cloud_resource.attributes.latitude,
      local_file_name: cloud_resource.guid,
      longitude: cloud_resource.attributes.longitude,
      mime: cloud_resource.mime,
      source_url: cloud_resource.attributes.sourceURL,
      try_again_at: binary_not_downloaded ? Time.now : 100.years.from_now,
      width: cloud_resource.width
    )
  end

  def delete_binaries
    File.delete raw_location if File.exists? raw_location
    Dir.glob("public/resources/templates/#{ id }*.*").each do |binary|
      File.delete binary if File.exists? binary
    end
    Dir.glob("public/resources/cut/*-#{ id }.*").each do |binary|
      File.delete binary if File.exists? binary
    end
  end
end
