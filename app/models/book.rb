# encoding: utf-8

class Book < ActiveRecord::Base

  include Syncable

  has_and_belongs_to_many :notes

  default_scope { order('tag') }

  scope :citable, -> { where('title IS NOT ? AND tag IS NOT ? AND published_date IS NOT ?', nil, nil, nil) }
  scope :editable, -> { order('updated_at DESC') }
  scope :missing_metadata, -> { where('author IS ? OR title IS ? OR published_date IS ?', nil, nil, nil).order('updated_at DESC') }
  scope :cited, -> { where('title IS NOT ? AND tag IS NOT ?', nil, nil)
    .joins('left outer join books_notes on books.id = books_notes.book_id')
    .where('books_notes.book_id IS NOT ?', nil)
    .uniq } # OPTIMIZE: Notes must be active and not hidden (publishable) see http://stackoverflow.com/questions/3875564

  validates :isbn_10, :isbn_13, uniqueness: true, allow_blank: true
  validates :isbn_13, presence: true, if: 'isbn_10.blank?'
  validates :isbn_10, isbn_format: { with: :isbn10 }, allow_blank: true
  validates :isbn_13, isbn_format: { with: :isbn13 }, allow_blank: true
  validates :full_text_url, url: true, allow_blank: true

  before_validation :update_tag,
                    if: (:author_changed? || :editor_changed? || :published_date_changed?) && '!published_date.blank?',
                    unless: :tag_changed? # || '!tag.blank?'
  before_validation :scan_notes_for_references, if: :tag_changed?

  paginates_per Setting['advanced.books_index_per_page'].to_i

  extend FriendlyId
  friendly_id :tag, use: :slugged

  def to_param
    slug
  end

  def self.grab_isbns(text)
    text.scan(/([0-9\-]{9,17}X?)/).each { |isbn_candidate| add_task(isbn_candidate.first) }
  end

  def self.add_task(isbn_candidate)
    isbn_candidate.gsub!(/[^\dX]/, '')
    book = where(isbn_10: isbn_candidate).first_or_create if isbn_candidate.length == 10
    book = where(isbn_13: isbn_candidate).first_or_create if isbn_candidate.length == 13
    # We can't use dirtify here because this is a class method
    if book
      book.dirty = true
      book.attempts = 0
      book.save
      book
    end
  end

  def self.sync_all
    need_syncdown.missing_metadata.each { |book| book.populate! }
  end

  def isbn
    (isbn_10.blank? ? isbn_13 : isbn_10)
  end

  def short_title
    title.blank? ? '' : title.gsub(/\:.*$/, '')
  end

  def author_or_editor
    author.blank? ? "#{ editor } #{ I18n.t('books.show.editor_short') }" : author
  end

  def author_sort
    return nil if author.blank? && editor.blank?
    (author.blank? ? editor : author).gsub(/([^ ]+?) ?([^ ]*)$/, '\\2, \\1')
  end

  def author_surname
    return nil if author.blank? && editor.blank?
    surname = (author.blank? ? editor : author).split(',')[0].scan(/([^ ]*)$/)[0][0]
    author.blank? ? "#{ surname } #{ I18n.t('books.show.editor_short') }" : surname
  end

  def headline
    "#{ author_surname }: <cite>#{ short_title }</cite>".html_safe
  end

  # REVIEW: this fails if protected and called through sync_all
  def populate!
    increment_attempts
    merge_world_cat
    merge_isbndb
    merge_google_books
    merge_open_library
    undirtify(false) unless missing_metadata?
    SYNC_LOG.info I18n.t('books.sync.updated', id: id, author: author, title: title, isbn: isbn)
    announce_missing_metadata if missing_metadata? && attempts == Setting['advanced.attempts'].to_i
    save!
  end

  def merge_world_cat
    merge(WorldCatRequest.new(isbn).metadata) if Constant.books.world_cat.active?
  end

  def merge_isbndb
    merge(IsbndbRequest.new(isbn).metadata) if Constant.books.isbndb.active?
  end

  def merge_google_books
    merge(GoogleBooksRequest.new(isbn).metadata) if Constant.books.google_books.active?
  end

  def merge_open_library
    merge(OpenLibraryRequest.new(isbn).metadata) if Constant.books.open_library.active?
  end

  private

  def scan_notes_for_references
    # REVIEW: try checking for setting as an unless: after before_save
    self.notes = Note.where('body LIKE ?', "%#{ tag }%") if Setting['advanced.books_section'] == 'true'
  end

  def missing_metadata?
    title.blank? || author.blank? || published_date.blank?
  end

  def announce_missing_metadata
    BookMailer.missing_metadata(self).deliver
    SYNC_LOG.error I18n.t('books.sync.missing_metadata.logger', id: id, author: author, title: title, isbn: isbn)
  end

  def update_tag
    self.tag = "#{ author_surname } #{ published_date.year }"
  end
end
