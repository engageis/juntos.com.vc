require 'rails_helper'

RSpec.describe UserDecorator do
  let(:user) { create(:user, :individual) }
  before(:all) do
    I18n.locale = :pt
  end

  describe "#contributions_text" do
    subject { user.reload.decorate.contributions_text }

    context "when the user has one contribution" do
      before { create(:contribution, :confirmed, user: user) }

      it { is_expected.to eq("Apoiou somente este projeto até agora") }
    end

    context "when the user has two contribution" do
      before { create_list(:contribution, 2, :confirmed, user: user) }

      it { is_expected.to eq("Apoiou este e mais 1 outro projeto") }
    end

    context "when the user has three contribution" do
      before { create_list(:contribution, 3, :confirmed, user: user) }

      it { is_expected.to eq("Apoiou este e mais outros 2 projetos") }
    end
  end

  describe "#twitter_link" do
    let(:user) { create(:user, twitter: 'twitter_user') }
    subject { user.decorate.twitter_link }

    context "when user has no twitter account" do
      let(:user) { create(:user, twitter: nil) }

      it { is_expected.to be_nil }
    end

    context "when user has twitter account" do
      it { is_expected.to eq("http://twitter.com/twitter_user") }
    end
  end

  describe "#gravatar_url" do
    let(:user) { create(:user, email: 'email@email.com') }
    subject { user.decorate.gravatar_url }

    context "when user has no email" do
      before { user.update_attribute(:email, nil) }

      it { is_expected.to be_nil }
    end

    context "when user has email" do
      it { is_expected.not_to be_nil }
    end
  end

  describe "#display_name" do
    let(:user) { create(:user, name: "name", full_name: "Full Name") }
    subject { user.decorate.display_name }

    context "when the user has a name and a full name" do
      it { is_expected.to eq('name') }
    end

    context "when the user has only have a full name" do
      let(:user) { create(:user, name: nil, full_name: "Full Name") }

      it { is_expected.to eq("Full Name") }
    end

    context "when the user has only a name" do
      let(:user) { create(:user, name: "name", full_name: nil) }

      it { is_expected.to eq("name") }
    end

    context "when the user name is empty string" do
      let(:user) { create(:user, name: "", full_name: "Full Name") }

      it { is_expected.to eq('Full Name') }
    end

    context "when the user has no name" do
      let(:user) { create(:user, name: nil, full_name: nil) }

      it { is_expected.to eq(I18n.t('no_name', scope: 'user')) }
    end
  end

  describe "#display_image" do
    let(:user) { create(:user, image_url: 'image.png') }
    subject { user.decorate.display_image }

    context "when we have an image url" do
      it { is_expected.to eq('image.png') }
    end

    context "when we have an uploaded image" do
      let(:user) { create(:user, uploaded_image: 'image.png') }

      before do
        image = double(url: 'image.png')
        allow(image).to receive(:thumb_avatar).and_return(image)
        allow(user).to receive(:uploaded_image).and_return(image)
      end

      it { is_expected.to eq('image.png') }
    end

    context "when we have an email" do
      let(:user) { create(:user, email: "diogob@gmail.com") }

      it { is_expected.to include("https://gravatar.com/avatar/") }
    end
  end

  describe "#larger_display_image" do
    let(:user) { create(:user, image_url: 'image.png') }
    subject { user.decorate.larger_display_image }

    context "when we have an image url" do
      it { is_expected.to eq('image.png') }
    end

    context "when we have an uploaded image" do
      let(:user) { create(:user, uploaded_image: 'image.png') }

      before do
        image = double(url: 'image.png')
        allow(image).to receive(:larger_thumb_avatar).and_return(image)
        allow(user).to receive(:uploaded_image).and_return(image)
      end

      it { is_expected.to eq('image.png') }
    end

    context "when we have an email" do
      let(:user) { create(:user, email: "diogob@gmail.com") }

      it { is_expected.to include("https://gravatar.com/avatar/") }
    end
  end

  describe "#display_image_html" do
    let(:user)           { build(:user, image_url: "http://image.jpg", uploaded_image: nil )}
    let(:options)        { { width: 300, height: 300 } }
    let(:html_options)   { "width: #{options[:width]}px; height: #{options[:height]}px" }
    let(:html_image_src) { "src=\"#{user.decorate.display_image}" }

    subject { user.decorate.display_image_html(options) }

    it { is_expected.to include(html_options, html_image_src) }
  end

  describe "#short_name" do
    let(:user) { create(:user, name: "My Name Is Lorem Ipsum Dolor Sit Amet") }
    subject    { user.decorate.short_name }

    context "when name length is bigger than 20" do
      it "should return the first 20 name characters only" do
        is_expected.to eq("My Name Is Lorem ...")
      end
    end

    context "when name length is smaller than 20" do
      let(:user) { create(:user, name: "My Name Is") }

      it "should return the entire name" do
        is_expected.to eq("My Name Is")
      end
    end
  end

  describe "#medium_name" do
    let(:user) { create(:user, name: "My Name Is Lorem Ipsum Dolor Sit Amet And This Is") }
    subject { user.decorate.medium_name }

    context "when name length is bigger than 42" do
      it "should return the first 42 name characters only" do
        is_expected.to eq("My Name Is Lorem Ipsum Dolor Sit Amet A...")
      end
    end

    context "when name length is smaller than 42" do
      let(:user) { create(:user, name: "My Name Is Lorem Ipsum") }

      it "should return the entire name" do
        is_expected.to eq("My Name Is Lorem Ipsum")
      end
    end
  end

  describe "#display_credits" do
    subject { user.decorate.display_credits }

    it { is_expected.to eq("R$ 0") }
  end

  describe "#display_total_of_contributions" do
    subject { user.decorate.display_total_of_contributions }

    context "when it has confirmed contributions" do
      before { create(:contribution, :confirmed, user: user, project_value: 500.0) }

      it { is_expected.to eq('R$ 500') }
    end

    context "when it has no confirmed contributions" do
      it { is_expected.to eq('R$ 0') }
    end
  end

  describe "#display_requested_refund_contributions_count" do
    subject { user.reload.decorate.display_requested_refund_contributions_count }

    context "when there is no requested refund contribution" do
      it { is_expected.to be_zero }
    end

    context "when there is one requested refund contribution" do
      before { create(:contribution, :requested_refund, user: user) }

      it { is_expected.to eq(1) }
    end

    context "when there is three requested refund contributions" do
      before { create_list(:contribution, 3, :requested_refund, user: user) }

      it { is_expected.to eq(3) }
    end
  end

  describe "#projects_count" do
    subject { user.decorate.projects_count }

    context "when project's state is online" do
      before  { create(:project, :online, user: user) }

      it { is_expected.to eq(1) }
    end

    context "when project's state is waiting_funds" do
      before { create(:project, :waiting_funds, user: user) }

      it { is_expected.to eq(1) }
    end

    context "when project's state is successful" do
      before { create(:project, :successful, user: user) }

      it { is_expected.to eq(1) }
    end

    context "when project's state is failed" do
      before { create(:project, :failed, user: user) }

      it { is_expected.to eq(1) }
    end

    context "when project's state is deleted" do
      before { create(:project, :deleted, user: user) }

      it { is_expected.to be_zero }
    end
  end

  describe "#display_pending_documents" do
    subject { user.decorate.display_pending_documents }

    context "when user is legal entity" do
      let(:user) { create(:user, :legal_entity) }

      it { is_expected.to be_nil }
    end

    context "when user is individual" do
      before { sign_in user }

      context "and has no ID document" do
        let(:user) { create(:user, :without_id_document) }

        it "should be pending documents" do
          is_expected.to be_kind_of(String)
        end
      end

      context "and has no proof of residence" do
        let(:user) { create(:user, :without_proof_of_residence) }

        it "should be pending documents" do
          is_expected.to be_kind_of(String)
        end
      end

      context "and has ID document" do
        let(:user) { create(:user, :with_id_document, :without_proof_of_residence) }

        context "but has no proof of residence" do
          it "should be pending documents" do
            is_expected.to be_kind_of(String)
          end
        end

        context "and has proof of residence" do
          let(:user) { create(:user, :with_id_document, :with_proof_of_residence) }

          it "should not be pending documents" do
            is_expected.to be_nil
          end
        end
      end
    end
  end

  describe "#display_project_not_approved" do
    subject { user.decorate.display_project_not_approved }

    context "when user is individual" do
      it { is_expected.to be_nil }
    end

    context "when user is legal entity" do
      let(:user) { create(:user, :legal_entity) }
      before     { sign_in user }

      it { is_expected.to be_kind_of(String) }
    end
  end

  describe "#following_this_category" do
    subject { user.decorate.following_this_category?(category.id) }

    context "when there is category for user's project" do
      let(:category_follower) { create(:category_follower, user: user) }
      let(:category)          { category_follower.category }

      it { is_expected.to be_truthy }
    end

    context "when there is no category for user's project" do
      let(:new_user)          { create(:user) }
      let(:category_follower) { create(:category_follower, user: new_user) }
      let(:category)          { category_follower.category }

      it { is_expected.to be_falsey }
    end
  end

  describe "#display_unsuccessful_project_count" do
    subject { user.reload.decorate.display_unsuccessful_project_count }

    context "when there is no failed contributed projects" do
      before { create(:contribution, user: user) }

      it { is_expected.to be_zero }
    end

    context "when there is one failed contributed project" do
      before { create(:failed_contribution_project, user: user) }

      it { is_expected.to eq(1) }
    end

    context "when there are many failed contributed projects" do
      before { create_list(:failed_contribution_project, 8, user: user) }

      it { is_expected.to eq(8) }
    end
  end

  describe "#display_last_unsuccessful_project_expires_at" do
    let(:date)       { DateTime.civil(2000, 2, 15, 1, 59, 59) }
    let(:project)    { create :project, online_date: date, online_days: 5 }
    let(:expires_at) { date + 5.days }

    subject { user.reload.decorate.display_last_unsuccessful_project_expires_at }

    context "when there is no failed contributed projects" do
      before { create(:contribution, user: user) }

      it { is_expected.to be_zero }
    end

    context "when there is one failed contributed project" do
      before { create(:failed_contribution_project, user: user, project: project) }

      it "should return online_date plus online_days" do
        is_expected.to eq((expires_at).to_time.to_i)
      end
    end

    context "when there are many failed contributed project" do
      before do
        create_list(:failed_contribution_project, 7, user: user)
        create(:failed_contribution_project, user: user, project: project)
      end

      it "should display the last unsuccessful project's expire at" do
        is_expected.to eq((expires_at).to_time.to_i)
      end
    end
  end

  describe "#to_analytics_json" do
    let(:user_information) {
      {
        id:                         user.id,
        email:                      user.email,
        total_contributed_projects: user.total_contributed_projects,
        total_created_projects:     user.projects.count,
        created_at:                 user.created_at,
        last_sign_in_at:            user.last_sign_in_at,
        sign_in_count:              user.sign_in_count,
        created_today:              user.created_today?
      }.to_json
    }

    subject { user.decorate.to_analytics_json }

    it "should expect some user information" do
      is_expected.to eq(user_information)
    end
  end

  describe "#to_param" do
    let(:user) { create(:user, id: 1001, name: "user_name") }

    subject { user.decorate.to_param }

    context "when user has name" do
      it "should return the user id and name" do
        is_expected.to eq("1001-user_name")
      end
    end

    context "when user has no name" do
      let(:user) { create(:user, id: 1001, name: nil) }

      it "should return the user id only" do
        is_expected.to eq("1001")
      end
    end
  end

  describe "#display_user_projects_link" do
    subject { user.decorate.display_user_projects_link }

    context "when user has no projects" do
      it { is_expected.to be_nil }
    end

    context "when user has projects" do
      before { create_list(:project, 5, user: user) }

      before { sign_in user }

      it { is_expected.to include("<a href=", "/users/", "#projects") }

      context "and font is smaller" do
        subject { user.decorate.display_user_projects_link('smaller') }

        it { is_expected.to include("fontsize-smaller", "dropdown-link", "w-dropdown-link") }
      end
    end
  end
end
