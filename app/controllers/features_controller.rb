class FeaturesController < ApplicationController

  def show
    @notes = Note.publishable.where(feature: params[:feature])

    if @notes.empty?
      flash[:error] = "404 error! #{ request.url } does not exist."
      redirect_to root_path
    elsif @notes.size > 1 && params[:feature_id].nil?
      show_feature_index
    else
      show_feature
    end
  end

  private

  def show_feature_index
    page_number = params[:page] ||= 1
    @notes = @notes.page(page_number).load
    @title = @notes.first.main_title
    interrelated_notes_features_and_citations
    @map = @notes.mappable
    @total_count = @notes.size
    @word_count = @notes.sum(:word_count)
    add_breadcrumb @notes.first.get_feature_name, feature_path(@notes.first.feature)
    render template: 'notes/index'
  end

  def show_feature
    @note = params[:feature_id].nil? ? @notes.first : @notes.where(feature_id: params[:feature_id]).first
    note_tags(@note)
    commontator_thread_show(@note)
    interrelated_notes_features_and_citations
    @map = mapify(@note) if @note.has_instruction?('map') && !@note.inferred_latitude.nil?
    @source = Note.where(title: @note.title).where.not(lang: @note.lang).first if @note.has_instruction?('parallel')
    add_breadcrumb @note.get_feature_name, feature_path(@note.feature)
    add_breadcrumb @note.get_feature_id, feature_path(@note.feature, @note.feature_id) unless params[:feature_id].nil?
    render template: 'notes/show'
  end
end
