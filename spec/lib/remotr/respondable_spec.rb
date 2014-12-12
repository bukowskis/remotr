require 'spec_helper'

RSpec.describe Remotr::Respondable do

  let(:api) { MyTestApp::Event }
  let(:operation) { api.all  }

  context 'server does not exist' do
    before do
      WebMock.disable!
      api.config.base_uri = 'http://does-certailny-not-exist.blue'
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :connection_failed
    end

    it 'holds the exception as object' do
      expect(operation.object).to be_instance_of SocketError
    end
  end

  context 'server times out' do
    before do
      WebMock.disable!
      api.config.base_uri = 'http://10.255.255.1'
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :connection_failed
    end

    it 'holds the exception as object' do
      # Ruby 1.9.3 vs 2.1.1
      expect(%w(Net::OpenTimeout Timeout::Error)).to include operation.object.class.to_s
    end
  end

  context 'getting a 4xx response' do
    before do
      WebMock.disable!
      api.config.base_uri = 'http://example.com/does-not-exist'
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :request_failed
    end

    it 'holds the HTTParty as object' do
      expect(operation.object.class).to eq HTTParty::Response
    end
  end

  context 'receiving empty response' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200)
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :response_missing_content_type
    end

    it 'holds the HTTParty as object' do
      expect(operation.object.class).to eq HTTParty::Response
    end
  end

  context 'receiving response without content type' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: 'I am just some blob data!', headers: { 'Age' => '12' })
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :response_missing_content_type
    end

    it 'holds the HTTParty as object' do
      expect(operation.object.class).to eq HTTParty::Response
    end
  end

  context 'receiving XML' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: '<xml><some><thing /></some></xml>', headers: { 'Content-Type' => 'application/xml' })
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :response_is_not_json
    end

    it 'holds the HTTParty as object' do
      expect(operation.object.class).to eq HTTParty::Response
    end
  end

  context 'receiving broken JSON' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: 'I cannot be parsed as JSON', headers: { 'Content-Type' => 'application/json' })
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :json_parsing_failed
    end

    it 'holds the HTTParty as object' do
      expect(operation.object.class).to eq HTTParty::Response
    end
  end

  context 'receiving JSON without success flag' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: { some: :thing }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :response_missing_success_flag
    end

    it 'holds the HTTParty as object' do
      expect(operation.object.class).to eq HTTParty::Response
    end
  end

  context 'JSON with falsey success flag' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: { success: :not_true }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fails' do
      expect(operation).to be_failure
    end

    it 'has an informative code' do
      expect(operation.code).to eq :response_unsuccessful
    end

    it 'holds the HTTParty as object' do
      expect(operation.object.class).to eq HTTParty::Response
    end
  end

  context 'JSON with true success flag' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'succeeds' do
      expect(operation).to be_success
    end

    it 'has an informative code' do
      expect(operation.code).to eq :request_succeeded
    end

    it 'holds no object' do
      expect(operation.object).to be_nil
    end
  end

  context 'an object in the default namespace' do
    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: { success: true, events: [:a, :b, :c] }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'succeeds' do
      expect(operation).to be_success
    end

    it 'has an informative code' do
      expect(operation.code).to eq :request_succeeded
    end

    it 'holds no object' do
      expect(operation.object).to eq %w(a b c)
    end
  end

  context 'an object in a custom namespace' do
    let(:operation) { api.first }

    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: { success: true, event: 'beautiful event' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'succeeds' do
      expect(operation).to be_success
    end

    it 'has an informative code' do
      expect(operation.code).to eq :request_succeeded
    end

    it 'holds no object' do
      expect(operation.object).to eq 'beautiful event'
    end
  end

  context 'custom code derived from the response' do
    let(:operation) { api.first }

    before do
      stub_request(:get, /.*example.*/).to_return(status: 200, body: { success: true, code: :supercool, event: 'nice event' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'succeeds' do
      expect(operation).to be_success
    end

    it 'has an informative code' do
      expect(operation.code).to eq :supercool
    end

    it 'holds no object' do
      expect(operation.object).to eq 'nice event'
    end
  end

end
