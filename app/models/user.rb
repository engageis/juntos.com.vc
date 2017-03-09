# coding: utf-8
class User < ActiveRecord::Base
  include User::OmniauthHandler
  has_notifications
  acts_as_copy_target

  devise          :database_authenticatable,
                  :registerable,
                  :recoverable,
                  :rememberable,
                  :trackable,
                  :omniauthable

  enum access_type: [:individual, :legal_entity]
  enum gender:      [:male, :female]

  STAFFS = {
    team:             0,
    financial_board:  1,
    technical_board:  2,
    advice_board:     3
  }

  LEGAL_ENTITY_AUTHORIZATION_DOCUMENTS = [
    :bylaw_registry,
    :last_general_meeting_minute,
    :fiscal_council_report,
    :directory_proof,
    :last_mandate_balance,
    :cnpj_card,
    :certificates,
    :last_year_activities_report,
    :organization_current_plan,
    :federal_tributes_certificate,
    :federal_court_debt_certificate,
    :manager_id
  ]

  mount_uploader :uploaded_image, UserUploader

  validates :bio, length: { maximum: 140 }
  validates :access_type, presence: true
  validates :email, presence: true
  validates :email,
              allow_blank: true,
              uniqueness: true,
              format: { with: Devise.email_regexp },
              if: :email_changed?
  validates :password,
              presence: { if: :password_required? },
              confirmation: { if: :password_confirmation_required? },
              length: { within: Devise.password_length },
              allow_blank: true

  belongs_to :channel
  belongs_to :country
  has_one    :user_total
  has_many   :bank_accounts
  has_many   :credit_cards
  has_many   :contributions
  has_many   :authorizations
  has_many   :channel_posts
  has_many   :channels_subscribers
  has_many   :projects
  has_many   :unsubscribes
  has_many   :project_posts
  has_many   :contributed_projects, -> { where(contributions: { state: 'confirmed' } ).uniq } ,through: :contributions, source: :project
  has_many   :category_followers
  has_many   :categories, through: :category_followers
  has_many   :recurring_contributions, class_name: 'Subscription'
  has_many   :authorization_documents, as: :authable, class_name: 'UserAuthorizationDocument'
  has_and_belongs_to_many :recommended_projects, join_table: :recommendations, class_name: 'Project'
  has_and_belongs_to_many :subscriptions, join_table: :channels_subscribers, class_name: 'Channel'

  accepts_nested_attributes_for :unsubscribes, allow_destroy: true rescue puts "No association found for name 'unsubscribes'. Has it been defined yet?"
  accepts_nested_attributes_for :bank_accounts, allow_destroy: true
  accepts_nested_attributes_for :authorization_documents, allow_destroy: true

  scope :active,                        -> { where(deactivated_at: nil) }
  scope :staff,                         -> { where(staff_members_query) }
  scope :has_credits,                   -> { joins(:user_total).where('credits > ?', 0) }
  scope :only_organizations,            -> { where(access_type: User.access_types[:legal_entity]) }
  scope :by_email,                      -> (email) { where('email ~* ?', email) }
  scope :order_by,                      -> (sort_field) { order(sort_field) }
  scope :by_name,                       -> (name) { where('users.name ~* ?', name) }
  scope :by_id,                         -> (id) { where(id: id) }
  scope :by_contribution_key,           -> (key) { joins(:contributions).merge(Contribution.by_key(key)) }
  scope :subscribed_to_posts,           -> { where.not(id: Unsubscribe.where(project_id: nil).select(:user_id)) }
  scope :with_project_contributions_in, -> (project_id) { includes(:contributions).merge(Contribution.confirmed_state).where(contributions: { project_id: project_id } ) }
  scope :with_visible_projects,         -> { joins(:projects).where.not(projects: { state: ['draft', 'rejected', 'deleted', 'in_analysis'] } ) }
  scope :find_first_active,             -> (id) { active.where(id: id).first! }
  scope :staff_descriptions,            -> { STAFFS.keys.map { |description| User.human_attribute_name("staff.#{description}") } }
  scope :staff_members_query,           -> { STAFFS.values.map { |value| "staffs @> ARRAY[#{value}]" }.join(' OR ') }
  scope :by_payer_email,                ->(email) { joins(:contributions => :payment_notifications).where('extra_data ~* ?', email) }
  scope :subscribed_to_project,         -> (project_id) do
    user_ids = Unsubscribe.where(project_id: project_id).select(:user_id)

    with_project_contributions_in(project_id).where.not(id: user_ids)
  end
  scope :to_send_category_notification, -> (category_id) do
    user_ids = CategoryNotification.where(
                template_name: 'categorized_projects_of_the_week',
                category_id: category_id
                ).where('created_at >= ?', 7.days.ago).select(:user_id)

    where.not(id: user_ids)
  end
  scope :already_used_credits, -> do
    user_ids = Contribution.credits.confirmed_state.select(:user_id)

    has_credits.where(id: user_ids)
  end
  scope :has_not_used_credits_last_month, -> do
    user_ids = Contribution.credits.confirmed_state.where("created_at < ?", 1.month.ago).select(:user_id)

    has_credits.where(id: user_ids)
  end

  def send_credits_notification
    self.notify(:credits_warning)
  end

  def change_locale(language)
    update_attribute(:locale, language) unless locale == language
  end

  def active_for_authentication?
    super && !deactivated_at
  end

  def reactivate
    update_attributes(deactivated_at: nil, reactivate_token: nil)
  end

  def deactivate
    self.notify(:user_deactivate)
    transaction do
      update_attributes(deactivated_at: Time.current, reactivate_token: Devise.friendly_token)
      contributions.update_all(anonymous: true)
    end
  end

  def made_any_contribution_for_this_project?(project_id)
    contributions.available_to_count.where(project_id: project_id).exists?
  end

  def credits
    user_total.try(:credits).to_f
  end

  def projects_in_reminder
    p = Array.new
    reminder_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job['class'] == 'ReminderProjectWorker' && job.args[0] == self.id
    end
    reminder_jobs.each do |job|
      p << Project.find(job.args[1])
    end
    return p
  end

  def total_contributed_projects
    user_total.try(:total_contributed_projects).to_i
  end

  def has_no_confirmed_contribution_to_project(project_id)
    contributions.where(
      project_id: project_id
    ).with_states(
      [
        'confirmed',
        'waiting_confirmation'
      ]
    ).empty?
  end

  def created_today?
    created_at.to_date == Date.current && sign_in_count <= 1
  end

  def posts_subscription
    unsubscribes.posts_unsubscribe(nil)
  end

  def project_unsubscribes
    contributed_projects.map do |p|
      unsubscribes.posts_unsubscribe(p.id)
    end
  end

  def fix_twitter_user
    self.twitter.gsub!(/@/, '') if twitter
  end

  def fix_facebook_link
    if facebook_link && !facebook_link.starts_with?("http")
      self.facebook_link = 'http://' + facebook_link
    end
  end

  def has_valid_contribution_for_project?(project_id)
    contributions.with_state(
      [
        'confirmed',
        'requested_refund',
        'waiting_confirmation'
      ]
    ).where(project_id: project_id).exists?
  end

  def approved?
    individual? || approved_at_a_year_ago?
  end

  def pending_documents?
    individual? && !(original_doc12_url? && original_doc13_url?)
  end

  def documents_list
    return [:original_doc12_url, :original_doc13_url] if individual?

    [
      :original_doc1_url, :original_doc2_url, :original_doc3_url,
      :original_doc4_url, :original_doc5_url, :original_doc6_url,
      :original_doc7_url, :original_doc8_url, :original_doc9_url,
      :original_doc10_url, :original_doc11_url, :original_doc12_url,
      :original_doc13_url
    ]
  end

  def failed_contributed_projects
    contributed_projects.where(state: 'failed')
  end

  private

  def password_required?
    !persisted? || !password || !password_confirmation
  end

  def password_confirmation_required?
    !new_record?
  end

  def approved_at_a_year_ago?
    approved_at && approved_at > 1.year.ago
  end
end
