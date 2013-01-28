module ApplicationHelper
  def lang_attr(language)
    if language != I18n.locale.to_s
      language
    end
  end

  def body_dir_attr(language)
    if Settings.lang.rtl_langs.include?(language)
      'rtl'
    end
  end

  def dir_attr(language)
    if language != I18n.locale.to_s
      page_direction = Settings.lang.rtl_langs.include?(I18n.locale.to_s) ? 'rtl' : 'ltr'
      this_direction = Settings.lang.rtl_langs.include?(language) ? 'rtl' : 'ltr'
      if page_direction != this_direction
        this_direction
      end
    end
  end

  def snippet(text, wordcount)
    text = strip_tags text
    text.split[0..(wordcount-1)].join(' ') + (text.split.size > wordcount ? '...' : '')
  end

  def bodify(text)
    notify(smartify(text))
      .gsub(/^(.+)$/, '<p>\1</p>').gsub(/^ +$/, '')
      .html_safe
  end

  def smartify(text)
    text
      .gsub(/ - ([^-^.]+) - /, "\u2013\\1\u2013")
      .gsub(/(\b\.)(\b)/, ". ")
      .gsub(/  /, " ")
      .gsub(/ - /, "\u2014")
      .gsub(/'([\d{2}])/, "\u2019\\1")
      .gsub(/(\b)'(\b)/, "\u2019")
      .gsub(/(\w)'(\w)/, "\\1\u2019\\2")
      .gsub(/'([^']+)'/, "\u2018\\1\u2019")
      .gsub(/"([^"]+)"/, "\u201C\\1\u201D")
  end

  def notify(text)
    text
      .gsub(/\[/, '<span class="annotation instapaper_ignore"><span>')
      .gsub(/\]/, '</span></span>')
  end
end
