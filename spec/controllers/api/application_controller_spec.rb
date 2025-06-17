require 'rails_helper'

RSpec.describe Api::ApplicationController, type: :controller do
  # テスト用のコントローラを作成
  controller do
    before_action :authenticate_user
    helper_method :current_user  # current_userをヘルパーメソッドとして公開
    def index
      render json: { message: 'success' }
    end
  end

  describe '#authenticate_user' do
    context '認証に成功した場合' do
      let(:valid_payload) do
        {
          'sub' => 'test-sub-123',
          'email' => 'test@example.com',
          'name' => 'Test User',  # name属性を追加
          'iss' => "https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['COGNITO_USER_POOL_ID']}",
          'aud' => ENV['COGNITO_APP_CLIENT_ID'],
          'exp' => 1.hour.from_now.to_i
        }
      end

      let(:valid_token) { JWT.encode(valid_payload, nil, 'none') }
      let(:mock_jwks) do
        [{
          'kid' => 'test-kid',
          'kty' => 'RSA',
          'n' => 'test-n',
          'e' => 'AQAB'
        }]
      end

      before do
        # JWKSのスタブ
        allow(Rails.cache).to receive(:fetch).with('cognito_jwks', expires_in: 12.hours).and_return(mock_jwks)
        # JWTデコードのスタブ
        allow(JWT).to receive(:decode).and_return([valid_payload, { 'kid' => 'test-kid' }])
        allow(JWT::JWK).to receive(:import).and_return(double(public_key: OpenSSL::PKey::RSA.new(2048)))
      end

      context '既存のユーザーが存在する場合' do
        let!(:existing_user) { create(:user, cognito_sub: valid_payload['sub'], email: valid_payload['email'], name: valid_payload['name']) }

        it '既存のユーザーが検索されること' do
          request.headers['Authorization'] = "Bearer #{valid_token}"
          get :index
          expect(response).to have_http_status(:ok)
          expect(controller.send(:current_user)).to eq(existing_user)
          expect(User.count).to eq(1) # 新しいユーザーが作成されていないことを確認
        end
      end

      context '新規ユーザーの場合' do
        it '新しいユーザーが作成されること' do
          request.headers['Authorization'] = "Bearer #{valid_token}"
          expect do
            get :index
          end.to change(User, :count).by(1)
          
          expect(response).to have_http_status(:ok)
          created_user = controller.send(:current_user)
          expect(created_user.cognito_sub).to eq(valid_payload['sub'])
          expect(created_user.email).to eq(valid_payload['email'])
          expect(created_user.name).to eq(valid_payload['name'])
        end
      end
    end

    context '認証に失敗した場合' do
      it '401 Unauthorizedとエラーメッセージが返されること' do
        get :index
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json.keys).to eq(['error'])
        expect(json['error']).to eq('Unauthorized')
      end

      it 'Authorizationヘッダーがない場合は401が返されること' do
        request.headers['Authorization'] = nil
        get :index
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json.keys).to eq(['error'])
        expect(json['error']).to eq('Unauthorized')
      end

      it '不正なトークン形式の場合は401が返されること' do
        request.headers['Authorization'] = 'InvalidToken'
        get :index
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json.keys).to eq(['error'])
        expect(json['error']).to eq('Unauthorized')
      end

      it 'Bearerプレフィックスがない場合は401が返されること' do
        request.headers['Authorization'] = 'valid.token.here'
        get :index
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json.keys).to eq(['error'])
        expect(json['error']).to eq('Unauthorized')
      end

      context 'JWTの検証に失敗する場合' do
        let(:invalid_payload) do
          {
            'sub' => 'test-sub-123',
            'email' => 'test@example.com',
            'name' => 'Test User',
            'iss' => 'https://invalid-issuer.com',  # 不正な発行者
            'aud' => 'invalid-audience',            # 不正な対象者
            'exp' => 1.hour.from_now.to_i
          }
        end

        let(:invalid_token) { JWT.encode(invalid_payload, nil, 'none') }
        let(:mock_jwks) do
          [{
            'kid' => 'test-kid',
            'kty' => 'RSA',
            'n' => 'test-n',
            'e' => 'AQAB'
          }]
        end

        before do
          # decode_cognito_jwt が検証エラーを返すようにスタブ
          allow_any_instance_of(Api::ApplicationController).to receive(:decode_cognito_jwt).and_raise(JWT::VerificationError.new('Invalid token'))
        end

        it '不正なISSの場合は401が返されること' do
          request.headers['Authorization'] = "Bearer #{invalid_token}"
          get :index
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to include('application/json')
          json = JSON.parse(response.body)
          expect(json.keys).to eq(['error'])
          expect(json['error']).to eq('Invalid token')
        end

        it '不正なAUDの場合は401が返されること' do
          request.headers['Authorization'] = "Bearer #{invalid_token}"
          get :index
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to include('application/json')
          json = JSON.parse(response.body)
          expect(json.keys).to eq(['error'])
          expect(json['error']).to eq('Invalid token')
        end

        it 'kidがJWKSに存在しない場合は401が返されること' do
          # kid不一致を想定したスタブ
          allow_any_instance_of(Api::ApplicationController).to receive(:decode_cognito_jwt).and_raise(JWT::VerificationError.new('Unknown kid'))

          request.headers['Authorization'] = "Bearer #{invalid_token}"
          get :index
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to include('application/json')
          json = JSON.parse(response.body)
          expect(json.keys).to eq(['error'])
          expect(json['error']).to eq('Invalid token')
        end

        it '有効な署名でもexpが過去の場合は401が返されること' do
          allow_any_instance_of(Api::ApplicationController).to receive(:decode_cognito_jwt).and_raise(JWT::ExpiredSignature)

          request.headers['Authorization'] = "Bearer #{invalid_token}"
          get :index
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to include('application/json')
          json = JSON.parse(response.body)
          expect(json.keys).to eq(['error'])
          expect(json['error']).to eq('Token has expired')
        end

        it 'トークン構造が壊れている、またはアルゴリズム不一致などでJWT::DecodeErrorが発生した場合は401が返されること' do
          allow_any_instance_of(Api::ApplicationController).to receive(:decode_cognito_jwt).and_raise(JWT::DecodeError.new('Not enough or too many segments'))

          # ロガーへの出力を検証
          logger_double = double('Logger').as_null_object
          allow(Rails).to receive(:logger).and_return(logger_double)
          expect(logger_double).to receive(:error).with(/Invalid token|JWT::DecodeError/)

          request.headers['Authorization'] = "Bearer #{invalid_token}"
          get :index
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to include('application/json')
          json = JSON.parse(response.body)
          expect(json.keys).to eq(['error'])
          expect(json['error']).to eq('Invalid token')
        end
      end
    end
  end

  describe '#extract_token_from_header' do
    context 'Authorizationヘッダーが正しい形式の場合' do
      it 'Bearerトークンを正しく抽出すること' do
        request.headers['Authorization'] = 'Bearer valid.token.here'
        expect(controller.send(:extract_token_from_header)).to eq('valid.token.here')
      end

      it 'bearer（小文字）でも正しく抽出すること' do
        request.headers['Authorization'] = 'bearer valid.token.here'
        expect(controller.send(:extract_token_from_header)).to eq('valid.token.here')
      end

      it 'Bearerの後のスペースが複数でも正しく抽出すること' do
        request.headers['Authorization'] = 'Bearer    valid.token.here'
        expect(controller.send(:extract_token_from_header)).to eq('valid.token.here')
      end
    end

    context 'Authorizationヘッダーが不正な形式の場合' do
      it 'Bearerプレフィックスがない場合はnilを返すこと' do
        request.headers['Authorization'] = 'InvalidToken'
        expect(controller.send(:extract_token_from_header)).to be_nil
      end

      it 'ヘッダーが空の場合はnilを返すこと' do
        request.headers['Authorization'] = ''
        expect(controller.send(:extract_token_from_header)).to be_nil
      end

      it 'ヘッダーがnilの場合はnilを返すこと' do
        request.headers['Authorization'] = nil
        expect(controller.send(:extract_token_from_header)).to be_nil
      end

      it 'Bearerの後にトークンがない場合はnilを返すこと' do
        request.headers['Authorization'] = 'Bearer '
        expect(controller.send(:extract_token_from_header)).to be_nil
      end

      it 'bearerの後にトークンがない場合はnilを返すこと' do
        request.headers['Authorization'] = 'bearer '
        expect(controller.send(:extract_token_from_header)).to be_nil
      end

      it 'BEARER（大文字）の後にトークンがない場合はnilを返すこと' do
        request.headers['Authorization'] = 'BEARER '
        expect(controller.send(:extract_token_from_header)).to be_nil
      end
    end

    context 'HTTP_AUTHORIZATION環境変数を使用する場合' do
      it 'HTTP_AUTHORIZATIONからもトークンを抽出できること' do
        request.env['HTTP_AUTHORIZATION'] = 'Bearer valid.token.here'
        expect(controller.send(:extract_token_from_header)).to eq('valid.token.here')
      end

      it 'HTTP_AUTHORIZATIONが空の場合はnilを返すこと' do
        request.env['HTTP_AUTHORIZATION'] = ''
        expect(controller.send(:extract_token_from_header)).to be_nil
      end
    end
  end

  describe 'JWKS キャッシュ' do
    let(:issuer) { "https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['COGNITO_USER_POOL_ID']}" }
    let(:payload) do
      {
        'sub' => 'cache-test-sub',
        'email' => 'cache@example.com',
        'name' => 'Cache User',
        'iss' => issuer,
        'aud' => ENV['COGNITO_APP_CLIENT_ID'],
        'exp' => 1.hour.from_now.to_i
      }
    end
    let(:token) { JWT.encode(payload, nil, 'none', { kid: 'kid-cache' }) }
    let(:jwks_json) { { 'keys' => [{ 'kid' => 'kid-cache', 'kty' => 'RSA', 'n' => 'test-n', 'e' => 'AQAB' }] }.to_json }

    let(:response_double) { instance_double(Net::HTTPResponse, body: jwks_json) }
    let(:http_double) { double('http', get: response_double) }

    before do
      # Switch to in-memory cache store for this test to validate caching
      @original_cache = Rails.cache
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      Rails.cache.delete('cognito_jwks')

      allow(JWT).to receive(:decode).and_return([payload, { 'kid' => 'kid-cache' }])
      allow(JWT::JWK).to receive(:import).and_return(double(public_key: OpenSSL::PKey::RSA.new(2048)))
      allow(Net::HTTP).to receive(:start).and_yield(http_double).and_return(response_double)
    end

    it '1回目はNet::HTTPが呼ばれ、2回目はキャッシュが使われること' do
      expect(Net::HTTP).to receive(:start).once.and_yield(http_double).and_return(response_double)

      # 1回目: キャッシュが無いので HTTP が実行される
      controller.send(:decode_cognito_jwt, token)
      expect(Rails.cache.read('cognito_jwks')).not_to be_nil

      # 2回目: キャッシュがあるので HTTP は呼ばれない
      controller.send(:decode_cognito_jwt, token)
    end

    after do
      # Restore original cache store
      allow(Rails).to receive(:cache).and_return(@original_cache)
    end
  end
end
