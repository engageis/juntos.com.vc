require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user)           { create(:user) }
  let(:unfinished_project) { create(:project, :online) }
  let(:successful_project) { create(:project, :online) }
  let(:facebook_provider)  { create :oauth_provider, name: 'facebook' }

  describe '::STAFFS' do
    it 'defines a constant' do
      expect(described_class.const_defined?(:STAFFS)).to be_truthy
    end
  end

  describe '::LEGAL_ENTITY_AUTHORIZATION_DOCUMENTS' do
    it 'defines a constant' do
      expect(described_class.const_defined?(:LEGAL_ENTITY_AUTHORIZATION_DOCUMENTS))
        .to be_truthy
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:channel) }
    it { is_expected.to belong_to(:country) }
    it { is_expected.to have_one(:user_total) }
    it { is_expected.to have_many(:bank_accounts) }
    it { is_expected.to have_many(:credit_cards) }
    it { is_expected.to have_many(:contributions) }
    it { is_expected.to have_many(:authorizations) }
    it { is_expected.to have_many(:channel_posts) }
    it { is_expected.to have_many(:channels_subscribers) }
    it { is_expected.to have_many(:projects) }
    it { is_expected.to have_many(:unsubscribes) }
    it { is_expected.to have_many(:project_posts) }
    it { is_expected.to have_many(:contributed_projects) }
    it { is_expected.to have_many(:category_followers) }
    it { is_expected.to have_many(:categories) }
    it { is_expected.to have_many(:notifications) }
    it { is_expected.to have_many(:recurring_contributions) }
    it { is_expected.to have_and_belong_to_many(:subscriptions) }
  end

  describe "validations" do
    describe "presence validations" do
      it { is_expected.to validate_presence_of(:email) }
      it { is_expected.to validate_presence_of(:access_type) }
    end

    describe "length validations" do
      it { is_expected.to ensure_length_of(:bio).is_at_most(140) }
      it { is_expected.to ensure_length_of(:password).is_at_least(6).is_at_most(128) }
    end

    describe "uniqueness validations" do
      it { is_expected.to validate_uniqueness_of(:email) }
    end

    describe "format validations" do
      it { is_expected.to allow_value('foo@bar.com').for(:email) }
      it { is_expected.not_to allow_value('foo').for(:email) }
      it { is_expected.not_to allow_value('foo@bar').for(:email) }
    end
  end

  describe '.staff_descriptions' do
    let(:staff_attributes) do
      [
        User.human_attribute_name('staff.team'),
        User.human_attribute_name('staff.financial_board'),
        User.human_attribute_name('staff.technical_board'),
        User.human_attribute_name('staff.advice_board'),
      ]
    end

    it "should return an array matching all the STAFF's constant keys" do
      expect(described_class.staff_descriptions).to match(staff_attributes)
    end
  end

  describe ".find_first_active" do
    let!(:deactivated_user) { create(:user, :deactivated) }

    it "should raise error when user is inactive" do
      expect { User.find_first_active(deactivated_user) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return user when active" do
      expect(User.find_first_active(user.id)).to eq(user)
    end
  end

  describe ".staff_members_query" do
    subject { User.staff_members_query }

    it { is_expected.to include("staffs @>", "ARRAY[") }
  end

  describe ".active" do
    subject { User.active }

    context "when there is no deactivated user" do
      it { is_expected.to contain_exactly(user) }
    end

    context "when there are deactivated users" do
      before do
        create_list(:user, 3, :deactivated)
      end

      it { is_expected.to contain_exactly(user) }
    end
  end

  describe ".staff" do
    subject { User.staff }

    context "when the user is a staff member" do
      let(:staff_member) { create :user, staffs: [1] }

      it { is_expected.to include(staff_member) }
    end

    context "when the user is not a staff member" do
      let(:non_staff_user) { create :user }

      it { is_expected.not_to include(non_staff_user) }
    end
  end

  describe ".has_credits" do
    let!(:failed_contribution_project) { create(:contribution, project_value: 200, state: 'confirmed', user: user) }

    subject { User.has_credits }

    context "when project fails" do
      let!(:failed_contribution_project) { create(:failed_contribution_project, project_value: 200, state: 'confirmed', user: user) }

      it "the user should have credits" do
        is_expected.to eq([user])
      end
    end

    context "when project does not fail" do
      it "the user should not have credits" do
        is_expected.to eq([])
      end
    end
  end

  describe ".only_organizations" do
    let!(:individual_users) { create_list(:user, 3, :individual) }
    let!(:legal_entity_users) { create_list(:user, 3, :legal_entity) }

    subject { User.only_organizations }

    context "when user is individual" do
      it "should not return individual_users" do
        is_expected.not_to match_array(individual_users)
      end
    end

    context "when user is legal entity" do
      it "should return legal_entity" do
        is_expected.to match_array(legal_entity_users)
      end
    end
  end

  describe ".by_email" do
    let!(:user) { create(:user, email: 'foo@bar.com') }
    let!(:user_2) { create(:user, email: 'another_email@bar.com') }

    subject { User.by_email('foo@bar') }

    it { is_expected.to eq([user]) }
  end

  describe ".order_by" do
    let!(:user_z) { create(:user, name: 'Ze Joseph') }
    let!(:user_b) { create(:user, name: 'Bruno Bar') }
    let!(:user_j) { create(:user, name: 'Joana Francisco') }
    let!(:user_a) { create(:user, name: 'Aluisio Moura') }

    context "when order by name" do
      it "should return a name ordained list of users" do
        expect(User.order_by(:name)).to eq([user_a, user_b, user_j, user_z])
      end
    end

    context "when order by id" do
      it "should return an id ordained list of users" do
        expect(User.order_by(:id)).to eq([user_z, user_b, user_j, user_a])
      end
    end
  end

  describe ".by_name" do
    let(:user) { create(:user, name: 'Baz Qux') }
    let!(:users) { create_list(:user, 4) }

    subject { User.by_name('Baz') }

    it { is_expected.to eq([user]) }
  end

  describe ".by_id" do
    before { create_list(:user, 5) }

    subject { User.by_id(user.id) }

    it { is_expected.to eq([user]) }
  end

  describe ".by_contribution_key" do
    let(:contribution) { create(:contribution, user: user) }
    let(:contribution_second) { create(:contribution, user: user) }
    let(:contribution_third) { create(:contribution, user: user) }

    before do
      contribution.key = 'abc'
      contribution.save!

      contribution_second.key = 'abcde'
      contribution_second.save!

      contribution_third.key = 'def'
      contribution_third.save!
    end

    subject { User.by_contribution_key('def') }

    it { is_expected.to eq([contribution.user]) }
  end

  describe ".subscribed_to_posts" do
    subject { User.subscribed_to_posts }

    context "when a user has not unsubscribed to all projects" do
      it { is_expected.to eq([user]) }
    end

    context "when a user has unsubscribed to all projects" do
      let!(:unsubscribe) { create(:unsubscribe, project: nil, user: user ) }
      let!(:users) { create_list(:user, 4) }

      it { is_expected.to match_array(users) }
    end
  end

  describe ".failed_contributed_projects" do
    let!(:failed_contribution_project) { create(:contribution, user: user) }
    subject { user.failed_contributed_projects }

    context "when there is no failed project" do
      it { is_expected.to eq([]) }
    end

    context "when there is one failed contributed project" do
      let(:failed_contribution_project) { create(:failed_contribution_project, user: user) }

      it { is_expected.to eq([failed_contribution_project.project]) }
    end

    context "when there are many failed contributed projects" do
      let(:failed_contribution_projects) { create_list(:failed_contribution_project, 4, user: user) }
      let(:failed_projects) { failed_contribution_projects.map(&:project) }

      it { is_expected.to match_array(failed_projects) }
    end
  end

  describe ".with_project_contributions_in" do
    let(:contribution) { create(:contribution, state: 'confirmed', project: successful_project) }

    subject { User.with_project_contributions_in(successful_project) }

    context "when there are pending projects" do
      before do
        create_list(:contribution, 3, state: 'pending', project: successful_project)
      end

      it { is_expected.to eq([]) }
    end

    context "when a single user has contributed on many projects" do
      before do
        create_list(:contribution, 4, state: 'confirmed', project: successful_project, user: contribution.user)
      end

      it { is_expected.to eq([contribution.user]) }
    end
  end

  describe ".with_visible_projects" do
    let(:users_with_visible_project) { create_list(:user, 3) }

    before do
      create(:project, state: 'draft')
      create(:project, state: 'rejected')
      create(:project, state: 'deleted')
      create(:project, state: 'in_analysis')
      create(:project, :online, user: users_with_visible_project[0])
      create(:project, user: users_with_visible_project[1], state: 'successful')
      create(:project, user: users_with_visible_project[2], state: 'waiting_funds')
    end

    subject { User.with_visible_projects }

    it "should return only users who has visible projects" do
      is_expected.to match_array(users_with_visible_project)
    end
  end

  describe ".by_payer_email" do
    let(:payment_notification) { create(:payment_notification) }
    let(:payment_notification_second) { create(:payment_notification) }
    let(:payment_notification_third) { create(:payment_notification) }

    before do
      payment_notification.extra_data = { 'payer_email' => 'foo@bar.com' }
      payment_notification.save!

      payment_notification_second.extra_data = { 'payer_email' => 'another_email@bar.com' }
      payment_notification_second.save!

      payment_notification_third.extra_data = { 'payer_email' => 'another_email@bar.com' }
      payment_notification_third.save!
    end

    subject { User.by_payer_email('foo@bar.com') }

    it { is_expected.to eq([payment_notification.contribution.user]) }
  end

  describe ".to_send_category_notification" do
    let(:category) { create(:category) }
    let(:user_second) { create(:user) }
    let(:user_third) { create(:user) }

    before do
      create(:project, category: category, user: user)
      category.users << user_second
      category.users << user_third
      category.deliver_projects_of_week_notification
      category.users << user
    end

    subject { User.to_send_category_notification(category.id) }

    it { is_expected.to eq([user]) }
  end

  describe ".already_used_credits" do
    let!(:failed_contribution_project) { create(:failed_contribution_project, project_value: 1000, user: user) }
    subject { User.already_used_credits }

    context "when the user contributes using credit as payment_method" do
      before do
        create(:contribution, project_value: 100, payment_method: 'credits', user: user)
      end

      it { is_expected.to eq([user]) }
    end

    context "when the user has not use its credits" do
      it { is_expected.to eq([]) }
    end
  end

  describe ".has_not_used_credits_last_month" do
    let!(:failed_contribution_project) { create(:failed_contribution_project, state: 'confirmed', value: 100, payment_method: 'credits', user: user) }
    subject { User.has_not_used_credits_last_month }

    context "when user has used credits in the last month" do
      it { is_expected.to eq([]) }
    end

    context "when user has not used credits in the last month" do
      before { failed_contribution_project.update_attribute(:created_at, Time.now-2.month) }

      it { is_expected.to eq([user]) }
    end
  end

  describe ".create" do
    subject do
      User.create! do |u|
        u.email = 'diogob@gmail.com'
        u.password = '123456'
        u.twitter = '@dbiazus'
        u.facebook_link = 'facebook.com/test'
      end
    end
    its(:twitter) { should == 'dbiazus' }
    its(:facebook_link) { should == 'http://facebook.com/test' }
  end

  describe "#change_locale" do
    let(:user) { create(:user, locale: 'pt') }

    context "when user already has a locale" do
      before { expect(user).not_to receive(:update_attribute).with(:locale, 'pt') }

      it { user.change_locale('pt') }
    end

    context "when locale is diff from the user locale" do
      before { expect(user).to receive(:update_attribute).with(:locale, 'en') }

      it { user.change_locale('en') }
    end
  end

  describe "#notify" do
    before do
      user.notify(:heartbleed)
    end

    context "when creating notification" do
      before { @notification = UserNotification.last }

      it { expect(@notification.user).to eq(user) }
      it { expect(@notification.template_name).to eq('heartbleed') }
    end
  end

  describe "#reactivate" do
    before do
      user.deactivate
      user.reactivate
    end

    it "should set reatiactivate_token to nil" do
      expect(user.reactivate_token).to be_nil
    end

    it "should set deactivated_at to nil" do
      expect(user.deactivated_at).to be_nil
    end
  end

  describe "#deactivate" do
    before do
      @contribution = create(:contribution, user: user, anonymous: false)
      user.deactivate
    end

    it "should send user_deactivate notification" do
      expect(UserNotification.last.template_name).to eq('user_deactivate')
    end

    it "should set all contributions as anonymous" do
      expect(@contribution.reload.anonymous).to be_truthy
    end

    it "should set reatiactivate_token" do
      expect(user.reactivate_token).to be_present
    end

    it "should set deactivated_at" do
      expect(user.deactivated_at).to be_present
    end
  end

  describe "#total_contributed_projects" do
    subject { user.total_contributed_projects }

    before do
      create(:contribution, state: 'confirmed', user: user, project: successful_project)
      create(:contribution, state: 'confirmed', user: user, project: successful_project)
      create(:contribution, state: 'confirmed', user: user, project: successful_project)
      create(:contribution, state: 'confirmed', user: user)
      user.reload
    end

    it { is_expected.to eq(2) }
  end

  describe "#created_today?" do
    subject { user.created_today? }

    context "when user is created today and not sign in yet" do
      before do
        allow(user).to receive(:created_at).and_return(Date.today)
        allow(user).to receive(:sign_in_count).and_return(0)
      end

      it { is_expected.to be_truthy }
    end

    context "when user is created today and already signed in more that once time" do
      before do
        allow(user).to receive(:created_at).and_return(Date.today)
        allow(user).to receive(:sign_in_count).and_return(2)
      end

      it { is_expected.to be_falsey }
    end

    context "when user is created yesterday and not sign in yet" do
      before do
        allow(user).to receive(:created_at).and_return(Date.yesterday)
        allow(user).to receive(:sign_in_count).and_return(1)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe "#to_analytics_json" do
    subject { user.decorate.to_analytics_json }

    it do
      is_expected.to eq({
        id: user.id,
        email: user.email,
        total_contributed_projects: user.total_contributed_projects,
        total_created_projects: user.projects.count,
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
        sign_in_count: user.sign_in_count,
        created_today: user.created_today?
      }.to_json)
    end
  end

  describe "#credits" do
    before do
      create(:contribution, state: 'confirmed', credits: false, project_value: 100, user_id: user.id, project: successful_project)
      create(:contribution, state: 'confirmed', credits: false, project_value: 100, user_id: user.id, project: unfinished_project)
      create(:failed_contribution_project, state: 'confirmed', credits: false, project_value: 200, user_id: user.id)
      create(:contribution, state: 'confirmed', credits: true, project_value: 100, user_id: user.id, project: successful_project)
      create(:contribution, state: 'confirmed', credits: true, project_value: 50, user_id: user.id, project: unfinished_project)
      create(:failed_contribution_project, state: 'confirmed', credits: true, project_value: 100, user_id: user.id)
      create(:failed_contribution_project, state: 'requested_refund', credits: false, project_value: 200, user_id: user.id)
      create(:failed_contribution_project, state: 'refunded', credits: false, project_value: 200, user_id: user.id)
      successful_project.update_attribute(:state, 'successful')
    end

    subject { user.credits }

    it { is_expected.to eq(50.0) }
  end

  describe "#update_attributes" do
    context "when I try to update moip_login" do
      before do
        user.update_attribute(:moip_login, 'test')
      end

      it("should perform the update") { expect(user.moip_login).to eq('test') }
    end
  end

  describe "#recommended_project" do
    subject { user.recommended_projects }

    before do
      other_contribution = create(:contribution, state: 'confirmed')
      create(:contribution, state: 'confirmed', user: other_contribution.user, project: unfinished_project)
      create(:contribution, state: 'confirmed', user: user, project: other_contribution.project)
    end

    it { is_expected.to eq([unfinished_project]) }
  end

  describe "#posts_subscription" do
    let(:unsubscribe) { create(:unsubscribe, project: nil, user: user) }
    subject { user.posts_subscription }

    context "when user is subscribed to all projects" do
      it { is_expected.to be_new_record }
    end

    context "when user is unsubscribed from all projects" do
      before { unsubscribe }

      it { is_expected.to eq(unsubscribe) }
    end
  end

  describe "#project_unsubscribes" do
    let(:unsubscribe) { create(:unsubscribe, project: successful_project, user: user) }
    subject { user.project_unsubscribes }

    before do
      create(:contribution, user: user, project: successful_project)
      unsubscribe
    end

    it { is_expected.to eq([unsubscribe]) }
  end

  describe "#contributed_projects" do
    subject { user.contributed_projects }

    before { create_list(:contribution, 2, user: user, project: successful_project) }

    it { is_expected.to eq([successful_project]) }
  end

  describe "#fix_facebook_link" do
    subject { user.facebook_link }

    context "when user provides invalid url" do
      let(:user) { create(:user, facebook_link: 'facebook.com/foo') }

      it { is_expected.to eq('http://facebook.com/foo') }
    end

    context "when user provides valid url" do
      let(:user) { create(:user, facebook_link: 'http://facebook.com/foo') }

      it { is_expected.to eq('http://facebook.com/foo') }
    end
  end

  describe "#made_any_contribution_for_this_project?" do
    subject { user.made_any_contribution_for_this_project?(successful_project.id) }

    context "when user have contributions for the project" do
      before do
        create(:contribution, project: successful_project, state: 'confirmed', user: user)
      end

      it { is_expected.to be_truthy }
    end

    context "when user don't have contributions for the project" do
      it { is_expected.to be_falsey }
    end
  end

  describe "#following_this_category?" do
    let(:category)       { create(:category) }
    let(:category_extra) { create(:category) }
    let(:user) { create(:user) }

    subject { user.decorate.following_this_category?(category.id) }

    context "when is following the category" do
      before do
        user.categories << category
      end

      it { is_expected.to be_truthy }
    end

    context "when not following the category" do
      before do
        user.categories << category_extra
      end

      it { is_expected.to be_falsey }
    end

    context "when not following any category" do
      it { is_expected.to be_falsey }
    end
  end

  describe '#documents_list' do
    subject { user.documents_list }

    context 'when user is a legal entity' do
      let(:user) { create :user, access_type: 'legal_entity' }
      let(:legal_entity_documents) do
        (1..13).map { |n| "original_doc#{n}_url".to_sym }
      end

      it { is_expected.to match_array(legal_entity_documents) }
    end

    context 'when user is an individual' do
      let(:user) { create :user, access_type: 'individual' }
      let(:individual_documents) { [:original_doc12_url, :original_doc13_url] }

      it { is_expected.to match_array(individual_documents) }
    end
  end

  describe ".subscribed_to_project" do
    let(:project) { create(:project) }
    let(:contribution) { create(:contribution, state: 'confirmed', project: project) }

    subject { User.subscribed_to_project(project) }

    context "when a user has no project" do
      it { should eq([contribution.user]) }
    end

    context "when a user has unsubscribed to project" do
      before do
        contribution
        create(:unsubscribe, project_id: project.id, user: user)
      end

      it { is_expected.to eq([contribution.user]) }
    end
  end
end
