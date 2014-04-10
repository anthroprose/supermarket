require 'spec_helper'

describe Api::V1::CookbookUploadsController do
  before do
    subject.stub(:authenticate_user!) { true }
    subject.stub(:current_user) { create(:user) }
  end

  describe '#create' do
    context 'when the upload succeeds' do
      before do
        allow_any_instance_of(CookbookUpload).
          to receive(:finish).
          and_yield([], double('Cookbook', name: 'cookbook'))
      end

      it 'sends the cookbook to the view' do
        post :create, cookbook: 'cookbook', tarball: 'tarball', format: :json

        expect(assigns[:cookbook]).to_not be_nil
      end

      it 'returns a 201' do
        post :create, cookbook: 'cookbook', tarball: 'tarball', format: :json

        expect(response.status.to_i).to eql(201)
      end
    end

    context 'when the upload fails' do
      before do
        errors = ActiveModel::Errors.new([]).tap do |e|
          e.add(:base, 'This cookbook is no good')
        end

        allow_any_instance_of(CookbookUpload).
          to receive(:finish).
          and_yield(errors, double('Cookbook'))
      end

      it 'renders the error messages' do
        post :create, cookbook: 'cookbook', tarball: 'tarball', format: :json

        expect(JSON.parse(response.body)).to eql(
          'error' => I18n.t('api.error_codes.invalid_data'),
          'error_messages' => ['This cookbook is no good']
        )
      end

      it 'returns a 400' do
        post :create, cookbook: 'cookbook', tarball: 'tarball', format: :json

        expect(response.status.to_i).to eql(400)
      end
    end

    context 'when the tarball parameter is missing' do
      it 'returns a 400' do
        post :create, cookbook: '{}', format: :json

        expect(response.status.to_i).to eql(400)
      end
    end

    context 'when the cookbook parameter is missing' do
      it 'returns a 400' do
        post :create, tarball: 'tarball', format: :json

        expect(response.status.to_i).to eql(400)
      end
    end
  end

  describe '#destroy' do
    context 'when a cookbook exists' do
      let!(:cookbook) { create(:cookbook) }
      let(:unshare) { delete :destroy, cookbook: cookbook.name, format: :json }

      it 'sends the cookbook to the view' do
        unshare
        expect(assigns[:cookbook]).to eql(cookbook)
      end

      it 'responds with a 200' do
        unshare
        expect(response.status.to_i).to eql(200)
      end

      it 'destroys a cookbook' do
        expect { unshare }.to change(Cookbook, :count).by(-1)
      end

      it 'destroys all associated cookbook versions' do
        expect { unshare }.to change(CookbookVersion, :count).by(-2)
      end
    end

    context 'when a cookbook does not exist' do
      it 'responds with a 404' do
        delete :destroy, cookbook: 'mamimi', format: :json

        expect(response.status.to_i).to eql(404)
      end
    end
  end
end
