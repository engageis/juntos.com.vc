# coding: utf-8
require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe Project, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject       { project }
  let(:project) { create(:project) }

  describe "associations" do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to :category }
    it { is_expected.to have_one  :project_total }
    it { is_expected.to have_many :rewards }
    it { is_expected.to have_many :contributions }
    it { is_expected.to have_many :posts }
    it { is_expected.to have_many :unsubscribes }
    it { is_expected.to have_many :project_images }
    it { is_expected.to have_many :project_partners }
    it { is_expected.to have_many :subgoals }
    it { is_expected.to have_many :notifications }
    it { is_expected.to have_and_belong_to_many :channels }
    it{ is_expected.to have_and_belong_to_many(:plans) }
  end

  describe "validations" do
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

    describe "presence validations" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:user) }
      it { is_expected.to validate_presence_of(:permalink) }
      it { is_expected.to validate_presence_of(:about) }
      it { is_expected.to validate_presence_of(:category) }
    end

    describe "online_days acceptance validations" do
      it { is_expected.to     allow_value(1).for(:online_days) }
      it { is_expected.not_to allow_value(0).for(:online_days) }
    end

    describe "video_url acceptance validations" do
      it { is_expected.to     allow_value('http://vimeo.com/12111').for(:video_url) }
      it { is_expected.to     allow_value('vimeo.com/12111').for(:video_url) }
      it { is_expected.to     allow_value('https://vimeo.com/12111').for(:video_url) }
      it { is_expected.to     allow_value('http://youtube.com/watch?v=UyU-xI').for(:video_url) }
      it { is_expected.to     allow_value('youtube.com/watch?v=UyU-xI').for(:video_url) }
      it { is_expected.to     allow_value('https://youtube.com/watch?v=UyU-xI').for(:video_url) }
      it { is_expected.not_to allow_value('http://www.foo.bar').for(:video_url) }
    end

    describe "goal acceptance validations" do
      it { is_expected.to     allow_value(10).for(:goal) }
      it { is_expected.not_to allow_value(8).for(:goal) }
    end

    describe "permalink acceptance validations" do
      it { is_expected.to      allow_value('testproject').for(:permalink) }
      it { is_expected.not_to allow_value('@users').for(:permalink) }
    end

    describe "numericality validations" do
      it { is_expected.to validate_numericality_of(:goal) }
    end

    describe "length of validations" do
      it { is_expected.to ensure_length_of(:headline).is_at_most(140).is_at_least(1) }
    end

    describe "exceptions" do
      describe ".category" do
        context "when a project belongs to a recurring channel" do
          let(:recurring_channel) { create :channel, recurring: true }
          subject { build(:project, channels: [recurring_channel], category: nil, online_days: nil) }

          it { is_expected.not_to validate_presence_of(:category) }
        end
      end

      describe ".video_url" do
        before  { CatarseSettings[:minimum_goal_for_video] = 5000 }

        context "when project state requires a video url" do
          context "state is online" do
            context "and goal is equals minimum" do
              let(:project) { create(:project, :online, goal: 5000) }

              it { is_expected.not_to allow_value(nil).for(:video_url) }
            end

            context "and goal is above minimum" do
              let(:project) { create(:project, :online, goal: 5001) }

              it { is_expected.not_to allow_value(nil).for(:video_url) }
            end

            context "and goal is below minimum" do
              let(:project) { create(:project, :online, goal: 4999) }

              it { is_expected.to allow_value(nil).for(:video_url) }
            end
          end

          context "state is in analysis" do
            context "and goal is equals minimum" do
              let(:project) { create(:project, :in_analysis, goal: 5000) }

              it { is_expected.not_to allow_value(nil).for(:video_url) }
            end

            context "and goal is above minimum" do
              let(:project) { create(:project, :in_analysis, goal: 5001) }

              it { is_expected.not_to allow_value(nil).for(:video_url) }
            end

            context "and goal is below minimum" do
              let(:project) { create(:project, :in_analysis, goal: 4999) }

              it { is_expected.to allow_value(nil).for(:video_url) }
            end
          end
        end

        context "when project state does not require a video url" do
          context "state is waiting_funds" do
            let(:project) { create(:project, :waiting_funds) }

            it { is_expected.to allow_value(nil).for(:video_url) }
          end

          context "state is successful" do
            let(:project) { create(:project, :successful) }

            it { is_expected.to allow_value(nil).for(:video_url) }
          end
        end
      end
    end
  end

  describe ".search_on_name" do
    before do
      category = create(:category, name_pt: 'teste_pt', name_en: 'test_en')
      create(:project, name: 'project_name', category: category)
      create(:project, name: 'foo_1')
      create(:project, name: 'foo_2')
    end

    context "when project is found" do
      context "and it searches on category name" do
        context "and it's in portuguese" do
          subject { Project.search_on_name('teste_pt').map(&:name) }

          it { is_expected.to contain_exactly('project_name') }
        end

        context "and it's in english" do
          subject { Project.search_on_name('test_en').map(&:name) }

          it { is_expected.to contain_exactly('project_name') }
        end
      end

      context "and it searches on project name" do
        subject { Project.search_on_name('project_name').map(&:name) }

        it { is_expected.to contain_exactly('project_name') }

        context "and the search ignores accents" do
          subject { Project.search_on_name('prôject_nãmé').map(&:name) }

          it { is_expected.to contain_exactly('project_name') }
        end
      end
    end

    context "when project is not found" do
      subject{ Project.search_on_name('lorem') }

      it{ is_expected.to be_empty }
    end
  end

  describe ".pg_search" do
    let(:user)     { create(:user, name: 'fulano', address_city: 'some_address_far_away') }
    let(:category) { create(:category, name_pt: 'teste_pt', name_en: 'test_en') }
    let!(:project) { create(:project, name: 'foo', category: category, user: user) }

    context "when project is found" do
      context "and it searches on category name" do
        context "and it's in portuguese" do
          subject { Project.pg_search('teste_pt').map(&:name) }

          it { is_expected.to contain_exactly(project.name) }
        end

        context "and it's in english" do
          subject { Project.pg_search('test_en').map(&:name) }

          it { is_expected.to contain_exactly(project.name) }
        end
      end

      context "and it searches on user" do
        context "name field" do
          subject { Project.pg_search('fulano').map(&:name) }

          it { is_expected.to contain_exactly(project.name) }
        end

        context "address_city field" do
          subject { Project.pg_search('some_address_far_away').map(&:name) }

          it { is_expected.to contain_exactly(project.name) }
        end
      end

      context "and it searches on project name" do
        subject { Project.pg_search('foo').map(&:name) }

        it { is_expected.to contain_exactly(project.name) }

        context "and the search ignores accents" do
          subject { Project.pg_search('fóõ').map(&:name) }

          it { is_expected.to contain_exactly(project.name) }
        end
      end
    end

    context "when project is not found" do
      subject{ Project.pg_search('lorem') }

      it{ is_expected.to be_empty }
    end
  end

  describe ".user_name_contains" do
    let(:user) { create(:user, name: 'fulano', address_city: 'some_address_far_away') }
    before     { create(:project, name: 'fulanos_project', user: user) }

    context "when project is found" do
      subject { Project.user_name_contains('fulano').map(&:name) }

      it { is_expected.to contain_exactly('fulanos_project') }

      context "and the search ignores accents" do
        subject { Project.user_name_contains('fūlåñö').map(&:name) }

        it { is_expected.to contain_exactly('fulanos_project') }
      end
    end

    context "when project is not found" do
      subject { Project.user_name_contains('user_does_not_exist').map(&:name) }

      it { is_expected.to be_empty }
    end
  end

  describe ".successful" do
    before do
      create(:project, :successful, name: 'successful_project_1')
      create(:project, :successful, name: 'successful_project_2')
      create(:project, :online)
      create(:project, :failed)
      create(:project, :draft)
      create(:project, :rejected)
      create(:project, :deleted)
      create(:project, :in_analysis)
    end

    subject { Project.successful.map(&:name) }

    it { is_expected.to contain_exactly('successful_project_1', 'successful_project_2') }
  end

  describe ".failed" do
    before do
      create(:project, :failed, name: 'failed_project_1')
      create(:project, :failed, name: 'failed_project_2')
      create(:project, :successful)
      create(:project, :online)
      create(:project, :draft)
      create(:project, :rejected)
      create(:project, :deleted)
      create(:project, :in_analysis)
    end

    subject { Project.failed.map(&:name) }

    it { is_expected.to contain_exactly('failed_project_1', 'failed_project_2') }
  end

  describe ".draft" do
    before do
      create(:project, :draft, name: 'draft_1')
      create(:project, :draft, name: 'draft_2')
      create(:project, :failed)
      create(:project, :successful)
      create(:project, :online)
      create(:project, :rejected)
      create(:project, :deleted)
      create(:project, :in_analysis)
    end

    subject { Project.draft.map(&:name) }

    it { is_expected.to contain_exactly('draft_1', 'draft_2') }
  end

  describe ".with_project_totals" do
    before  do
      project = create(:project, name: 'with_project_totals')
      create(:contribution, project: project)
    end

    subject { Project.with_project_totals.map(&:name) }

    it { is_expected.to contain_exactly('with_project_totals') }
  end

  describe ".without_pepsico_channel" do
    let(:channel) { create(:channel) }
    before { create(:project, name: 'without_pepsico', channels: [channel]) }

    subject { Project.without_pepsico_channel.map(&:name) }

    context "when the permalink is not 'pepsico'" do
      it { is_expected.to contain_exactly('without_pepsico') }
    end

    context "when the permalink is 'pepsico'" do
      let(:channel) { create(:channel, permalink: 'pepsico') }

      it { is_expected.to be_empty }
    end
  end

  describe ".draft_and_without_channel" do
    let(:channel) { create(:channel) }
    subject       { Project.draft_and_without_channel.map(&:name) }

    context "when project state is 'draft'" do
      context "and it has no channel" do
        before { create(:project, :draft, name: 'draft_project') }

        it { is_expected.to contain_exactly('draft_project') }
      end

      context "and it has channel" do
        before { create(:project, :draft, channels: [channel]) }

        it { is_expected.to be_empty }
      end
    end

    context "when project state is not 'draft'" do
      before { create(:project, :online) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_progress" do
    let(:fifth_percent) { 50 }
    let(:project)       { create(:project, name: 'project_in_progress', goal: 100) }

    subject { Project.by_progress(fifth_percent).map(&:name) }

    context "when project value is smaller than half goal" do
      before { create(:contribution, project: project, project_value: 10) }

      it { is_expected.to be_empty }
    end

    context "when project value is greater than half goal" do
      before { create(:contribution, project: project, project_value: 51) }

      it { is_expected.to contain_exactly('project_in_progress') }
    end
  end

  describe ".by_channel" do
    let(:channel) { create(:channel) }

    subject { Project.by_channel(channel).map(&:name) }

    context "when a project has the channel" do
      before { create(:project, name: 'project_by_channel', channels: [channel]) }

      it { is_expected.to contain_exactly('project_by_channel') }
    end

    context "when a project has not the channel" do
      before { create(:project) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_user_email" do
    let(:user_email) { 'user_email_@test.com' }
    let(:user) { create(:user, email: user_email) }

    subject { Project.by_user_email(user_email).map(&:name) }

    context "when project belongs to the user" do
      before { create(:project, name: 'project_user', user: user) }

      it { is_expected.to contain_exactly('project_user') }
    end

    context "when project does not belong to the user" do
      let!(:project) { create(:project) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_id" do
    subject { Project.by_id(10003).map(&:name) }

    context "when the project id is 10003" do
      before { create(:project, name: 'id_10003', id: 10003) }

      it { is_expected.to contain_exactly('id_10003') }
    end

    context "when the project id is not 10003" do
      before { create(:project, id: 1002) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_goal" do
    subject { Project.by_goal(1009).map(&:name) }

    context "when project goal is 1009" do
      before { create(:project, name: 'goal_1009', goal: 1009) }

      it { is_expected.to contain_exactly('goal_1009') }
    end

    context "when project goal is not 1009" do
      before { create(:project, goal: 1234) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_category_id" do
    let(:category) { create(:category, id: 2001) }
    subject        { Project.by_category_id(2001).map(&:name) }

    context "when category id is 2001" do
      before { create(:project, name: 'project_category_2001', category: category) }

      it { is_expected.to contain_exactly('project_category_2001') }
    end

    context "when category id is not 2001" do
      before { create(:project) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_online_date" do
    let(:online_date) { Time.current }
    subject { Project.by_online_date(online_date).map(&:name) }

    context "when online_date is today" do
      before { create(:project, name: 'project_today', online_date: online_date) }

      it { is_expected.to contain_exactly('project_today') }
    end

    context "when online_date is not today" do
      before { create(:project, online_date: 5.days.from_now) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_expires_at" do
    before             { travel_to Time.new(2016, 11, 28, 10, 00, 00) }
    after              { travel_back }
    let(:expires_at)   { 2.day.from_now.utc.to_date }
    subject            { Project.by_expires_at(expires_at).map(&:name) }

    context "when expires next day" do
      before { create(:project, name: 'project_next_day', online_date: Time.current.utc, online_days: 1) }

      it { is_expected.to contain_exactly('project_next_day') }
    end

    context "when does not expire next day" do
      before { create(:project, online_date: Time.current.utc, online_days: 5) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_updated_at" do
    let(:updated_at) { Time.current }
    subject { Project.by_updated_at(updated_at).map(&:name) }

    context "when project updated_at is now" do
      before { create(:project, name: 'project_updated_at', updated_at: updated_at) }

      it { is_expected.to contain_exactly('project_updated_at') }
    end

    context "when project updated_at is not now" do
      before { create(:project, updated_at: 5.days.from_now) }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_permalink" do
    subject { Project.by_permalink('foo').map(&:name) }

    context "when permalink is found" do
      context "and permalink is upper case" do
        before { create(:project, name: 'project_permalink', permalink: 'FOO') }

        it { is_expected.to contain_exactly('project_permalink') }
      end

      context "and permalink is lower case" do
        before { create(:project, name: 'project_permalink', permalink: 'foo') }

        it { is_expected.to contain_exactly('project_permalink') }
      end
    end

    context "when permalink is not found" do
      before { create(:project, permalink: 'bar') }

      it { is_expected.to be_empty }
    end
  end

  describe ".by_permalink_and_available" do
    subject { Project.by_permalink_and_available('foo').map(&:name) }

    context "when permalink is found" do
      context "when project is deleted" do
        before { create(:project, :deleted, permalink: 'foo') }

        it { is_expected.to be_empty }
      end

      context "when project is not deleted" do
        before { create(:project, name: 'project_permalink', permalink: 'foo') }

        it { is_expected.to contain_exactly('project_permalink') }
      end
    end

    context "when permalink is not found" do
      before { create(:project, :deleted, permalink: 'bar') }

      it { is_expected.to be_empty }
    end
  end

  describe ".recommended" do
    subject { Project.recommended.map(&:name) }

    context "when the project is recommended" do
      before { create(:project, name: 'recommended_project', recommended: true) }

      it { is_expected.to contain_exactly('recommended_project') }
    end

    context "when the project is not recommended" do
      before { create(:project, recommended: false) }

      it { is_expected.to be_empty }
    end
  end

  describe ".in_funding" do
    subject { Project.in_funding.map(&:name) }

    context "when project is expired" do
      before { create(:project, online_date: 2.days.ago, online_days: 1) }

      it { is_expected.to be_empty }
    end

    context "when project is not expired" do
      context "and state is online" do
        before { create(:project, :online, name: 'project_in_funding') }

        it { is_expected.to contain_exactly('project_in_funding') }
      end

      context "and state is not online" do
        before { create(:project, :draft, name: 'project_in_funding') }

        it { is_expected.to be_empty }
      end
    end
  end

  describe ".name_contains" do
    subject { Project.name_contains('project_name').map(&:name) }

    context "when project name is found" do
      context "and it is exactly the same" do
        before { create(:project, name: 'project_name') }

        it { is_expected.to contain_exactly('project_name') }
      end

      context "and it contains more characters" do
        before { create(:project, name: 'it is has bigger project_name than search criteria') }

        it { is_expected.to contain_exactly('it is has bigger project_name than search criteria') }
      end

      context "and it is a mix of upper and lower cases" do
        before { create(:project, name: 'PrOjeCt_nAMe') }

        it { is_expected.to contain_exactly('PrOjeCt_nAMe') }
      end
    end

    context "when project name is not found" do
      before { create(:project, name: 'test_some_name') }

      it { is_expected.to be_empty }
    end
  end

  describe ".near_of" do
    subject { Project.near_of('RN').map(&:name) }

    context "when project is found" do
      before do
        user = create(:user, address_state: 'RN')
        create(:project, name: 'project_near_of', user: user)
      end

      it { is_expected.to contain_exactly('project_near_of') }
    end

    context "when project is not found" do
      before do
        user = create(:user, address_state: 'SP')
        create(:project, user: user)
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".random_near_online_with_limit" do
    let(:address_state) { 'RN' }
    let(:limit) { 1 }

    before do
      user = create(:user, address_state: address_state)
      create_list(:project, 8, state, user: user, name: 'project_name')
    end

    subject { Project.random_near_online_with_limit('RN', limit).map(&:name) }

    context "when the project is online" do
      let(:state) { :online }

      it "returns the project with the specific address state" do
        is_expected.to contain_exactly('project_name')
      end

      it "returns the projects with the passed limit" do
        expect(subject.count).to eq(limit)
      end

      context "and it is in another address state" do
        let(:address_state) { 'SP' }

        it { is_expected.to be_empty }
      end
    end

    context "when the project is not online" do
      let(:state) { :successful }

      it { is_expected.to be_empty }
    end
  end

  describe ".online_non_recommended_with_limit" do
    let(:recommended) { false }
    let(:limit) { 1 }

    before do
      create_list(:project, 8, state, recommended: recommended, name: 'project_name')
    end

    subject { Project.online_non_recommended_with_limit(limit).map(&:name) }

    context "when the project is online" do
      let(:state) { :online }

      context "and it is non-recommended" do
        let(:recommended) { false }

        it { is_expected.to contain_exactly('project_name') }

        it "returns the projects with the passed limit" do
          expect(subject.count).to eq(limit)
        end
      end

      context "and it is recommended" do
        let(:recommended) { true }

        it { is_expected.to be_empty }
      end
    end

    context "when the project is not online" do
      let(:state) { :successful }

      it { is_expected.to be_empty }
    end
  end

  describe ".to_finish" do
    subject { Project.to_finish.map(&:name) }

    context "when project is found" do
      context "and is expired" do
        context "and state is 'online' or 'waiting_funds'" do
          before do
            create(:project, :online, name: 'project_to_finish_1', online_date: 10.days.ago, online_days: 1)
            create(:project, :waiting_funds, name: 'project_to_finish_2', online_date: 10.days.ago, online_days: 1)
          end

          it { is_expected.to contain_exactly('project_to_finish_1', 'project_to_finish_2') }
        end

        context "and state is not 'online' nor 'waiting_funds'" do
          before do
            create(:project, :rejected, online_date: Date.current, online_days: 4)
            create(:project, :failed, online_date: Date.current, online_days: 4)
            create(:project, :deleted, online_date: Date.current, online_days: 4)
            create(:project, :successful, online_date: Date.current, online_days: 4)
          end

          it { is_expected.to be_empty }
        end
      end

      context "and is not expired" do
        before { create(:project, online_date: Date.current, online_days: 10) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe ".visible" do
    subject { Project.visible.map(&:name) }

    context "when the projects are visible" do
      before do
        create(:project, :online, name: 'online')
        create(:project, :successful, name: 'successful')
        create(:project, :failed, name: 'failed')
        create(:project, :waiting_funds, name: 'waiting_funds')
      end

      it { is_expected.to contain_exactly('online', 'successful', 'failed', 'waiting_funds') }
    end

    context "when the projects are not visible" do
      before do
        create(:project, :draft)
        create(:project, :rejected)
        create(:project, :deleted)
        create(:project, :in_analysis)
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".financial" do
    subject { Project.financial.map(&:name) }

    context "when the projects are found" do
      context "when state is 'online', 'successful' or 'waiting_funds'" do
        context "when the project has expired for less than 15 days or is not expired" do
          before do
            create(:project, :online, name: 'financial_project_1', online_date: 15.days.ago, online_days: 2)
            create(:project, :successful, name: 'financial_project_2', online_date: Date.current, online_days: 2)
            create(:project, :waiting_funds, name: 'financial_project_3')
          end

          it { is_expected.to contain_exactly('financial_project_1', 'financial_project_2', 'financial_project_3') }
        end

        context "when the project is expired for 15 or more days" do
          before do
            create(:project, :online, online_date: 20.days.ago, online_days: 4)
            create(:project, :successful, online_date: 20.days.ago, online_days: 4)
            create(:project, :waiting_funds, online_date: 20.days.ago, online_days: 4)
          end

          it { is_expected.to be_empty }
        end
      end

      context "when state is not 'online', 'successful' nor 'waiting_funds'" do
        before do
          create(:project, :failed)
          create(:project, :deleted)
          create(:project, :rejected)
          create(:project, :in_analysis)
        end

        it { is_expected.to be_empty }
      end
    end
  end

  describe ".expired" do
    subject { Project.expired.map(&:name) }

    context "when project is expired" do
      before { create(:project, name: 'expired_project', online_date: 2.days.ago, online_days: 1) }

      it { is_expected.to contain_exactly('expired_project') }
    end

    context "when project is not expired" do
      before { create(:project, online_date: Date.current, online_days: 15) }

      it { is_expected.to be_empty }
    end
  end

  describe ".not_expired" do
    subject { Project.not_expired.map(&:name) }

    context "when project is not expired" do
      before { create(:project, name: 'not_expired_project', online_date: Date.current, online_days: 2) }

      it { is_expected.to contain_exactly('not_expired_project') }
    end

    context "when project is expired" do
      before { create(:project, online_days: 1, online_date: Date.current - 2.days) }

      it { is_expected.to be_empty }
    end
  end

  describe ".expiring" do
    subject { Project.expiring.map(&:name) }

    context "when project is expiring in two weeks" do
      before { create(:project, name: 'expiring_project', online_date: Date.current, online_days: 13) }

      it { is_expected.to contain_exactly('expiring_project') }
    end

    context "when project expires_at is longer than two weeks" do
      before { create(:project, online_date: Date.current, online_days: 50) }

      it { is_expected.to be_empty }
    end

    context "when project is already expired" do
      before { create(:project, online_date: 10.days.ago, online_days: 1) }

      it { is_expected.to be_empty }
    end
  end

  describe ".not_expiring" do
    subject { Project.not_expiring.map(&:name) }

    context "when there are no projects expiring" do
      before { create(:project, name: 'not_expiring_project', online_date: Date.current, online_days: 15) }

      it { is_expected.to contain_exactly('not_expiring_project') }
    end

    context "when there are projects expiring" do
      before { create(:project, online_date: 2.days.ago, online_days: 1) }

      it { is_expected.to be_empty }
    end
  end

  describe ".recent" do
    subject { Project.recent.map(&:name) }

    context "when there are recent projects" do
      before { create(:project, name: '4_days_ago', online_date: 4.days.ago) }

      it { is_expected.to contain_exactly('4_days_ago') }
    end

    context "when there is no project created in the last 6 days" do
      before { create(:project, online_date: 6.days.ago) }

      it { is_expected.to be_empty }
    end
  end

  describe ".order_status" do
    subject { Project.order_status.map(&:name) }

    before {
      create(:project, :waiting_funds, name: 'waiting_funds')
      create(:project, :online, name: 'online')
      create(:project, :failed, name: 'failed')
      create(:project, :successful, name: 'successful')
    }

    it { is_expected.to eq(['online', 'waiting_funds', 'successful', 'failed']) }
  end

  describe ".most_recent_first" do
    subject { Project.most_recent_first.map(&:name) }

    before do
      create(:project, name: 'project_2', online_date: Date.current)
      create(:project, name: 'project_4', online_date: 10.days.ago)
      create(:project, name: 'project_3', online_date: 4.days.ago)
      create(:project, name: 'project_1', online_date: 4.days.from_now)
    end

    it { is_expected.to contain_exactly('project_1', 'project_2', 'project_3', 'project_4') }
  end

  describe ".order_for_admin" do
    subject { Project.order_for_admin.map(&:name) }

    before {
      create(:project, :waiting_funds, name: 'waiting_funds')
      create(:project, :in_analysis, name: 'in_analysis')
      create(:project, :failed, name: 'failed')
      create(:project, :successful, name: 'successful')
    }

    it { is_expected.to eq(['in_analysis', 'waiting_funds', 'successful', 'failed']) }
  end

  describe ".from_channels" do
    let(:channel) { create(:channel) }
    subject       { Project.from_channels(channel.id).map(&:name) }

    context "when the project could be found by the channel" do
      before { create(:project, name: 'project_by_channel', channels: [channel]) }

      it { is_expected.to contain_exactly('project_by_channel') }
    end

    context "when the project could not be found by the channel" do
      before { create(:project) }

      it { is_expected.to be_empty }
    end
  end

  describe ".with_contributions_confirmed_today" do
    let(:project_01) { create(:project, :online, name: 'with_contribution_1') }
    let(:project_02) { create(:project, :online, name: 'with_contribution_2') }
    let(:project_03) { create(:project, :online) }

    subject { Project.with_contributions_confirmed_today.map(&:name) }

    context "when have confirmed contributions today" do
      before do
        create(:contribution, :confirmed, project: project_01, confirmed_at: Time.current )
        create(:contribution, :confirmed, project: project_02, confirmed_at: Time.current )
        create(:contribution, :confirmed, project: project_03, confirmed_at: 2.days.ago )
      end

      it { is_expected.to contain_exactly('with_contribution_1', 'with_contribution_2') }
    end

    context "when does not have any confirmed contribution today" do
      before do
        create(:contribution, :confirmed, project: project_01, confirmed_at: 1.days.ago )
        create(:contribution, :confirmed, project: project_02, confirmed_at: 2.days.ago )
        create(:contribution, :confirmed, project: project_03, confirmed_at: 5.days.ago )
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".expiring_in_less_of" do
    subject { Project.expiring_in_less_of('7 days').map(&:name) }

    context "when the project is online" do
      context "when expiring date is in less than 7 days" do
        before do
          create(:project, :online, name: 'expires_in_3_days', online_date: DateTime.current, online_days: 3)
          create(:project, :online, name: 'expires_in_5_days', online_date: DateTime.current, online_days: 5)
        end

        it { is_expected.to contain_exactly('expires_in_3_days', 'expires_in_5_days') }
      end

      context "when expiring date is over 7 days" do
        before do
          create(:project, :online, online_date: DateTime.current, online_days: 30)
          create(:project, :draft)
        end

        it { is_expected.to be_empty }
      end
    end

    context "when the project is not online" do
      before do
        create(:project, :failed)
        create(:project, :draft)
        create(:project, :rejected)
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".with_visible_channel_and_without_channel" do
    before do
      create(:project, name: 'project_name', channels: channels)
    end

    subject { Project.with_visible_channel_and_without_channel.map(&:name) }

    context "when there is no channel" do
      let(:channels) { [] }

      it { is_expected.to contain_exactly('project_name') }
    end

    context "when there is a channel" do
      context "and the channel is visible" do
        let(:channels) { [create(:channel, :visible)] }

        it { is_expected.to contain_exactly('project_name') }
      end

      context "and the channel is invisible" do
        let(:channels) { [create(:channel, :invisible)] }

        it { is_expected.to be_empty }
      end
    end
  end

  describe ".with_visible_channel" do
    subject { Project.with_visible_channel.map(&:name) }

    context "when the project is in none channel" do
      before { create(:project, channels: []) }

      it { is_expected.to be_empty }
    end

    context "when the project is in a channel" do
      before { create(:project, name: 'project_bar', channels: [channel]) }

      context "and the channel is visible" do
        let(:channel) { create(:channel, :visible) }

        it { is_expected.to contain_exactly('project_bar') }
      end

      context "and the channel is invisible" do
        let(:channel) { create(:channel, :invisible) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe ".of_current_week" do
    subject { Project.of_current_week.map(&:name) }

    context "when the online_date is any day from last week" do
      before do
        create(:project, channels: [channel], name: 'today', online_date: DateTime.current)
        create(:project, channels: [channel], name: 'in_3_days', online_date: 3.days.from_now)
        create(:project, channels: [channel], name: 'in_30_days', online_date: 30.days.from_now)
        create(:project, channels: [channel], name: 'six_days_ago', online_date: 6.days.ago)
      end

      context "and the channel is invisible" do
        let(:channel) { create(:channel, :invisible) }

        it { is_expected.to be_empty }
      end

      context "and the channel is visible" do
        let(:channel) { create(:channel, :visible) }

        it { is_expected.to contain_exactly('today', 'in_3_days', 'in_30_days', 'six_days_ago') }
      end
    end

    context "when the online_date is earlier than last week" do
      before do
        create(:project, online_date: 9.year.ago)
        create(:project, online_date: 8.days.ago)
        create(:project, online_date: 10.weeks.ago)
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".recurring" do
    let(:channel)               { create :channel, recurring: true }
    let(:channel_not_recurring) { create :channel }
    subject { Project.recurring.map(&:name) }

    context "when there are recurring projects" do
      before do
        create(:project, name: 'recurring_project_1', channels: [channel], category: nil)
        create(:project, name: 'recurring_project_2', channels: [channel], category: nil)
      end

      it { is_expected.to contain_exactly('recurring_project_1', 'recurring_project_2') }
    end

    context "when there are not recurring_projects" do
      before do
        create(:project, channels: [channel_not_recurring])
        create(:project, channels: [channel_not_recurring])
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".with_channel_without_recurring" do
    let(:channel)               { create :channel, recurring: true }
    let(:channel_not_recurring) { create :channel }
    subject { Project.with_channel_without_recurring.map(&:name) }

    context "when there are recurring projects" do
      before do
        create(:project, channels: [channel], category: nil)
        create(:project, channels: [channel], category: nil)
      end

      it { is_expected.to be_empty }
    end

    context "when there are not recurring_projects" do
      before do
        create(:project, name: 'normal_project_1', channels: [channel_not_recurring])
        create(:project, name: 'normal_project_2', channels: [channel_not_recurring])
      end

      it { is_expected.to contain_exactly('normal_project_1', 'normal_project_2') }
    end
  end

  describe ".without_channel" do
    subject { Project.without_channel.map(&:name) }

    context "when there are projects without channel" do
      before do
        create(:project, name: 'project_1')
        create(:project, name: 'project_2')
        create(:project, name: 'project_3')
      end

      it { is_expected.to contain_exactly('project_1', 'project_2', 'project_3') }
    end

    context "when there are projects with channel" do
      before do
        create(:project_with_channel)
        create(:project_with_channel)
        create(:project_with_channel)
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".without_recurring_and_pepsico_channel" do
    let(:channel)           { create(:channel) }
    let(:recurring_channel) { create(:channel, recurring: true) }
    let(:channel_pepsico)     { create(:channel, permalink: 'pepsico') }
    subject { Project.without_recurring_and_pepsico_channel.map(&:name) }

    context "when there are projects not recurring" do
      context "and the project has channel" do
        context "and the channel is not pepsico" do
          before { create(:project, name: 'project_with_channel', channels: [channel]) }

          it { is_expected.to contain_exactly('project_with_channel') }
        end

        context "and the channel is pepsico" do
          before { create(:project, channels: [channel_pepsico]) }

          it { is_expected.to be_empty }
        end
      end

      context "and the project has no channel" do
        before { create(:project, name: 'project_without_channel') }

        it { is_expected.to contain_exactly('project_without_channel') }
      end
    end

    context "when there are recurring projects" do
      before { create(:project, channels: [recurring_channel], category: nil ) }

      it { is_expected.to be_empty }
    end
  end

  describe ".goal_between" do
    before do
      create(:project, goal: 199, name: 'with_goal_199')
      create(:project, goal: 200, name: 'with_goal_200')
      create(:project, goal: 300, name: 'with_goal_300')
      create(:project, goal: 400, name: 'with_goal_400')
      create(:project, goal: 401, name: 'with_goal_401')
    end

    subject { Project.goal_between(start_at, ends_at).map(&:name) }

    context "when there are both start_at and ends_at" do
      let(:start_at) { 200 }
      let(:ends_at)  { 300 }

      it { is_expected.to contain_exactly('with_goal_200', 'with_goal_300') }
    end

    context "when there is only ends_at filter" do
      let(:start_at) { nil }
      let(:ends_at)  { 300 }

      it { is_expected.to contain_exactly('with_goal_199', 'with_goal_200', 'with_goal_300') }
    end

    context "when there is only start_at filter" do
      let(:start_at) { 200 }
      let(:ends_at)  { nil }

      it { is_expected.to contain_exactly('with_goal_200', 'with_goal_300', 'with_goal_400', 'with_goal_401') }
    end

    context "when there is neither start_at and ends_at" do
      let(:start_at) { nil }
      let(:ends_at)  { nil }

      it { is_expected.to contain_exactly('with_goal_199', 'with_goal_200', 'with_goal_300', 'with_goal_400', 'with_goal_401') }
    end
  end

  describe ".expiring_for_home" do
    let(:recommended) { false }
    let(:state) { :online }

    before do
      create(:project, state, online_date: expires_at, recommended: recommended, name: 'project_name', online_days: 1)
    end

    subject { Project.expiring_for_home.map(&:name) }

    context "when the project's expires_at is within 2 weeks" do
      let(:expires_at) { 1.week.from_now }

      context "and the project is non-recommended" do
        let(:recommended) { false }

        context "and the project is online" do
          let(:state) { :online }

          it { is_expected.to contain_exactly('project_name') }
        end

        context "and there are over than 3 valid responses" do
          before do
            create_list(:project, 8, :online, online_date: expires_at, recommended: recommended, online_days: 1)
          end

          it { expect(subject.count).to eq(3) }
        end

        context "and the project is not online" do
          let(:state) { :successful }

          it { is_expected.to be_empty }
        end
      end

      context "and the project is recommended" do
        let(:recommended) { true }

        it { is_expected.to be_empty }
      end
    end

    context "when the project is already expired" do
      let(:expires_at) { 2.days.ago }

      it { is_expected.to be_empty }
    end

    context "when the project's expires_at is over 2 weeks" do
      let(:expires_at) { 3.weeks.from_now }

      it { is_expected.to be_empty }
    end
  end

  describe ".recommended_for_home" do
    let(:state) { :online }

    before do
      create(:project, state, recommended: recommended, name: 'project_name')
    end

    subject { Project.recommended_for_home.map(&:name) }

    context "when the project is recommended" do
      let(:recommended) { true }

      context "and it is online" do
        let(:state) { :online }

        it { is_expected.to contain_exactly('project_name') }
      end

      context "and there are over than 3 valid responses" do
        before do
          create_list(:project, 8, :online, recommended: true)
        end

        it { expect(subject.count).to eq(3) }
      end

      context "and it is not online" do
        let(:state) { :successful }

        it { is_expected.to be_empty }
      end
    end

    context "when the project is non-recommended" do
      let(:recommended) { :false }

      it { is_expected.to be_empty }
    end
  end

  describe ".send_verify_moip_account_notification" do
    let(:user) { create(:user) }
    let!(:project) { create(:project, :online, user: user, online_date: Time.current, online_days: 3) }

    before do
      allow(ProjectNotification).to receive(:notify_once)

      Project.send_verify_moip_account_notification
    end

    context "when a project is expiring in less than seven days" do
      it "should have created notification for all projects that is expiring" do
        expect(ProjectNotification).to have_received(:notify_once).
          with(:verify_moip_account, user, project, {from_email: CatarseSettings[:email_payments]})
      end
    end

    context "when a project is expiring in over seven days" do
      let!(:project) { create(:project, :online, user: user, online_date: Time.current, online_days: 8) }

      it "should not have created a notification for the project" do
        expect(ProjectNotification).to_not have_received(:notify_once)
      end
    end
  end

  describe ".order_by" do
    before do
      create(:project, name: 'a_goal_1000', goal: 1000)
      create(:project, name: 'b_goal_400', goal: 400)
      create(:project, name: 'c_goal_10', goal: 10)
    end

    subject { Project.order_by(order_by_query).map(&:name) }

    context "when the order by query is valid" do
      context "and order by goal" do
        context "and it is ascending" do
          let(:order_by_query) { "goal asc" }

          it { is_expected.to eq(['c_goal_10', 'b_goal_400', 'a_goal_1000']) }
        end

        context "and it is descending" do
          let(:order_by_query) { "goal desc" }

          it { is_expected.to eq(['a_goal_1000', 'b_goal_400', 'c_goal_10']) }
        end
      end

      context "and order by name" do
        context "and it is ascending" do
          let(:order_by_query) { "name asc" }

          it { is_expected.to eq(['a_goal_1000', 'b_goal_400', 'c_goal_10']) }
        end

        context "and it is descending" do
          let(:order_by_query) { "name desc" }

          it { is_expected.to eq(['c_goal_10', 'b_goal_400', 'a_goal_1000']) }
        end
      end
    end

    context "when the order by query is invalid" do
      context "and it has sql injection" do
        let(:order_by_query) { "select * from projects; goal asc" }

        it { is_expected.to eq(['a_goal_1000', 'b_goal_400', 'c_goal_10']) }
      end

      context "by having invalid characters" do
        let(:order_by_query) { "goal" }

        it { is_expected.to eq(['a_goal_1000', 'b_goal_400', 'c_goal_10']) }
      end
    end
  end

  describe ".enabled_to_use_pagarme" do
    subject { Project.enabled_to_use_pagarme.map(&:name) }
    before  { CatarseSettings[:projects_enabled_to_use_pagarme] = 'a, c' }

    context "when there are projects enabled to use pagarme" do
      before do
        create(:project, name: 'permalink_a', permalink: 'a')
        create(:project, name: 'permalink_c', permalink: 'c')
      end

      it { is_expected.to contain_exactly('permalink_a', 'permalink_c') }
    end

    context "when there are not projects enabled to use pagarme" do
      before do
        create(:project, name: 'permalink_k', permalink: 'k')
        create(:project, name: 'permalink_b', permalink: 'b')
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#using_pagarme?" do
    let(:project) { create(:project, permalink: 'foo') }

    subject { project.using_pagarme? }

    context "when project is using pagarme" do
      before { CatarseSettings[:projects_enabled_to_use_pagarme] = 'foo' }

      it { is_expected.to be_truthy }
    end

    context "when project is not using pagarme" do
      before { CatarseSettings[:projects_enabled_to_use_pagarme] = nil }

      it { is_expected.to be_falsey }
    end
  end

  describe "#subscribed_users" do
    let(:project) { create(:project) }
    let(:user_1)  { create(:user, name: 'user_1') }
    let(:user_2)  { create(:user, name: 'user_2') }
    let(:user_3)  { create(:user, name: 'user_3') }

    subject { project.subscribed_users.map(&:name) }

    context "when there are contributions for the project" do
      before do
        create(:contribution, :confirmed, user: user_1, project: project)
        create(:contribution, :confirmed, user: user_2, project: project)
        create(:contribution, :confirmed, user: user_3, project: project)
      end

      it { is_expected.to contain_exactly('user_1', 'user_2', 'user_3') }
    end

    context "when there are not contributions for the project" do
      before do
        project_1 = create(:project, name: 'project_1', user: user_1)

        create(:contribution, :confirmed, user: user_1, project: project_1)
        create(:contribution, :confirmed, user: user_2, project: project_1)
        create(:contribution, :confirmed, user: user_3, project: project_1)
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#expires_at" do
    let(:expires_at) { project.expires_at }

    subject { expires_at }

    context "when we do not have an online_date" do
      let(:project) { build(:project, online_date: nil, online_days: 1) }

      it { is_expected.to be_nil }
    end

    context "when we have an online_date" do
      before                 { travel_to Time.new(2016, 11, 10, 10, 00, 00) }
      after                  { travel_back }
      subject                { expires_at.utc.to_date }
      let(:expires_tomorrow) { 2.day.from_now.utc.to_date }
      let(:project)          { create(:project, online_date: Time.current.utc, online_days: 1)}

      it { is_expected.to eq(expires_tomorrow) }
    end
  end

  describe "#pledged" do
    subject { project.pledged }

    context "when there are no contributions for the project" do
      it { is_expected.to be_zero }
    end

    context "when there are contributions for the project" do
      context "and the contribution state is valid for pledged" do
        before do
          create(:contribution, :confirmed, project_value: 185, project: project)
          create(:contribution, :requested_refund, project_value: 15, project: project)
        end

        it 'expect sum of both contributions' do
          is_expected.to eq(200)
        end
      end

      context "and the contribution state is invalid for pledged" do
        before do
          create(:contribution, :pending, project_value: 100, project: project)
          create(:contribution, :canceled, project_value: 100, project: project)
          create(:contribution, :refunded, project_value: 100, project: project)
          create(:contribution, :deleted, project_value: 100, project: project)
          create(:contribution, :invalid_payment, project_value: 100, project: project)
          create(:contribution, :waiting_confirmation, project_value: 100, project: project)
          create(:contribution, :refunded_and_canceled, project_value: 100, project: project)
        end

        it { is_expected.to be_zero }
      end
    end
  end

  describe "#total_contributions" do
    subject { project.total_contributions }

    context "when there are no contributions for the project" do
      it { is_expected.to be_zero }
    end

    context "when there are contributions for the project" do
      context "and the contribution state is valid" do
        before do
          create(:contribution, :confirmed, project: project)
          create(:contribution, :requested_refund, project: project)
        end

        it { is_expected.to eq(2) }
      end

      context "and the contribution state is invalid" do
        before do
          create(:contribution, :pending, project_value: 100, project: project)
          create(:contribution, :canceled, project_value: 100, project: project)
          create(:contribution, :refunded, project_value: 100, project: project)
          create(:contribution, :deleted, project_value: 100, project: project)
          create(:contribution, :invalid_payment, project_value: 100, project: project)
          create(:contribution, :waiting_confirmation, project_value: 100, project: project)
          create(:contribution, :refunded_and_canceled, project_value: 100, project: project)
        end

        it { is_expected.to be_zero }
      end
    end
  end

  describe "#total_payment_service_fee" do
    subject { project.total_payment_service_fee }

    context "when there are no contribution for the project" do
      it { is_expected.to be_zero }
    end

    context "when there are contributions for the project" do
      context "and the contribution status is valid" do
        before do
          create(:contribution, :confirmed, project: project, payment_service_fee: 30)
          create(:contribution, :requested_refund, project: project, payment_service_fee: 20)
        end

        it { is_expected.to eq(50) }
      end

      context "and the contribution status is invalid" do
        before do
          create(:contribution, :pending, project: project, payment_service_fee: 50)
          create(:contribution, :canceled, project: project, payment_service_fee: 50)
          create(:contribution, :refunded, project: project, payment_service_fee: 50)
          create(:contribution, :deleted, project: project, payment_service_fee: 50)
          create(:contribution, :invalid_payment, project: project, payment_service_fee: 50)
          create(:contribution, :waiting_confirmation, project: project, payment_service_fee: 50)
          create(:contribution, :refunded_and_canceled, project: project, payment_service_fee: 50)
        end

        it { is_expected.to be_zero }
      end
    end
  end

  describe "#selected_rewards" do
    let(:project)   { create(:project) }
    let(:reward_01) { create(:reward, description: 'reward_1', project: project) }
    let(:reward_02) { create(:reward, description: 'reward_2', project: project) }
    let(:reward_03) { create(:reward, description: 'reward_3', project: project) }
    subject         { project.selected_rewards.map(&:description) }

    context "when there are confirmed contributions" do
      before do
        create(:contribution, :confirmed, project: project, reward: reward_01)
        create(:contribution, :confirmed, project: project, reward: reward_03)
      end

      it { is_expected.to contain_exactly('reward_1', 'reward_3') }
    end

    context "when there are not confirmed contributions" do
      before do
        create(:contribution, :pending, project: project, reward: reward_01)
        create(:contribution, :waiting_confirmation, project: project, reward: reward_03)
        create(:contribution, :canceled, project: project, reward: reward_03)
        create(:contribution, :refunded, project: project, reward: reward_03)
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#accept_contributions?" do
    context "when project is online" do
      context "and is not expired" do
        context "and is available for contribution" do
          let(:project) { create(:project, :online, :not_expired, available_for_contribution: true) }

          it { expect(project).to be_accept_contributions }
        end

        context "and not available for contribution" do
          let(:project) { create(:project, :online, :not_expired, available_for_contribution: false) }

          it { expect(project).not_to be_accept_contributions }
        end
      end

      context "and is expired" do
        let(:project) { create(:project, :online, :expired, available_for_contribution: true) }

        it { expect(project).not_to be_accept_contributions }
      end
    end

    context "when project is not online" do
      let(:project) { create(:project, :failed) }

      it { expect(project).not_to be_accept_contributions }
    end
  end

  describe "#reached_goal?" do
    let(:project) { create(:project, goal: 3000) }

    context "when there are no contributions" do
      it { expect(project).not_to be_reached_goal }
    end

    context "when there are contributions" do
      context "and the contributions value sum equals the goal" do
        before do
          create(:contribution, :confirmed, project_value: 1500, project: project)
          create(:contribution, :confirmed, project_value: 1500, project: project)
        end

        it { expect(project).to be_reached_goal }
      end

      context "and the contributions value sum is over the goal" do
        before do
          create(:contribution, :confirmed, project_value: 1500, project: project)
          create(:contribution, :confirmed, project_value: 4500, project: project)
        end

        it { expect(project).to be_reached_goal }
      end

      context "and the contributions value sum is under the goal" do
        before do
          create_list(:contribution, 2, :confirmed, project_value: 500, project: project)
        end

        it { expect(project).not_to be_reached_goal }
      end
    end
  end

  describe "#expired?" do
    context "the project is not expired yet" do
      context "when online_date is nil" do
        let(:project) { create(:project, online_date: nil) }

        it { expect(project.expired?).to be_nil }
      end

      context "when expires_at is in the future" do
        let(:project) { create(:project, online_date: 2.days.from_now, online_days: 1) }

        it { expect(project).not_to be_expired }
      end
    end

    context "when expires_at is in the past" do
      let(:project) { create(:project, online_date: 3.days.ago, online_days: 1) }

      it { expect(project).to be_truthy }
    end
  end

  describe "#in_time_to_wait?" do
    context "when there is waiting_confirmation contribution" do
      before { create(:contribution, :waiting_confirmation, project: project) }

      it { expect(project).to be_in_time_to_wait }
    end

    context "when there are contributions with no waiting_confirmation state" do
      before do
        create(:contribution, :pending, project: project, payment_service_fee: 50)
        create(:contribution, :canceled, project: project, payment_service_fee: 50)
        create(:contribution, :refunded, project: project, payment_service_fee: 50)
        create(:contribution, :deleted, project: project, payment_service_fee: 50)
        create(:contribution, :invalid_payment, project: project, payment_service_fee: 50)
        create(:contribution, :confirmed, project: project, payment_service_fee: 50)
        create(:contribution, :refunded_and_canceled, project: project, payment_service_fee: 50)
      end

      it { expect(project).not_to be_in_time_to_wait }
    end
  end

  describe "#pending_contributions_reached_the_goal?" do
    let(:project) { create(:project, goal: 200) }

    context "when the contribution state is confirmed or waiting_confirmation" do
      context "and the goal has reached" do
        before do
          create(:contribution, :waiting_confirmation, project: project, project_value: 120)
          create(:contribution, :confirmed, project: project, project_value: 120)
        end

        it { expect(project).to be_pending_contributions_reached_the_goal }
      end

      context "and the goal has not reached" do
        before do
          create(:contribution, :waiting_confirmation, project: project, project_value: 60)
          create(:contribution, :confirmed, project: project, project_value: 40)
        end

        it { expect(project).not_to be_pending_contributions_reached_the_goal }
      end
    end

    context "when the contribution state is not confirmed neither waiting_confirmation" do
      before do
        create(:contribution, :pending, project: project, payment_service_fee: 500)
        create(:contribution, :canceled, project: project, payment_service_fee: 510)
        create(:contribution, :refunded, project: project, payment_service_fee: 520)
        create(:contribution, :deleted, project: project, payment_service_fee: 503)
        create(:contribution, :invalid_payment, project: project, payment_service_fee: 50)
        create(:contribution, :refunded_and_canceled, project: project, payment_service_fee: 50)
      end

      it { expect(project).not_to be_pending_contributions_reached_the_goal }
    end
  end

  describe "#pledged_and_waiting" do
    subject { project.pledged_and_waiting }

    context "when the contribution state is confirmed or waiting_confirmation" do
      before do
        create(:contribution, :waiting_confirmation, project: project, project_value: 80)
        create(:contribution, :confirmed, project: project, project_value: 20)
      end

      it { is_expected.to eq(100) }
    end

    context "when the contribution state is not confirmed neither waiting_confirmation" do
      before do
        create(:contribution, :pending, project: project, payment_service_fee: 500)
        create(:contribution, :canceled, project: project, payment_service_fee: 510)
        create(:contribution, :refunded, project: project, payment_service_fee: 520)
        create(:contribution, :deleted, project: project, payment_service_fee: 503)
        create(:contribution, :invalid_payment, project: project, payment_service_fee: 50)
        create(:contribution, :refunded_and_canceled, project: project, payment_service_fee: 50)
      end

      it { is_expected.to be_zero }
    end
  end

  describe "#new_draft_recipient" do
    before do
      CatarseSettings[:email_projects] = 'admin_projects@foor.bar'
      create(:user, name: 'email_project_user', email: CatarseSettings[:email_projects])
    end

    subject { project.new_draft_recipient.name }

    it { is_expected.to eq('email_project_user') }
  end

  describe "#last_channel" do
    let(:channel_last) { create(:channel, name: 'last_channel') }
    let(:channel_02)   { create(:channel) }
    let!(:project)     { create(:project, channels: [ channel_02, create(:channel), channel_last ]) }
    subject            { project.last_channel.name }

    it { is_expected.to eq('last_channel') }
  end

  describe "#recurring?" do
    context "when the project has exactly one recurring channel" do
      let(:channel) { create(:channel, recurring: true) }
      let(:project) { create(:project, channels: [channel]) }

      it { expect(project).to be_recurring }
    end

    context "when the project has many recurring channels" do
      let(:channels) { create_list(:channel, 3, recurring: true) }
      let(:project)    { create :project, channels: channels }

      it { expect(project).not_to be_recurring }
    end

    context "when a project does not have a recurring channel" do
      let(:project) { create :project }

      it { expect(project).not_to be_recurring }
    end
  end

  describe "#color" do
    before  { CatarseSettings[:default_color] = '#ff8a41' }
    subject { project.color }

    context "when a project has a recurring channel" do
      let(:default_color) { CatarseSettings[:default_color] }
      let(:channel)       { create :channel, recurring: true }
      let(:project)       { create :project, channels: [channel] }

      it "should return the default color" do
        is_expected.to eq(default_color)
      end
    end

    context "when a project is not related to a recurring channel" do
      let(:category) { create :category }
      let(:project)  { create :project, category: category }

      it "should return the category color" do
        is_expected.to eq category.color
      end
    end
  end

  describe "#notification_type" do
    subject { project.notification_type(:foo) }

    context "when project does not have any channel" do
      it { is_expected.to eq(:foo) }
    end

    context "when project has a channel" do
      let(:channel) { create(:channel) }
      let(:project) { create(:project, channels: [channel]) }

      it { is_expected.to eq(:foo_channel) }
    end
  end

  describe "#should_fail?" do
    context "when the project has expired" do
      context "and has not reached the goal" do
        let(:project) { create(:project, :expired, goal: 10000) }

        it { expect(project).to be_should_fail }
      end

      context "but has reached the goal" do
        let(:project) { create(:project, :expired, goal: 100) }
        let!(:contribution) { create(:contribution, :confirmed, project: project, project_value: 101) }

        it { expect(project).not_to be_should_fail }
      end
    end

    context "when the project has not expired" do
      let(:project) { create(:project, online_date: Time.current, online_days: 10) }

      it { expect(project).not_to be_should_fail }
    end
  end

  describe "#notify_owner" do
    let(:user)     { create(:user) }
    let!(:project) { create(:project, :online, user: user, online_date: Time.current, online_days: 3) }

    before do
      allow(ProjectNotification).to receive(:notify_once)

      project.notify_owner(:template, { options: 'test' })
    end

    it "should notify the owner" do
      expect(ProjectNotification).to have_received(:notify_once).
        with(:template, user, project, { options: 'test' })
    end
  end

  describe "#notify_to_backoffice" do
    let(:project)         { create(:project) }
    let(:backoffice_user) { nil }
    let(:template_name)   { nil }
    let(:options)         { { from_name: 'test' } }

    before { CatarseSettings[:email_payments] = 'foo@bar.com' }

    context "when backoffice_user is nil" do
      subject { project.notify_to_backoffice(template_name, options, backoffice_user) }

      it { is_expected.to be_nil }
    end

    context "when backoffice_user is not nil" do
      context "and template_name is :new_draft_project" do
        let(:backoffice_user) { create(:user) }
        let(:template_name)   { :new_draft_project }

        before do
          allow(ProjectNotification).to receive(:notify)

          project.notify_to_backoffice(template_name, options, backoffice_user)
        end

        it "should notify the backoffice_user" do
          expect(ProjectNotification).to have_received(:notify).
            with(template_name, backoffice_user, project, options)
        end
      end

      context "and template_name is not :new_draft_project" do
        let(:backoffice_user) { create(:user) }
        let(:template_name)   { :template }

        before do
          allow(ProjectNotification).to receive(:notify_once)

          project.notify_to_backoffice(template_name, options, backoffice_user)
        end

        it "should notify_once the backoffice_user" do
          expect(ProjectNotification).to have_received(:notify_once).
            with(template_name, backoffice_user, project, options)
        end
      end
    end
  end

  describe "#have_partner?" do
    context "when there is partner" do
      let(:project) { create(:project, partner_name: 'foo_bar') }

      it { expect(project).to be_have_partner }
    end

    context "when there is no partner" do
      let(:project) { create(:project) }

      it { expect(project).not_to be_have_partner }
    end
  end

  describe "#channel_json" do
    let(:project) { create(:project, name: 'foo', permalink: 'bar') }
    let!(:contribution) { create(:contribution, :confirmed, project: project) }
    let(:response) { {"name"=>"foo", "permalink"=>"bar", "total_contributions"=>1} }

    subject { project.channel_json }

    it { is_expected.to eq(response) }
  end

  describe "#current_subgoal" do
    let(:project) { create(:project) }
    subject       { project.current_subgoal }

    context "when there are subgoals" do
      before do
        create(:subgoal, project: project, value: 30)
        create(:subgoal, project: project, value: 50)
        create(:subgoal, description: 'last_subgoal', project: project, value: 20)
      end

      context "and the subgoals values are greater than pledged" do
        subject { project.current_subgoal.description }

        it { is_expected.to eq('last_subgoal') }
      end

      context "and the subgoals values are smaller than pledged" do
        before do
          create(:contribution, :confirmed, project_value: 185, project: project)
          create(:contribution, :requested_refund, project_value: 15, project: project)
        end

        it { is_expected.to be_nil }
      end
    end

    context "when there are no subgoals" do
      it { is_expected.to be_nil }
    end
  end

  describe "#project_images_limit?" do
    before        { CatarseSettings[:project_images_limit] = '8' }
    let(:project) { create(:project) }

    context "when the project has no images" do
      it { expect(project).not_to be_project_images_limit }
    end

    context "when the project has less than eight images" do
      before { create_list(:project_image, 5, project: project) }

      it { expect(project).not_to be_project_images_limit }
    end

    context "when project has reached the images limit" do
      before { create_list(:project_image, 8, project: project) }

      it { expect(project).to be_project_images_limit }
    end
  end

  describe "#project_partners_limit?" do
    before        { CatarseSettings[:project_partners_limit] = '3' }
    let(:project) { create :project }

    context "when project has no partners" do
      it { expect(project).not_to be_project_partners_limit }
    end

    context "when project has less than three partners" do
      before { create(:project_partner, project: project) }

      it { expect(project).not_to be_project_partners_limit }
    end

    context "when project has reached the partners limit" do
      before { create_list(:project_partner, 3, project: project) }

      it { expect(project).to be_project_partners_limit }
    end
  end

  describe "#visible?" do
    context "when the project is 'draft'" do
      let(:project) { create(:project, :draft) }

      it { expect(project).not_to be_visible }
    end

    context "when the project is 'rejected'" do
      let(:project) { create(:project, :rejected) }

      it { expect(project).not_to be_visible }
    end

    context "when the project is 'deleted'" do
      let(:project) { create(:project, :deleted) }

      it { expect(project).not_to be_visible }
    end

    context "when the project is 'in_analysis'" do
      let(:project) { create(:project, :in_analysis) }

      it { expect(project).not_to be_visible }
    end

    context "when the project is 'online'" do
      let(:project) { create(:project, :online) }

      it { expect(project).to be_visible }
    end

    context "when the project is 'successful'" do
      let(:project) { create(:project, :successful) }

      it { expect(project).to be_visible }
    end

    context "when the project is 'failed'" do
      let(:project) { create(:project, :failed) }

      it { expect(project).to be_visible }
    end

    context "when the project is 'waiting_funds'" do
      let(:project) { create(:project, :waiting_funds) }

      it { expect(project).to be_visible }
    end
  end

  describe ".state_names" do
    let(:states) { [:draft, :rejected, :online, :successful, :waiting_funds, :failed, :in_analysis] }

    subject { Project.state_names }

    it { is_expected.to eq(states) }
  end

  describe ".between_created_at" do
    let(:start_at) { '17/01/2013' }
    let(:ends_at)  { '20/01/2013' }
    subject        { Project.between_created_at(start_at, ends_at).map(&:name) }

    context "when there are projects in the between range" do
      before do
        create(:project, name: 'project_1', created_at: '19/01/2013')
        create(:project, name: 'project_2', created_at: '18/01/2013')
      end

      it { is_expected.to contain_exactly('project_1', 'project_2') }
    end

    context "when there are no projects in the between range" do
      before do
        create(:project, created_at: '23/01/2013')
        create(:project, created_at: '26/01/2013')
      end

      it { is_expected.to be_empty }
    end
  end

  describe ".between_expires_at" do
    let(:start_at) { '17/01/2013' }
    let(:ends_at)  { '22/01/2013' }
    subject        { Project.between_expires_at(start_at, ends_at).map(&:name) }

    context "when there are projects in the between range" do
      before do
        create(:project, name: 'project_17_01', online_date: '17/01/2013', online_days: 1)
        create(:project, name: 'project_21_01', online_date: '21/01/2013', online_days: 1)
      end

      it { is_expected.to contain_exactly('project_17_01', 'project_21_01') }
    end

    context "when there are no project in the between range" do
      before { create(:project, online_date: '23/01/2013', online_days: 1) }

      it { is_expected.to be_empty }
    end
  end
end
