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
    describe "request status" do
      before do
        get :index, locale: :pt
      end

      it { is_expected.to be_success }

      context "with referal link" do
        subject { controller.session[:referal_link] }

        before do
          get :index, locale: :pt, ref: 'referal'
        end

        it { is_expected.to eq('referal') }
      end
    end

    describe "variables instantiating" do
      describe "projects visibility" do
        context "@projects" do
          before do
            projects = Project.all
            allow(Project).to receive(:all).and_return(projects)
            allow(Project).to receive(:with_visible_channel_and_without_channel).and_return(projects)
            get :index, locale: :pt
          end

          context "when there is a logged user" do
            context "and the user is admin" do
              let(:current_user) { create(:user, admin: true).decorate }

              it { expect(Project).to have_received(:all).at_least(:once) }

              it { expect(Project).not_to have_received(:with_visible_channel_and_without_channel) }
            end

            context "and the user is not admin" do
              let(:current_user) { create(:user, admin: false).decorate }

              it { expect(Project).to have_received(:with_visible_channel_and_without_channel).once }
            end
          end

          context "when there is no logged user" do
            let(:current_user) { nil }

            it { expect(Project).to have_received(:with_visible_channel_and_without_channel).once }
          end
        end
      end

      context "when it's an ajax request" do
        before do
          create_list(:project, 10)
          projects = Project.all
          allow(Project).to receive(:visible).and_return(projects)
          allow(Project).to receive(:order_status).and_return(projects)
          allow(Project).to receive(:most_recent_first).and_return(projects)
          xhr :get, :index, locale: :pt
        end

        it "returns the visible projects" do
          expect(Project).to have_received(:visible).once
        end

        it "returns the projects ordered by status" do
          expect(Project).to have_received(:order_status).once
        end

        it "returns the most recent first projects" do
          expect(Project).to have_received(:most_recent_first).once
        end

        it "returns only six projects per page" do
          expect(assigns(:projects).count).to eq(6)
        end

        it "renders the project partial" do
          expect(response).to render_template(partial: '_project')
        end

        it "renders no layout" do
          expect(response).to render_template(layout: [])
        end
      end

      context "@index_scope" do
        before do
          projects     = Project.all
          current_user = create(:user)
          index_scope  = Project::IndexScope.new(projects, current_user)

          allow(Project::IndexScope).to receive(:new).and_return(index_scope)
          get :index, locale: :pt
        end

        it "calls the index scope to instante the index variables" do
          expect(Project::IndexScope).to have_received(:new).once
        end
      end
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
        { permalink: 'updated_permalink' }
      end

      before do
        put :update, id: project.id, project: project_attributes, locale: :pt
        project.reload
      end

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

  describe "GET permalink_valid?" do
    let(:permalink) { "peramlink_taken" }

    subject { JSON.parse(response.body) }

    context "when the permalink is already taken" do
      let(:project) { create(:project) }

      before do
        create(:project, permalink: permalink)
        get :permalink_valid?, permalink: permalink, project_id: project.id, locale: :pt, format: :js
      end

      it { expect(subject["available_permalink"]).to be_falsey }
    end

    context "when the permalink is available" do
      let(:project) { create(:project, permalink: permalink) }

      before do
        get :permalink_valid?, permalink: permalink, project_id: project.id, locale: :pt, format: :js
      end

      it { expect(subject["available_permalink"]).to be_truthy }
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
