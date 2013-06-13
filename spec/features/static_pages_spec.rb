describe 'Static pages' do

  describe 'Home page' do

    before { visit '/' }

    it 'has a link to Notes' do
      page.should have_link(I18n.t('notes.title'), href: notes_path)
    end
    
    it 'has a link to Tags' do
      page.should have_link(I18n.t('tags.title'), href: tags_path)
    end

  end

end
