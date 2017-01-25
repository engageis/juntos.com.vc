#encoding:utf-8
require 'rails_helper'

RSpec.describe ProjectsController, type: :controller do
  before{ allow(controller).to receive(:current_user).and_return(current_user) }
  before{ CatarseSettings[:base_url] = 'http://catarse.me' }
  before{ CatarseSettings[:email_projects] = 'foo@bar.com' }
  render_views
  subject{ response }
  let(:project){ create(:project, state: 'draft') }
  let(:current_user){ nil }

  describe "POST create" do
    let(:project){ build(:project) }
    before do
      post :create, { locale: :pt, project: project.attributes }
    end

    context "when no user is logged in" do
      it{ is_expected.to redirect_to new_user_registration_path }
    end

    context "when user is logged in" do
      let(:current_user){ create(:user) }
      it{ is_expected.to redirect_to project_by_slug_path(project.permalink, anchor: 'basics') }
    end
  end

  describe "GET send_to_analysis" do
    let(:current_user){ project.user }

    context "without referal link" do
      before do
        get :send_to_analysis, id: project.id, locale: :pt
        project.reload
      end

      it { expect(project.in_analysis?).to eq(true) }
    end

    context "with referal link" do
      subject { project.referal_link }
      before do
        get :send_to_analysis, id: project.id, locale: :pt, ref: 'referal'
        project.reload
      end

      it { is_expected.to eq('referal') }
    end
  end

  describe "GET index" do
    before do
      get :index, locale: :pt
    end
    xit { is_expected.to be_success }

    context "with referal link" do
      subject { controller.session[:referal_link] }

      before do
        get :index, locale: :pt, ref: 'referal'
      end

      xit { is_expected.to eq('referal') }
    end
  end

  describe "GET new" do
    before { get :new, locale: :pt }

    context "when user is a guest" do
      it { is_expected.not_to be_success }
    end

    context "when user is a registered user" do
      let(:user) { create(:user, admin: false) }
      let(:current_user) { user.decorate }
      it { is_expected.to be_success }
    end
  end

  describe "PUT update" do
    shared_examples_for "updatable project" do
      context "with valid permalink" do
        before { put :update, id: project.id, project: { name: 'My Updated Title' }, locale: :pt }
        it {
          project.reload
          expect(project.name).to eq('My Updated Title')
        }

        xit{ is_expected.to redirect_to project_by_slug_path(project.permalink, anchor: 'edit') }
      end

      context "with invalid permalink" do
        before { put :update, id: project.id, project: { permalink: '', name: 'My Updated Title' },locale: :pt }

        xit{ is_expected.to redirect_to project_by_slug_path(project.permalink, anchor: 'edit') }
      end
    end

    shared_examples_for "protected project" do
      let(:project_attributes) do
        {
          headline:  'updated_headline',
          name:      'updated_name',
          permalink: 'updated_permalink'
        }
      end

      before do
        put :update, id: project.id, project: project_attributes, locale: :pt
        project.reload
      end

      it { expect(project.headline).not_to eq('updated_headline') }

      it { expect(project.name).not_to eq('updated_name') }

      it { expect(project.permalink).not_to eq('updated_permalink') }
    end

    context "when user is a guest" do
      let(:project) { create(:project, :draft) }

      it_should_behave_like "protected project"
    end

    context "when user is a project owner" do
      let(:current_user) { project.user }

      context "and the project is offline" do
        it_should_behave_like "updatable project"
      end

      context "and the project is online" do
        let(:project) { create(:project, :online) }

        it_should_behave_like "protected project"
      end
    end

    context "when user is a registered user" do
      let(:current_user) { create(:user, admin: false) }
      let(:project)      { create(:project, :online) }

      it_should_behave_like "protected project"
    end

    context "when user is an admin" do
      let(:current_user){ create(:user, admin: true) }
      it_should_behave_like "updatable project"
    end
  end

  describe "GET embed" do
    before do
      get :embed, id: project, locale: :pt
    end
    its(:status){ should == 200 }
  end

  describe "GET embed_panel" do
    before do
      get :embed_panel, id: project, locale: :pt
    end
    its(:status){ should == 200 }
  end

  describe "GET show" do
    context "when we have update_id in the querystring" do
      let(:project){ create(:project) }
      let(:project_post){ create(:project_post, project: project) }
      before{ get :show, permalink: project.permalink, project_post_id: project_post.id, locale: :pt }
      it("should assign update to @update"){ expect(assigns(:post)).to eq(project_post) }
    end
  end

  describe "GET video" do
    context 'url is a valid video' do
      let(:video_url){ 'http://vimeo.com/17298435' }
      before do
        allow(VideoInfo).to receive(:get).and_return({video_id: 'abcd'})
        get :video, locale: :pt, url: video_url
      end

      its(:body){ should == VideoInfo.get(video_url).to_json }
    end

    context 'url is not a valid video' do
      before { get :video, locale: :pt, url: 'http://????' }

      its(:body){ should == nil.to_json }
    end
  end

  describe "online_days" do
    context "when has a value greater than 60" do
      let(:online_days_error_message) {
        I18n.t('activerecord.attributes.project.online_days') + ' ' + \
        I18n.t('activerecord.errors.models.project.attributes.online_days.less_than_or_equal_to')
      }

      before(:each) do
        user_decorated = UserDecorator.new(user)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user_decorated)
      end

      context "when the request is a POST" do
        before do
          post :create, { locale: :pt, project: project.attributes }
        end

        context "when the current_user is a juntos' admin" do
          let(:user) { create(:user, admin: true) }
          let(:project) { build(:project, permalink: 'available_permalink', online_days: 61) }

          it "should not show any error message" do
            expect(flash[:alert]).to be_nil
          end
        end

        context "when the current_user is a normal user" do
          let(:user) { create(:user, admin: false) }
          let(:project) { build(:project, permalink: 'other_available_permalink', online_days: 61) }

          it "should return a flash error message for the online_days field" do
            expect(flash[:alert]).to match online_days_error_message
          end

          it "should redirect back to projects new path" do
            is_expected.to render_template('projects/new')
          end
        end
      end

      context "when the request is a PUT" do
        context 'and it updates the online_days' do
          let(:project) { create(:project, :draft, online_days: 15, user: user) }

          before(:each) do
            put :update, id: project.id, project: { online_days: 61 }, locale: :pt
          end

          context "when the current_user is a juntos' admin" do
            let(:user) { create(:user, admin: true) }

            it "should not show any error message" do
              expect(flash[:alert]).to be_nil
            end
          end

          context "when the current_user is a normal user" do
            let(:user) { create(:user, admin: false) }

            it 'should return a flash error message for the online_days field' do
              expect(flash[:alert]).to match online_days_error_message
            end
          end
        end
      end
    end
  end
end
