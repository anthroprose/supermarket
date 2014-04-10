require 'spec_helper'

describe 'POST /api/v1/cookbooks' do
  context 'the user provides valid params' do
    before(:each) { share_cookbook(cookbook_name: 'redis-test') }

    it 'returns a 201' do
      expect(response.status.to_i).to eql(201)
    end

    it 'returns the URI for the newly created cookbook' do
      expect(json_body['uri']).to match(%r(api/v1/cookbooks/redis))
    end
  end

  context "the user doesn't provide valid params" do
    before(:each) { share_cookbook(cookbook_name: 'redis-test', payload: {}) }

    it 'returns a 400' do
      expect(response.status.to_i).to eql(400)
    end

    it 'returns an error code' do
      expect(json_body['error_code']).to_not be_nil
    end

    it 'returns a error message' do
      expect(json_body['error_messages']).to_not be_nil
    end
  end

  context "the user sharing doesn't exist" do
    before(:each) { share_cookbook(cookbook_name: 'redis-test', user: double(:user, username: 'non-existent-user')) }

    it 'returns a 401' do
      expect(response.status.to_i).to eql(401)
    end

    it 'returns an error code' do
      expect(json_body['error_code']).to_not be_nil
    end

    it 'returns an error message' do
      expect(json_body['error_messages']).to_not be_nil
    end
  end

  context "the users private/public key pair is invalid" do
    before(:each) { share_cookbook(cookbook_name: 'redis-test', private_key: 'invalid_private_key.pem') }

    it 'returns a 401' do
      expect(response.status.to_i).to eql(401)
    end

    it 'returns an error code' do
      expect(json_body['error_code']).to_not be_nil
    end

    it 'returns an error message' do
      expect(json_body['error_messages']).to_not be_nil
    end
  end

  context "invalid signing headers are sent" do
    before(:each) { share_cookbook(cookbook_name: 'redis-test', omitted_headers: ['X-Ops-Sign']) }

    it 'returns a 400' do
      expect(response.status.to_i).to eql(400)
    end

    it 'returns an error code' do
      expect(json_body['error_code']).to_not be_nil
    end

    it 'returns an error message' do
      expect(json_body['error_messages']).to_not be_nil
    end
  end
end
