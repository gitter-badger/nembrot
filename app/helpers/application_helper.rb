module ApplicationHelper

  # Add html truncate gem - do blurb
  # Truncate by letters not words
  def snippet(text, wordcount)
    # Full path to strip_tags because we're using this in model (sub-optimal)
    text = ActionController::Base.helpers.strip_tags text
    text.split[0..(wordcount-1)].join(' ') + (text.split.size > wordcount ? '...' : '')
  end

  def bodify(text)
    (sanitize text, :tags => %w(a ul ol li ins del), :attributes => %w(href))
      .gsub(/^.*DOCTYPE.*>/, '')
      .gsub(/^(\w*)$/, '')
      .gsub(/^(.*)$/, '<p>\1</p>')
      .html_safe
  end
end
