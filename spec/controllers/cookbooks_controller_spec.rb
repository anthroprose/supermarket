require 'spec_helper'

describe CookbooksController do
  describe 'GET #index' do
    context 'there are no parameters' do
      it 'assigns @cookbooks' do
        get :index
        expect(assigns[:cookbooks]).to_not be_nil
      end

      it 'paginates @cookbooks' do
        create_list(:cookbook, 30)
        get :index

        expect(assigns[:cookbooks].count).to eql(20)
      end

      it 'assigns @categories' do
        get :index
        expect(assigns[:categories]).to_not be_nil
      end
    end

    context 'there is an order parameter' do
      let!(:cookbook_1) do
        create(
          :cookbook,
          name: 'great',
          updated_at: 1.year.ago,
          created_at: 1.year.ago,
          download_count: 100,
          cookbook_followers_count: 100
        )
      end

      let!(:cookbook_2) do
        create(
          :cookbook,
          name: 'cookbook',
          updated_at: 1.day.ago,
          created_at: 2.years.ago,
          download_count: 50,
          cookbook_followers_count: 50
        )
      end

      it 'orders @cookbooks by updated at' do
        get :index, order: 'recently_updated'
        expect(assigns[:cookbooks].first).to eql(cookbook_2)
      end

      it 'orders @cookbooks by created at' do
        get :index, order: 'recently_added'
        expect(assigns[:cookbooks].first).to eql(cookbook_1)
      end

      it 'orders @cookbooks by download_count' do
        get :index, order: 'most_followed'
        expect(assigns[:cookbooks].first).to eql(cookbook_1)
      end

      it 'orders @cookbooks by download_followers_count' do
        get :index, order: 'most_downloaded'
        expect(assigns[:cookbooks].first).to eql(cookbook_1)
      end
    end

    context 'there is a category parameter' do
      let!(:databases_cookbook) { create(:cookbook, category: create(:category, name: 'Databases')) }
      let!(:other_cookbook) { create(:cookbook, category: create(:category, name: 'Other')) }

      it 'only returns @cookbooks with the specified category' do
        get :index, category: 'other'

        expect(assigns[:cookbooks]).to include(other_cookbook)
        expect(assigns[:cookbooks]).to_not include(databases_cookbook)
      end
    end

    context 'there is a query parameter' do
      let!(:amazing_cookbook) do
        create(
          :cookbook,
          name: 'AmazingCookbook',
          maintainer: 'john@example.com',
          description: 'Makes you a pirate',
          category: create(:category, name: 'Databases')
        )
      end

      let!(:ok_cookbook) do
        create(
          :cookbook,
          name: 'OKCookbook',
          maintainer: 'jack@example.com',
          description: 'Makes you a pigeon',
          category: create(:category, name: 'Other')
        )
      end

      it 'only returns @cookbooks that match the name' do
        get :index, q: 'amazing'

        expect(assigns[:cookbooks]).to include(amazing_cookbook)
        expect(assigns[:cookbooks]).to_not include(ok_cookbook)
      end

      it 'only returns @cookbooks that match the maintainer' do
        get :index, q: 'john'

        expect(assigns[:cookbooks]).to include(amazing_cookbook)
        expect(assigns[:cookbooks]).to_not include(ok_cookbook)
      end

      it 'only returns @cookbooks that match the description' do
        get :index, q: 'pirate'

        expect(assigns[:cookbooks]).to include(amazing_cookbook)
        expect(assigns[:cookbooks]).to_not include(ok_cookbook)
      end

      it 'only returns @cookbooks that match the category' do
        get :index, q: 'databases'

        expect(assigns[:cookbooks]).to include(amazing_cookbook)
        expect(assigns[:cookbooks]).to_not include(ok_cookbook)
      end
    end
  end

  describe 'PATCH #update' do
    let(:cookbook) { create(:cookbook) }
    before { sign_in create(:user) }

    context 'the params are valid' do
      it 'updates the cookbook' do
        patch :update, id: cookbook, cookbook: {
          source_url: 'http://example.com/cookbook',
          issues_url: 'http://example.com/cookbook/issues'
        }

        cookbook.reload

        expect(cookbook.source_url).to eql('http://example.com/cookbook')
        expect(cookbook.issues_url).to eql('http://example.com/cookbook/issues')
      end

      it 'redirects to @cookbook'  do
        patch :update, id: cookbook, cookbook: {
          source_url: 'http://example.com/cookbook',
          issues_url: 'http://example.com/cookbook/issues'
        }

        expect(response).to redirect_to(assigns[:cookbook])
      end
    end

    context 'the params are invalid' do
      it "doesn't update the cookbook" do
        expect do
          patch :update, id: cookbook, cookbook: { source_url: 'some-invalid-url' }
        end.to_not change(cookbook, :source_url)
      end

      it 'redirects to @cookbook' do
        patch :update, id: cookbook, cookbook: { source_url: 'some-invalid-url' }

        expect(response).to redirect_to(assigns[:cookbook])
      end
    end
  end

  describe 'GET #directory' do
    before { get :directory }

    it 'assigns @recently_updated_cookbooks' do
      expect(assigns[:recently_updated_cookbooks]).to_not be_nil
    end

    it 'assigns @recently_added_cookbooks' do
      expect(assigns[:recently_added_cookbooks]).to_not be_nil
    end

    it 'assigns @most_downloaded_cookbooks' do
      expect(assigns[:most_downloaded_cookbooks]).to_not be_nil
    end

    it 'assigns @most_followed_cookbooks' do
      expect(assigns[:most_followed_cookbooks]).to_not be_nil
    end

    it 'assigns @categories' do
      expect(assigns[:categories]).to_not be_nil
    end
  end

  describe '#show' do
    let(:hank) { create(:user) }
    let(:sally) { create(:user) }
    let(:cookbook) { create(:cookbook, owner: hank) }

    before do
      create(:icla_signature, user: sally)
      create(:cookbook_collaborator, cookbook: cookbook, user: sally)
    end

    it 'renders the show template' do
      get :show, id: cookbook.name

      expect(response).to render_template('show')
    end

    it 'renders an atom feed of cookbook versions' do
      get :show, id: cookbook.name, format: :atom

      expect(response).to render_template('show')
    end

    it 'sends the cookbook to the view' do
      get :show, id: cookbook.name

      expect(assigns(:cookbook)).to eql(cookbook)
    end

    it 'sends the latest cookbook version to the view' do
      version = create(:cookbook_version, cookbook: cookbook)
      get :show, id: cookbook.name

      expect(assigns(:latest_version)).to eql(version)
    end

    it 'sends all cookbook versions to the view' do
      get :show, id: cookbook.name

      expect(assigns(:cookbook_versions)).to_not be_empty
    end

    it 'sends the maintainer to the view' do
      get :show, id: cookbook.name

      expect(assigns(:owner)).to_not be_nil
    end

    it 'sends the collaborators to the view' do
      get :show, id: cookbook.name

      expect(assigns(:collaborators)).to_not be_nil
    end

    it 'sends the supported platforms to the view' do
      get :show, id: cookbook.name

      expect(assigns(:supported_platforms)).to_not be_nil
    end

    it '404s when the cookbook does not exist' do
      get :show, id: 'snarfle'

      expect(response.status.to_i).to eql(404)
    end
  end

  describe '#download' do
    let(:cookbook) do
      cookbook = create(:cookbook)
    end

    it '302s to the cookbook version download  path' do
      version = create(:cookbook_version, cookbook: cookbook)

      get :download, id: cookbook.name

      expect(response).to redirect_to(cookbook_version_download_url(cookbook, version))
      expect(response.status.to_i).to eql(302)
    end

    it '404s when the cookbook does not exist' do
      get :download, id: 'snarfle'

      expect(response.status.to_i).to eql(404)
    end
  end

  describe 'PUT #follow' do
    let(:cookbook) { create(:cookbook) }
    before { request.env['HTTP_REFERER'] = cookbook_url(cookbook) }

    context 'a user is signed in' do
      before { sign_in create(:user) }

      it 'should add a follower' do
        expect do
          put :follow, id: cookbook
        end.to change(cookbook.cookbook_followers, :count).by(1)
      end

      it 'redirects back' do
        put :follow, id: cookbook

        expect(response).to redirect_to(:back)
      end
    end

    context 'a user is not signed in' do
      it 'redirects to user sign in' do
        put :follow, id: cookbook

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'cookbook does not exist' do
      before { sign_in create(:user) }

      it 'returns a 404' do
        put :follow, id: 'snarfle'

        expect(response.status.to_i).to eql(404)
      end
    end
  end

  describe 'DELETE #unfollow' do
    let(:cookbook) { create(:cookbook) }
    before { request.env['HTTP_REFERER'] = cookbook_url(cookbook) }

    context 'the signed in user follows the specified cookbook' do
      before do
        user = create(:user)
        create(:cookbook_follower, cookbook: cookbook, user: user)
        sign_in(user)
      end

      it 'should remove follower' do
        expect do
          delete :unfollow, id: cookbook
        end.to change(cookbook.cookbook_followers, :count).by(-1)
      end

      it 'redirects back' do
        delete :follow, id: cookbook

        expect(response).to redirect_to(:back)
      end
    end

    context "the signed in user doesn't follow the specified cookbook" do
      before { sign_in create(:user) }

      it 'should not remove a follower'  do
        expect do
          delete :unfollow, id: cookbook
        end.to_not change(cookbook.cookbook_followers, :count)
      end

      it 'redirects back' do
        delete :follow, id: cookbook

        expect(response).to redirect_to(:back)
      end
    end
  end
end
