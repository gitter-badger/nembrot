# encoding: utf-8

module ResourcesHelper

  include EffectsHelper

  # REVIEW: Does this duplicate Resource#cut_location? Or maybe this should be a separate Class?
  #  Derive from: https://github.com/carrierwaveuploader/carrierwave/blob/92c817bb7b1c821d8021d3fd1ded06551b1d9a01/lib/carrierwave/processing/mini_magick.rb
  #  And: https://gist.github.com/tonycoco/2910540

  def cut_image_binary_path(image, options = {})
    type = options[:type] || 'standard'

    Rails.application.routes.url_helpers.cut_resource_path(
      file_name:  image.local_file_name,
      aspect_x:   options[:aspect_x]  || Setting["style.images_#{ type.to_s }_aspect_x"],
      aspect_y:   options[:aspect_y]  || Setting["style.images_#{ type.to_s }_aspect_y"],
      width:      options[:width]     || Setting["style.images_#{ type.to_s }_width"],
      snap:       options[:snap]      || Setting['style.images_snap'],
      gravity:    options[:gravity]   || Setting['style.images_gravity'],
      effects:    options[:effects]   || image.note.fx,
      id:         options[:id]        || image.id,
      format:     image.file_ext.to_sym
    )
  end

  def cut_image_binary(local_file_name, format, aspect_x, aspect_y, width, snap, gravity, effects)

    image_record = Resource.find_by_local_file_name(local_file_name)

    if image_record.nil?
      logger.info t('resources.cut.failed.record_not_found', local_file_name: local_file_name)
      return Constant.blank_image_location
    end

    file_name_template = image_record.template_location(aspect_x, aspect_y)
    file_name_out = image_record.cut_location(aspect_x, aspect_y, width, snap, gravity, effects)

    # Shorthand: small integers are taken to be number of columns rather than absolute width
    width = column_width(width) if width <= Setting['style.total_columns'].to_i

    # The height is derived from the aspect ratio and width.
    height = (width * aspect_y) / aspect_x

    # We snap the height to nearest baseline to maintain a vertical grid.
    height = round_nearest(height, Setting['style.line_height'].to_i) if snap == '1'

    # We check if a (manually-cropped) template exists.
    file_name_in = (File.exists?(file_name_template) ? file_name_template : image_record.raw_location)

    begin
      image =  MiniMagick::Image.open(file_name_in)
      image = pre_fx(image, effects)

      # TODO: This needs to do crop/resize, not just resize.
      # image.resize "#{ width }x#{ height }"

      gravity_options = { gravity: gravity } unless gravity == '0' || gravity == ''
      resize_with_crop(image, width, height, gravity_options = {})

      image = fx(image, effects)
      image = post_fx(image, effects, image_record)

      # Gravity
      # image = image.resize_to_fit(width, height, EastGravity)

      # We save the image so next time it can be served directly, totally bypassing Rails.
      image.write file_name_out
      return file_name_out
    rescue => error
      image_record.dirty = true
      image_record.save!
      logger.info t('resources.cut.failed.image_record_not_found', local_file_name: local_file_name)
      logger.info error
      return image_record.blank_location
    end
  end

  def round_nearest(number, nearest)
    (number / nearest.to_f).round * nearest
  end

  def column_width(columns)
    (Setting['style.column_width'].to_i * columns) + (Setting['style.gutter_width'].to_i * (columns - 1))
  end

  # FROM: http://maxivak.com/crop-and-resize-an-image-using-minimagick-ruby-on-rails/
  def resize_with_crop(img, w, h, options = {})
    gravity = options[:gravity] || :center

    w_original, h_original = [img[:width].to_f, img[:height].to_f]

    op_resize = ''

    # check proportions
    if w_original * h < h_original * w
      op_resize = "#{ w.to_i }x"
      w_result = w
      h_result = (h_original * w / w_original)
    else
      op_resize = "x#{ h.to_i }"
      w_result = (w_original * h / h_original)
      h_result = h
    end

    w_offset, h_offset = crop_offsets_by_gravity(gravity, [w_result, h_result], [w, h])

    img.combine_options do |i|
      i.resize(op_resize)
      i.gravity(gravity)
      i.crop "#{w.to_i}x#{h.to_i}+#{w_offset}+#{h_offset}!"
      i.quality 65
    end

    img
  end

  # from http://www.dweebd.com/ruby/resizing-and-cropping-images-to-fixed-dimensions/

  GRAVITY_TYPES = [:north_west, :north, :north_east, :east, :south_east, :south, :south_west, :west, :center]

  def crop_offsets_by_gravity(gravity, original_dimensions, cropped_dimensions)
    fail(ArgumentError, "Gravity must be one of #{GRAVITY_TYPES.inspect}") unless GRAVITY_TYPES.include?(gravity.to_sym)
    fail(ArgumentError, 'Original dimensions must be supplied as a [ width, height ] array') unless original_dimensions.kind_of?(Enumerable) && original_dimensions.size == 2
    fail(ArgumentError, 'Cropped dimensions must be supplied as a [ width, height ] array') unless cropped_dimensions.kind_of?(Enumerable) && cropped_dimensions.size == 2

    original_width, original_height = original_dimensions
    cropped_width, cropped_height = cropped_dimensions

    [
      _horizontal_offset(gravity, original_width, cropped_width),
      _vertical_offset(gravity, original_height, cropped_height)
    ]
  end

  def _horizontal_offset(gravity, original_width, cropped_width)
    case gravity
    when :north_west, :west, :south_west then 0
    when :center, :north, :south then [((original_width - cropped_width) / 2.0).to_i, 0].max
    when :north_east, :east, :south_east then (original_width - cropped_width).to_i
    end
  end

  def _vertical_offset(gravity, original_height, cropped_height)
    case gravity
    when :north_west, :north, :north_east then 0
    when :center, :east, :west then [((original_height - cropped_height) / 2.0).to_i, 0].max
    when :south_west, :south, :south_east then (original_height - cropped_height).to_i
    end
  end
end
