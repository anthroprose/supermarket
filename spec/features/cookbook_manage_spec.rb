require 'spec_feature_helper'

describe "updating a cookbook's issue and source urls" do
  before { sign_in create(:user) }

  it 'displays success message when saved' do
    owner = create(:user)
    cookbook = create(:cookbook, owner: owner)

    visit cookbook_path(cookbook)

    within '.cookbook_show_sidebar' do
      follow_relation 'edit-cookbook-urls'
      fill_in 'cookbook_source_url', with: 'http://example.com/source'
      fill_in 'cookbook_source_url', with: 'http://example.com/tissues'
      submit_form
    end

    expect(page).to have_selector('.source-url')
  end

  it 'displays a failure message when invalid urls are entered' do
    owner = create(:user)
    cookbook = create(:cookbook, owner: owner)

    visit cookbook_path(cookbook)

    within '.cookbook_show_sidebar' do
      follow_relation 'edit-cookbook-urls'
      fill_in 'cookbook_source_url', with: 'example'
      fill_in 'cookbook_source_url', with: 'example'
      expect(page).to have_selector('.error')
    end
  end
end
