# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe :from_oauth do
    let! :provider do
      AuthProviders::Facebook.new
    end

    let! :oauth_data do
      {
        email: 'test@example.com',
        name: 'Test User',
        id: '123'
      }
    end

    context 'when user does not exist' do
      context 'and requested oauth provider requires email confirmation' do
        it 'creates the user, but with user will need to confirm email' do
          result = User.from_oauth(
            oauth_data,
            AuthProviders::Patreon.new
          )

          expect(result.id).to_not eq(nil)
          expect(result.errors.empty?).to eq(true)
          expect(result.active_for_authentication?).to eq(false)
        end
      end

      context 'and requested oauth provider does not require email confirmation' do
        it 'creates the user, who is active for authentication' do
          result = User.from_oauth(
            oauth_data,
            provider
          )

          expect(result.id).to_not eq(nil)
          expect(result.errors.empty?).to eq(true)
          expect(result.active_for_authentication?).to eq(true)
        end
      end
    end

    context 'when user exists' do
      let! :user do
        User.create(
          email: oauth_data[:email],
          password: 'password123'
        )
      end

      context 'and requested oauth provider is in the system' do
        let! :user_oauth do
          user.user_o_auth_providers.create(
            oauth_id: oauth_data[:id],
            provider: provider.provider_name,
            confirmed_at: DateTime.now
          )
        end

        context 'and request matches the data' do
          it 'should return a user with no errors' do
            result = User.from_oauth(oauth_data, provider)
            expect(result.id).to eq(user.id)
            expect(result.errors.empty?).to eq(true)
          end
        end

        context 'and request does not match the data' do
          it 'should return a user with errors' do
            result = User.from_oauth(
              oauth_data.merge(id: 'bad_id'),
              provider
            )

            expect(result.id).to eq(user.id)
            expect(result.errors.empty?).to eq(false)
          end
        end
      end

      context 'and requested oauth provider is not in the system' do
        context 'when provider does not require confirmation' do
          it 'adds oauth provider to the user, and authenticates them' do
            before_count = UserOAuthProvider.count

            result = User.from_oauth(
              oauth_data,
              provider
            )

            expect(result.id).to eq(user.id)
            expect(result.errors.empty?).to eq(true)
            expect(UserOAuthProvider.count).to eq(before_count + 1)
          end
        end

        context 'when provider does require confirmation' do
          it 'links the provider to the user and returns the user with an error' do
            before_count = UserOAuthProvider.count

            result = User.from_oauth(
              oauth_data,
              AuthProviders::Patreon.new
            )

            expect(result.id).to eq(user.id)
            expect(result.errors.empty?).to eq(false)
            expect(UserOAuthProvider.count).to eq(before_count + 1)
            expect(UserOAuthProvider.last.confirmed?).to eq(false)
          end
        end
      end
    end
  end
end
