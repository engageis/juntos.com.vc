# coding: utf-8
require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe Project, type: :model do
  let(:project){ build(:project, goal: 3000) }
  let(:user){ create(:user) }
  let(:channel){ create(:channel, users: [ user ]) }
  let(:channel_project){ create(:project, channels: [ channel ]) }

  describe "associations" do
    it{ is_expected.to belong_to :user }
    it{ is_expected.to belong_to :category }
    it{ is_expected.to have_many :contributions }
    it{ is_expected.to have_one  :project_total }
    it{ is_expected.to have_many :rewards }
    it{ is_expected.to have_many :posts }
    it{ is_expected.to have_many :notifications }
    it{ is_expected.to have_many :subscriptions }
    it{ is_expected.to have_and_belong_to_many :channels }
    it{ is_expected.to have_and_belong_to_many(:plans) }
  end

  describe "validations" do
    %w[name user category permalink].each do |field|
      it{ is_expected.to validate_presence_of field }
    end
    it{ is_expected.to validate_numericality_of(:goal) }
    it{ is_expected.to allow_value(10).for(:goal) }
    it{ is_expected.not_to allow_value(8).for(:goal) }
    it{ is_expected.to ensure_length_of(:headline).is_at_most(140).is_at_least(1) }
    it{ is_expected.to allow_value('http://vimeo.com/12111').for(:video_url) }
    it{ is_expected.to allow_value('vimeo.com/12111').for(:video_url) }
    it{ is_expected.to allow_value('https://vimeo.com/12111').for(:video_url) }
    it{ is_expected.to allow_value('http://youtube.com/watch?v=UyU-xI').for(:video_url) }
    it{ is_expected.to allow_value('youtube.com/watch?v=UyU-xI').for(:video_url) }
    it{ is_expected.to allow_value('https://youtube.com/watch?v=UyU-xI').for(:video_url) }
    it{ is_expected.not_to allow_value('http://www.foo.bar').for(:video_url) }
    it{ is_expected.to allow_value('testproject').for(:permalink) }
    it{ is_expected.to allow_value(1).for(:online_days) }
    it{ is_expected.not_to allow_value(0).for(:online_days) }
    it{ is_expected.not_to allow_value(61).for(:online_days) }
    xit{ is_expected.not_to allow_value('users').for(:permalink) }

    describe "plans" do
      let(:plan) { create(:plan) }
      subject { build(:project, channels: [channel], plans: [plan]) }

      context "when the project is recurring" do
        let(:channel) { create(:channel, :recurring) }

        it "can has associated plans" do
          expect(subject).to be_valid
        end
      end

      context "when the project is not recurring" do
        let(:channel) { create(:channel) }

        it "cannot has associated plans" do
          expect(subject).to be_invalid
        end
      end
    end
  end

  describe ".of_current_week" do
    subject { Project.of_current_week }
    before do
      3.times { create(:project, state: 'online', online_date: DateTime.now) }
      3.times { create(:project, state: 'draft', online_date: 3.days.ago) }
      3.times { create(:project, state: 'successful', online_date: 6.days.ago) }
      5.times { create(:project, state: 'online', online_date: 8.days.ago) }
      5.times { create(:project, state: 'online', online_date: 2.weeks.ago) }
      2.times { create(:project, state: 'in_analysis', online_date: 3.days.from_now)}
    end

    it "should return a collection with projects of current week" do
      is_expected.to have(11).itens
    end
  end

  describe ".expiring_in_less_of" do
    subject { Project.expiring_in_less_of('7 days') }

    before do
      @project_01 = create(:project, state: 'online', online_date: DateTime.now, online_days: 3)
      @project_02 = create(:project, state: 'online', online_date: DateTime.now, online_days: 30)
      @project_03 = create(:project, state: 'draft')
      @project_04 = create(:project, state: 'online', online_date: DateTime.now, online_days: 3)
    end

    it "should return a collection with projects that is expiring time less of the time in param" do
      is_expected.to eq([@project_01, @project_04])
    end
  end

  describe ".with_contributions_confirmed_today" do
    let(:project_01) { create(:project, state: 'online') }
    let(:project_02) { create(:project, state: 'online') }
    let(:project_03) { create(:project, state: 'online') }

    subject { Project.with_contributions_confirmed_today }

    before do
      project_01
      project_02
      project_03
    end

    context "when have confirmed contributions today" do
      before do

        #TODO: need to investigate this timestamp issue when
        # use DateTime.now or Time.now
        create(:contribution, state: 'confirmed', project: project_01, confirmed_at: Time.now )
        create(:contribution, state: 'confirmed', project: project_02, confirmed_at: 2.days.ago )
        create(:contribution, state: 'confirmed', project: project_03, confirmed_at: Time.now )
      end

      it { is_expected.to have(2).items }
      it { expect(subject.include?(project_02)).to eq(false) }
    end

    context "when does not have any confirmed contribution today" do
      before do
        create(:contribution, state: 'confirmed', project: project_01, confirmed_at: 1.days.ago )
        create(:contribution, state: 'confirmed', project: project_02, confirmed_at: 2.days.ago )
        create(:contribution, state: 'confirmed', project: project_03, confirmed_at: 5.days.ago )
      end

      it { is_expected.to have(0).items }
    end
  end

  describe ".visible" do
    before do
      [:draft, :rejected, :deleted, :in_analysis].each do |state|
        create(:project, state: state)
      end
      @project = create(:project, state: :online)
    end
    subject{ Project.visible }
    it{ is_expected.to eq([@project]) }
  end

  describe '.state_names' do
    let(:states) { [:draft, :rejected, :online, :successful, :waiting_funds, :failed, :in_analysis] }

    subject { Project.state_names }

    it { is_expected.to eq(states) }
  end

  describe '.near_of' do
    before do
      mg_user = create(:user, address_state: 'MG')
      sp_user = create(:user, address_state: 'SP')
      3.times { create(:project, user: mg_user) }
      6.times { create(:project, user: sp_user) }
    end

    let(:state) { 'MG' }

    subject { Project.near_of(state) }

    it { is_expected.to have(3).itens }
  end

  describe ".by_permalink" do
    context "when project is deleted" do
      before do
        @p = create(:project, permalink: 'foo', state: 'deleted')
        create(:project, permalink: 'bar')
      end
      subject{ Project.by_permalink('foo') }
      it{ is_expected.to eq([]) }
    end
    context "when project is not deleted" do
      before do
        @p = create(:project, permalink: 'foo')
        create(:project, permalink: 'bar')
      end
      subject{ Project.by_permalink('foo') }
      it{ is_expected.to eq([@p]) }
    end
  end

  describe '.by_progress' do
    subject { Project.by_progress(20) }

    before do
      @project_01 = create(:project, goal: 100)
      @project_02 = create(:project, goal: 100)
      @project_03 = create(:project, goal: 100)

      create(:contribution, value: 10, project: @project_01)
      create(:contribution, value: 10, project: @project_01)
      create(:contribution, value: 30, project: @project_02)
      create(:contribution, value: 10, project: @project_03)
    end

    xit { is_expected.to have(2).itens }
  end

  describe '.by_goal' do
    subject { Project.by_goal(200) }

    before do
      @project_01 = create(:project, goal: 100)
      @project_02 = create(:project, goal: 200)

    end

    it { should = [@project_02] }
  end

  describe '.video_url' do
    subject { project }

    before do
      CatarseSettings[:minimum_goal_for_video] = 5000
    end

    context 'when goal is above minimum' do
      context 'and project is online' do
        let(:project) { create :project, goal: 6000, state: 'online' }

        it { is_expected.not_to allow_value(nil).for(:video_url) }
      end

      context 'and project is in analysis' do
        let(:project) { create :project, goal: 6000, state: 'in_analysis' }

        it { is_expected.not_to allow_value(nil).for(:video_url) }
      end
    end

    context 'when goal is below minimum' do
      context 'and project is online' do
        let(:project) { create :project, goal: 4000, state: 'online' }

        it { is_expected.to allow_value(nil).for(:video_url) }
      end

      context 'and project is in analysis' do
        let(:project) { create :project, goal: 4000, state: 'in_analysis' }

        it { is_expected.to allow_value(nil).for(:video_url) }
      end
    end

    context 'when goal is minimum' do
      context 'and project is online' do
        let(:project) { build :project, goal: 5000, state: 'online' }

        it { is_expected.not_to allow_value(nil).for(:video_url) }
      end

      context 'and project is in analysis' do
        let(:project) { build :project, goal: 5000, state: 'in_analysis' }

        it { is_expected.not_to allow_value(nil).for(:video_url) }
      end
    end
  end

  describe '.by_online_date' do
    subject { Project.by_online_date(Time.now.to_date.to_s) }

    before do
      @project_01 = create(:project, online_date: Time.now.to_s)
      @project_02 = create(:project, online_date: 2.weeks.ago)

    end

    it { should = [@project_01] }
  end

  describe '.by_expires_at' do
    subject { Project.by_expires_at('10/10/2013') }

    before do
      @project_01 = create(:project, online_date: '10/10/2013', online_days: 1)
      @project_02 = create(:project, online_date: '09/10/2013', online_days: 1)
    end

    it { should = [@project_01] }
  end

  describe '.order_by' do
    subject { Project.last.name }

    before do
      create(:project, name: 'lorem')
      #testing for sql injection
      Project.order_by("goal asc;update projects set name ='test';select * from projects ").first #use first so the sql is actually executed
    end

    it { is_expected.to eq('lorem') }
  end

  describe '.between_created_at' do
    let(:start_at) { '17/01/2013' }
    let(:ends_at) { '20/01/2013' }
    subject { Project.between_created_at(start_at, ends_at) }

    before do
      @project_01 = create(:project, created_at: '19/01/2013')
      @project_02 = create(:project, created_at: '23/01/2013')
      @project_03 = create(:project, created_at: '26/01/2013')
    end

    it { is_expected.to eq([@project_01]) }
  end

  describe '.goal_between' do
    let(:start_at) { 100 }
    let(:ends_at) { 200 }
    subject { Project.goal_between(start_at, ends_at).order(:id) }

    before do
      @project_01 = create(:project, goal: 100)
      @project_02 = create(:project, goal: 200)
      @project_03 = create(:project, created_at: 300)
    end

    it { is_expected.to eq([@project_01, @project_02]) }
  end


  describe '.between_expires_at' do
    let(:start_at) { '17/01/2013' }
    let(:ends_at) { '22/01/2013' }
    subject { Project.between_expires_at(start_at, ends_at).order("id desc") }

    let(:project_01) { create(:project) }
    let(:project_02) { create(:project) }
    let(:project_03) { create(:project) }

    before do
      project_01.update_attributes({ online_date: '17/01/2013', online_days: 1 })
      project_02.update_attributes({ online_date: '21/01/2013', online_days: 1 })
      project_03.update_attributes({ online_date: '23/01/2013', online_days: 1 })
    end

    it { is_expected.to eq([project_02, project_01]) }
  end

  describe '.to_finish' do
    before do
      expect(Project).to receive(:expired).and_call_original
      expect(Project).to receive(:with_states).with(['online', 'waiting_funds']).and_call_original
    end
    it "should call scope expired and filter states that can be finished" do
      Project.to_finish
    end
  end

  describe ".expired" do
    before do
      @p = create(:project, online_days: 1, online_date: Time.now - 2.days)
      create(:project, online_days: 1)
    end
    subject{ Project.expired}
    it{ is_expected.to eq([@p]) }
  end

  describe ".not_expired" do
    before do
      @p = create(:project, online_days: 1)
      create(:project, online_days: 1, online_date: Time.now - 2.days)
    end
    subject{ Project.not_expired }
    it{ is_expected.to eq([@p]) }
  end

  describe ".expiring" do
    before do
      @p = create(:project, online_date: Time.now, online_days: 13)
      create(:project, online_date: Time.now, online_days: 1, online_date: Time.now - 2.days)
    end
    subject{ Project.expiring }
    it{ is_expected.to eq([@p]) }
  end

  describe ".not_expiring" do
    before do
      @p = create(:project, online_days: 15)
      create(:project, online_days: 1, online_date: Time.now - 2.days)
    end
    subject{ Project.not_expiring }
    it{ is_expected.to eq([@p]) }
  end

  describe ".recent" do
    before do
      @p = create(:project, online_date: (Time.now - 4.days))
      create(:project, online_date: (Time.now - 15.days))
    end
    subject{ Project.recent }
    it{ is_expected.to eq([@p]) }
  end

  describe "send_verify_moip_account_notification" do
    before do
      @p = create(:project, state: 'online', online_date: DateTime.now, online_days: 3)
      create(:project, state: 'draft')
    end

    it "should create notification for all projects that is expiring" do
      expect(ProjectNotification).to receive(:notify_once).
        with(:verify_moip_account, @p.user, @p, {from_email: CatarseSettings[:email_payments]})
      Project.send_verify_moip_account_notification
    end
  end

  describe ".from_channels" do
    let(:channel){create(:channel)}
    before do
      @p = create(:project, channels: [channel])
      create(:project, channels: [])
    end
    subject{ Project.from_channels([channel.id]) }
    xit{ is_expected.to eq([@p]) }
  end

  describe '#reached_goal?' do
    let(:project) { create(:project, goal: 3000) }
    subject { project.reached_goal? }

    context 'when sum of all contributions hit the goal' do
      before do
        create(:contribution, value: 4000, project: project)
      end
      xit { is_expected.to eq(true) }
    end

    context "when sum of all contributions don't hit the goal" do
      it { is_expected.to eq(false) }
    end
  end

  describe '#in_time_to_wait?' do
    let(:contribution) { create(:contribution, state: 'waiting_confirmation') }
    subject { contribution.project.in_time_to_wait? }

    context 'when project expiration is in time to wait' do
      it { is_expected.to eq(true) }
    end

    context 'when project expiration time is not more on time to wait' do
      let(:contribution) { create(:contribution, created_at: 1.week.ago) }
      it {is_expected.to eq(false)}
    end
  end

  describe "#search_on_name" do
    before { @p = create(:project, name: 'foo') }
    context "when project exists" do
      subject{ [Project.search_on_name('foo'), Project.pg_search('fóõ')] }
      it{ is_expected.to eq([[@p],[@p]]) }
    end
    context "when project is not found" do
      subject{ Project.search_on_name('lorem') }
      it{ is_expected.to eq([]) }
    end
  end

  describe "#pg_search" do
    before { @p = create(:project, name: 'foo') }
    context "when project exists" do
      subject{ [Project.pg_search('foo'), Project.pg_search('fóõ')] }
      it{ is_expected.to eq([[@p],[@p]]) }
    end
    context "when project is not found" do
      subject{ Project.pg_search('lorem') }
      it{ is_expected.to eq([]) }
    end
  end

  describe "#pledged_and_waiting" do
    subject{ project.pledged_and_waiting }
    before do
      @confirmed = create(:contribution, value: 10, state: 'confirmed', project: project)
      @waiting = create(:contribution, value: 10, state: 'waiting_confirmation', project: project)
      create(:contribution, value: 100, state: 'refunded', project: project)
      create(:contribution, value: 1000, state: 'pending', project: project)
    end
    it{ is_expected.to eq(@confirmed.value + @waiting.value) }
  end

  describe "#pledged" do
    subject(:pledged_value){ project.pledged }

    context "when project_total is nil" do
      before do
        allow(project).to receive(:project_total).and_return(nil)
      end
      it{ is_expected.to eq(0) }
    end

    context "when project_total exists" do
      context "when two contributions with state confirmed and/or requested_refund exists" do
        before do
          create(:contribution, :confirmed, project_value: 100, project: project)
          create(:contribution, :requested_refund, project_value: 75, project: project)
        end

        it 'expect sum of contributions' do
          expect(pledged_value).to eq(175.0)
        end
      end

      context "when contribution with pending state exists" do
        before do
          create(:contribution, :pending, project_value: 100, project: project)
        end

        it 'is not added' do
          expect(pledged_value).to eq(0)
        end
      end

      context "when contribution with waiting_confirmation state exists" do
        before do
          create(:contribution, project_value: 100, state: 'waiting_confirmation', project: project)
        end

        it 'is not added' do
          expect(pledged_value).to eq(0)
        end
      end

      context "when contribution with canceled state exists" do
        before do
          create(:contribution, :canceled, project_value: 100, project: project)
        end

        it 'is not added' do
          expect(pledged_value).to eq(0)
        end
      end

      context "when contribution with refunded state exists" do
        before do
          create(:contribution, :refunded, project_value: 100, project: project)
        end

        it 'is not added' do
          expect(pledged_value).to eq(0)
        end
      end

      context "when contribution with refunded_and_canceled state exists" do
        before do
          create(:contribution, :refunded_and_canceled, project_value: 100, project: project)
        end

        it 'is not added' do
          expect(pledged_value).to eq(0)
        end
      end

      context "when contribution with deleted state exists" do
        before do
          create(:contribution, :deleted, project_value: 100, project: project)
        end

        it 'is not added' do
          expect(pledged_value).to eq(0)
        end
      end

      context "when contribution with invalid_payment state exists" do
        before do
          create(:contribution, :invalid_payment, project_value: 100, project: project)
        end

        it 'is not added' do
          expect(pledged_value).to eq(0)
        end
      end

      context "when there are contributions with requested_refund and confirmed states and contributions with an invalid state" do
        before do
          ['pending', 'waiting_confirmation', 'canceled',
           'refunded', 'refunded_and_canceled', 'deleted',
           'invalid_payment'].each do |state|
             create(:contribution, state: state, project_value: 100, project: project)
           end
          create(:contribution, :requested_refund, project_value: 171, project: project)
          create(:contribution, :confirmed, project_value: 15, project: project)
        end

        it 'expect sum only of the contributions with requested_refund and confirmed states' do
          expect(pledged_value).to eq(186.0)
        end
      end
    end
  end

  describe "#total_payment_service_fee" do
    subject { project.total_payment_service_fee }

    context "when project_total is nil" do
      before { allow(project).to receive(:project_total).and_return(nil) }
      it { is_expected.to eq(0) }
    end

    context "when project_total exists" do
      before do
        project_total = double()
        allow(project_total).to receive(:total_payment_service_fee).and_return(4.0)
        allow(project).to receive(:project_total).and_return(project_total)
      end

      it { is_expected.to eq(4.0) }
    end
  end

  describe "#total_contributions" do
    subject{ project.total_contributions }
    context "when project_total is nil" do
      before do
        allow(project).to receive(:project_total).and_return(nil)
      end
      it{ is_expected.to eq(0) }
    end
    context "when project_total exists" do
      before do
        project_total = double()
        allow(project_total).to receive(:total_contributions).and_return(1)
        allow(project).to receive(:project_total).and_return(project_total)
      end
      it{ is_expected.to eq(1) }
    end
  end

  describe "#expired?" do
    subject{ project.expired? }

    context "when online_date is nil" do
      let(:project){ Project.new online_date: nil, online_days: 0 }
      it{ is_expected.to eq(nil) }
    end

    context "when expires_at is in the future" do
      let(:project){ Project.new online_date: 2.days.from_now, online_days: 0 }
      it{ is_expected.to eq(nil) }
    end

    context "when expires_at is in the past" do
      let(:project){ build(:project, online_date: 3.days.ago, online_days: 1) }
      before{project.save!}
      it{ is_expected.to eq(true) }
    end
  end

  describe "#expires_at" do
    subject{ project.expires_at }
    context "when we do not have an online_date" do
      let(:project){ build(:project, online_date: nil, online_days: 1) }
      it{ is_expected.to be_nil }
    end
    context "when we have an online_date" do
      let(:project){ create(:project, online_date: Time.now, online_days: 1)}
      before{project.save!}
      it{ is_expected.to eq(Time.zone.tomorrow.end_of_day.to_s(:db)) }
    end
  end

  describe '#selected_rewards' do
    let(:project){ create(:project) }
    let(:reward_01) { create(:reward, project: project) }
    let(:reward_02) { create(:reward, project: project) }
    let(:reward_03) { create(:reward, project: project) }

    before do
      create(:contribution, state: 'confirmed', project: project, reward: reward_01)
      create(:contribution, state: 'confirmed', project: project, reward: reward_03)
    end

    subject { project.selected_rewards }
    it { is_expected.to eq([reward_01, reward_03]) }
  end

  describe "#last_channel" do
    let(:channel){ create(:channel) }
    let(:project){ create(:project, channels: [ create(:channel), channel ]) }
    subject{ project.last_channel }
    xit{ is_expected.to eq(channel) }
  end

  describe '#pending_contributions_reached_the_goal?' do
    let(:project) { create(:project, goal: 200) }

    subject { project.pending_contributions_reached_the_goal? }

    context 'when reached the goal with pending contributions' do
      before { 2.times { create(:contribution, project: project, value: 120, state: 'waiting_confirmation') } }

      xit { is_expected.to eq(true) }
    end

    context 'when dont reached the goal with pending contributions' do
      before { 2.times { create(:contribution, project: project, value: 30, state: 'waiting_confirmation') } }

      it { is_expected.to eq(false) }
    end
  end

  describe "#new_draft_recipient" do
    subject { project.new_draft_recipient }
    before do
      CatarseSettings[:email_projects] = 'admin_projects@foor.bar'
      @user = create(:user, email: CatarseSettings[:email_projects])
    end
    it{ is_expected.to eq(@user) }
  end

  describe "#notification_type" do
    subject { project.notification_type(:foo) }
    context "when project does not belong to any channel" do
      it { is_expected.to eq(:foo) }
    end

    context "when project does belong to a channel" do
      let(:project) { channel_project }
      xit{ is_expected.to eq(:foo_channel) }
    end
  end

  describe ".enabled_to_use_pagarme" do
    before do
      @project_01 = create(:project, permalink: 'a')
      @project_02 = create(:project, permalink: 'b')
      @project_03 = create(:project, permalink: 'c')

      CatarseSettings[:projects_enabled_to_use_pagarme] = 'a, c'
    end

    subject { Project.enabled_to_use_pagarme }

    it { is_expected.to match_array([@project_01, @project_03])}
  end

  describe "#using_pagarme?" do
    let(:project) { create(:project, permalink: 'foo') }

    subject { project.using_pagarme? }

    context "when project is using pagarme" do
      before do
        CatarseSettings[:projects_enabled_to_use_pagarme] = 'foo'
      end

      it { is_expected.to be_truthy }
    end

    context "when project is not using pagarme" do
      before do
        CatarseSettings[:projects_enabled_to_use_pagarme] = nil
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#recurring?' do
    subject { project.recurring? }

    context 'when a project belongs to a recurring channel' do
      let(:channel) { create :channel, recurring: true }
      let(:project) { create :project, channels: [channel] }

      it { is_expected.to be_truthy }
    end

    context 'when a project does not belong to a recurring channel' do
      let(:project) { create :project }

      it { is_expected.to be_falsey }
    end
  end

  describe '#color' do
    subject { project.color }

    before { CatarseSettings[:default_color] = '#ff8a41' }

    context 'when a project belongs to a recurring channel' do
      let(:default_color) { CatarseSettings[:default_color] }
      let(:channel) { create :channel, recurring: true }
      let(:project) { create :project, channels: [channel] }

      it 'returns the default color' do
        expect(subject).to eq default_color
      end
    end

    context 'when a project is not related to a recurring channel' do
      let(:category) { create :category }
      let(:project) { create :project, category: category }

      it 'returns the category color' do
        expect(subject).to eq category.color
      end
    end
  end

  describe '#project_images_limit?' do
    let(:project) { create :project }

    subject { project.reload.project_images_limit? }

    before { CatarseSettings[:project_images_limit] = '8' }

    context 'when project has no images' do
      it { is_expected.to be_falsey }
    end

    context 'when project has less than eight images' do
      let!(:project_images) { create_list :project_image, 5, project: project }

      it { is_expected.to be_falsey }
    end

    context 'when project has reached the images limit' do
      let!(:project_images) { create_list :project_image, 8, project: project }

      it { is_expected.to be_truthy }
    end
  end

  describe '#project_partners_limit?' do
    let(:project) { create :project }

    subject { project.reload.project_partners_limit? }

    before { CatarseSettings[:project_partners_limit] = '3' }

    context 'when project has no partners' do
      it { is_expected.to be_falsey }
    end

    context 'when project has less than three partners' do
      let!(:project_partner) do
        create_list :project_partner, 1, project: project
      end

      it { is_expected.to be_falsey }
    end

    context 'when project has reached the partners limit' do
      let!(:project_partner) do
        create_list :project_partner, 3, project: project
      end

      it { is_expected.to be_truthy }
    end
  end

  describe 'recurring related scopes' do
    let(:channel) { create :channel, recurring: true }
    let(:channel_not_recurring) { create :channel }
    let!(:normal_projects) { create_list :project, 2, channels: [channel_not_recurring] }
    let!(:recurring_projects) {
      create_list :project, 2,
        channels: [channel],
        category: nil
    }

    describe '.with_channel_without_recurring' do
      subject { described_class.with_channel_without_recurring }

      it { is_expected.to match_array normal_projects }
      it { is_expected.to have(2).itens }
    end

    describe '.recurring' do
      subject { described_class.recurring }

      it { is_expected.to match_array recurring_projects }
      it { is_expected.to have(2).itens }
    end
  end

  context 'when a project belongs to a recurring channel' do
    let(:recurring_channel) { create :channel, recurring: true }
    subject {
      build :project,
        channels: [recurring_channel],
        category: nil,
        online_days: nil
    }

    describe 'validations' do
      it { is_expected.not_to validate_presence_of :category }
    end
  end

  describe 'pg_search scope associating other scopes' do
    context 'when associated scope joins one table used in associated_against of pg_search' do
      context 'when there are projects having user that matches the user name searched in user_name_contains scope' do
        before do
          john = create(:user, address_city: 'Orange town', name: 'John')
          steve = create(:user, name: 'Steve')
          create(:project, user: steve, name: 'Project about fruits')
          create(:project, user: steve, name: 'Apples', headline: 'Project about Apples')
          create(:project, user: steve, name: 'Oranges', about: 'Project about Oranges')
          create(:project, user: john, name: 'Project about Lemons')
          create(:project, user: user, name: 'Project about Vegetables')
          create_list :project, 4
        end

        it 'returns projects with name matching the pg_search term' do
          projects = Project.pg_search('about fruits').user_name_contains('Steve')
          expect(projects.map(&:name)).to match(['Project about fruits'])
        end

        it 'returns projects with headline matching the pg_search term' do
          projects = Project.pg_search('about apples').user_name_contains('Steve')
          expect(projects.map(&:name)).to match(['Apples'])
        end

        it 'returns projects with about attribute matching the pg_search term' do
          projects = Project.pg_search('about oranges').user_name_contains('Steve')
          expect(projects.map(&:name)).to match(['Oranges'])
        end

        it 'returns projects having user\'s address_city attribute matching the pg_search term' do
          projects = Project.pg_search('orange town').user_name_contains('John')
          expect(projects.map(&:name)).to match(['Project about Lemons'])
        end

        it 'returns projects having name, headline and/or about attributes matching the pg_search term' do
          projects = Project.pg_search('about').user_name_contains('Steve')
          expect(projects.map(&:name)).to match_array(['Project about fruits', 'Apples', 'Oranges'])
        end

        it 'ommits projects which do not have name, headline and/or about attributes matching the pg_search term' do
          projects = Project.pg_search('about fruits').user_name_contains('Steve')
          expect(projects.map(&:name)).not_to match(['Project about Vegetables'])
        end
      end

      context 'when there are not projects with user that matches the user name searched in user_name_contains scope' do
        before do
          create(:user_with_projects, projects_count: 1, name: 'John')
        end

        it 'does not return projects' do
          projects = Project.pg_search('john').user_name_contains('Steve')
          expect(projects.count(:all)).to eq(0)
        end
      end
    end
  end

  describe '#by_channel' do
    let(:foo_channel){ create(:channel, name: 'Foo Channel', users: [ user ]) }
    let(:foo_channel_projects){ Project.by_channel(foo_channel.id) }

    before(:each) do
      create_list(:project, 10)
    end

    context 'when channel does not have registered projects' do
      it 'does not return projects' do
        expect(foo_channel_projects.count).to eq(0)
      end
    end

    context 'when channel have registered projects' do
      before do
        create(:project, name: 'Project Bar in Foo Channel', channels: [foo_channel])
      end

      it "should return only projects that belongs to the channel passed as param" do
        expect(foo_channel_projects.map(&:name)).to match(['Project Bar in Foo Channel'])
      end
    end
  end
end
