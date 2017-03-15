require 'rails_helper'

RSpec.describe Channels::ProfilesController, type: :controller do
  describe "GET show" do
    let (:channel) { create(:channel) }

    it 'should return status 200' do
      allow(request).to receive(:subdomain).and_return(channel.permalink)
      get :show, id: 'sample', locale: 'pt'
      expect(response).to be_success
    end

    context "when it is a recurring channel" do
      context "when there is a logged user" do
        let(:user) { create(:user, projects: [project]) }
        let(:channel) { create(:channel, :recurring) }

        before do
          allow(request).to receive(:subdomain).and_return(channel.permalink)
          sign_in user
          get :show, locale: 'pt'
        end

        context "and the user is the owner of a recurring project" do
          let(:project) { build(:project, channels: [channel]) }

          it "redirects to the channel's profile path" do
            expect(response).to render_template :show
          end
        end

        context "and the user does not have recurring projects" do
          let(:project) { build(:project) }

          it "redirects to the channel's policy path" do
            expect(response).to redirect_to channels_about_path
          end
        end
      end

      context "when the user is a guest" do
        before do
          allow(request).to receive(:subdomain).and_return(channel.permalink)
          get :show, locale: 'pt'
        end

        it "redirects to the channel's policy path" do
          expect(response).to render_template :show
        end
      end
    end
  end

  describe "PUT update" do
    let (:user)    { create(:user, admin: true) }
    let (:channel) { create(:channel, users: [user]) }

    before do
      allow(request).to receive(:subdomain).and_return(channel.permalink)
      sign_in user
      put :update, id: channel.permalink, locale: 'pt', profile: params
    end

    context "when invalid params are sent" do
      let(:params) { { name: '' } }
      let(:error_message) do
        I18n.t('activerecord.attributes.channel.name') + ' ' + \
        I18n.t('activerecord.errors.messages.blank')
      end

      it "renders the edit view" do
        expect(response).to render_template(:edit)
      end

      it "returns an error flash message" do
        expect(flash[:alert]).to match error_message
      end
    end

    context "when all params sent are valid" do
      let(:params) { { name: 'Foo Channel', ga_code: '<script></script>' } }
      let(:updated_channel) { Channel.find(channel.id) }

      it "updates the channel" do
        expect(updated_channel)
          .to have_attributes(name: 'Foo Channel', ga_code: '<script></script>')
      end

      it "redirects to channel's profile view" do
        expect(response).to redirect_to channels_profile_path(channel)
      end

      it "returns a success flash message" do
        expect(flash[:notice]).to match I18n.t('success', scope: 'channels.profiles.update')
      end
    end
  end
end
