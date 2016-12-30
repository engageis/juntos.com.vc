FactoryGirl.define do
  sequence :name do |n|
    "Foo bar #{n}"
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :uid do |n|
    "#{n}"
  end

  sequence :permalink do |n|
    "foo_page_#{n}"
  end

  factory :channel_partner do |f|
    f.url "http://google.com"
    f.image File.open("#{Rails.root}/spec/support/testimg.png")
    f.association :channel
  end

  factory :category_follower do |f|
    f.association :user
    f.association :category
  end

  factory :user do |f|
    f.name "Foo bar"
    f.password "123456"
    f.email { generate(:email) }
    f.bio "This is Foo bar's biography."

    factory :user_with_projects do
      transient do
        projects_count 1
      end

      after(:create) do |user, evaluator|
        create_list(:project, evaluator.projects_count, user: user)
      end
    end

    trait :without_id_document do
      original_doc12_url nil
    end

    trait :with_id_document do
      original_doc12_url '903.123.209-43'
    end

    trait :without_proof_of_residence do
      original_doc13_url nil
    end

    trait :with_proof_of_residence do
      original_doc13_url 'proof of residence'
    end

    trait :deactivated do
      deactivated_at Time.now
    end

    trait :legal_entity do
      access_type 'legal_entity'
    end

    trait :individual do
      access_type 'individual'
    end
  end

  factory :category do |f|
    f.name_pt { generate(:name) }
  end

  factory :subgoal do |f|
    f.association :project, factory: :project
    f.color 'foo'
    f.value 15.0
    f.description "Lorem Ipsum"
  end

  factory :project do |f|
    f.name "Foo bar"
    f.permalink { generate(:permalink) }
    f.association :user, factory: :user
    f.association :category, factory: :category
    f.about "Foo bar"
    f.headline "Foo bar"
    f.goal 10000
    f.online_date Time.now
    f.online_days 5
    f.more_links 'Ipsum dolor'
    f.first_contributions 'Foo bar'
    f.video_url 'http://vimeo.com/17298435'
    f.state 'online'

    factory :project_with_channel do
      after(:create) do |project|
        channel = create :channel
        project.channels << channel
      end
    end

    trait :online do
      state 'online'
    end

    trait :failed do
      state 'failed'
    end

    trait :rejected do
      state 'rejected'
    end

    trait :deleted do
      state 'deleted'
    end

    trait :in_analysis do
      state 'in_analysis'
    end

    trait :draft do
      state 'draft'
    end

    trait :successful do
      state 'successful'
    end

    trait :waiting_funds do
      state 'waiting_funds'
    end

    trait :expired do
      online_date 10.days.ago
      online_days 1
    end

    trait :not_expired do
      online_date Date.current
      online_days 10
    end

    trait :successful do
      state 'successful'
    end

    trait :waiting_funds do
      state 'waiting_funds'
    end

    trait :failed do
      state 'failed'
    end

    trait :deleted do
      state 'deleted'
    end

    trait :available_for_contributions do
      available_for_contribution true
    end

    trait :unavailable_for_contributions do
      available_for_contribution false
    end
  end

  factory :channels_subscriber do |f|
    f.association :user
    f.association :channel
  end

  factory :unsubscribe do |f|
    f.association :user, factory: :user
    f.association :project, factory: :project
  end

  factory :notification do |f|
    f.association :user, factory: :user
    f.association :contribution, factory: :contribution
    f.association :project, factory: :project
    f.template_name 'project_success'
    f.origin_name 'Foo Bar'
    f.origin_email 'foo@bar.com'
    f.locale 'pt'
  end

  factory :reward do |f|
    f.association :project, factory: :project
    f.minimum_value 10.00
    f.description "Foo bar"
    f.deliver_at 10.days.from_now
  end

  factory :contribution do |f|
    f.association :project, factory: :project
    f.association :user, factory: :user
    f.confirmed_at Time.now
    f.value 10.00
    f.project_value 10.00
    f.state 'confirmed'
    f.credits false
    f.payment_id '1.2.3'

    factory :failed_contribution_project do
      after(:create) do |contribution|
        contribution.project.update_attribute(:state, 'failed')
      end
    end

    trait :slip_payment do
      payment_choice 'boletobancario'
    end

    trait :confirmed do
      state 'confirmed'
    end

    trait :requested_refund do
      state 'requested_refund'
    end

    trait :pending do
      state 'pending'
    end

    trait :waiting_confirmation do
      state 'waiting_confirmation'
    end

    trait :canceled do
      state 'canceled'
    end

    trait :refunded do
      state 'refunded'
    end

    trait :refunded_and_canceled do
      state 'refunded_and_canceled'
    end

    trait :deleted do
      state 'deleted'
    end

    trait :invalid_payment do
      state 'invalid_payment'
    end
  end

  factory :payment_notification do |f|
    f.association :contribution, factory: :contribution
    f.extra_data {}
  end

  factory :authorization do |f|
    f.association :oauth_provider
    f.association :user
    f.uid 'Foo'
  end

  factory :oauth_provider do |f|
    f.name 'facebook'
    f.strategy 'GitHub'
    f.path 'github'
    f.key 'test_key'
    f.secret 'test_secret'
  end

  factory :configuration do |f|
    f.name 'Foo'
    f.value 'Bar'
  end

  factory :institutional_video do |f|
    f.title "My title"
    f.description "Some Description"
    f.video_url "http://vimeo.com/35492726"
    f.visible false
  end

  factory :project_post do |f|
    f.association :project, factory: :project
    f.association :user, factory: :user
    f.title "My title"
    f.comment "This is a comment"
    f.comment_html "<p>This is a comment</p>"
  end

  factory :channel do |f|
    f.association :category
    name "Test"
    email "email+channel@foo.bar"
    description "Lorem Ipsum"
    sequence(:permalink) { |n| "#{n}-test-page" }

    trait :visible do
      visible true
    end

    trait :invisible do
      visible false
    end

    trait :recurring do
      recurring true
    end

    trait :non_recurring do
      recurring false
    end
  end

  factory :state do
    name "RJ"
    acronym "RJ"
  end

  factory :bank do
    name "Foo"
    sequence(:code) { |n| n.to_s.rjust(3, '0') }
  end

  factory :bank_account do |f|
    f.association :user, factory: :user
    f.association :bank, factory: :bank
    owner_name "Foo"
    owner_document "000"
    account_digit "1"
    agency "1"
    account "1"
  end

  factory :channel_post do |f|
    f.association :user, factory: :user
    f.association :channel, factory: :channel
    title "My title"
    f.body "This is a comment"
    f.body_html "<p>This is a comment</p>"
  end

  factory :recurring_contribution do |f|
    before(:create) do |contribution|
      channel = FactoryGirl.create(:channel, recurring: true)

      contribution.project = FactoryGirl.create(:project, channels: [channel])
    end

    f.association :user, factory: :user
    value 100
  end

  factory :project_image do |f|
    f.association :project, factory: :project
    f.caption 'Image caption'
    f.original_image_url 'http://juntos.com.vc/assets/juntos/logo-small.png'
  end

  factory :project_partner do |f|
    f.association :project, factory: :project
    f.link 'http://juntos.com.vc'
    f.original_image_url 'http://juntos.com.vc/assets/juntos/logo-small.png'
  end

  factory :page do |f|
    f.name Page.names.keys.sample
    f.content "Some random content"
  end

  factory :transparency_report do |f|
    f.attachment File.open("#{Rails.root}/spec/support/testimg.png")
    f.previous_attachment File.open("#{Rails.root}/spec/support/testimg.png")
  end

  factory :site_partner do |f|
    f.name 'foo_bar'
    f.url  'foo_url_bar'
    f.logo File.open("#{Rails.root}/spec/support/testimg.png")

    trait :featured do
      featured true
    end

    trait :regular do
      featured false
    end
  end

  factory :home_banner do |f|
    f.numeric_order 10
    f.image File.open("#{Rails.root}/spec/support/testimg.png")
  end

  factory :plan do |f|
    f.plan_code { rand(1..100) }
    f.name 'Foo Plan'
    f.amount 30
    f.payment_methods [:credit_card, :bank_billet]

    trait :invalid_payment_method do
      payment_methods [:unknown]
    end

    trait :with_credit_card do
      payment_methods [:credit_card]
    end

    trait :with_bank_billet do
      payment_methods [:bank_billet]
    end
  end

  factory :subscription do |f|
    f.subscription_code { rand(1..100) }
    f.payment_method :credit_card
    f.status :paid
    f.charging_day 5
    f.association :project, factory: :project
    f.association :plan, factory: :plan
    f.association :user, factory: :user

    trait :bank_billet_payment do
      payment_method 'bank_billet'
    end

    trait :credit_card_payment do
      payment_method 'credit_card'
    end

    trait :waiting_for_charging_day do
      status :waiting_for_charging_day
    end

    trait :unpaid do
      status :unpaid
    end
  end

  factory :transaction do |f|
    f.transaction_code { rand(1..100) }
    f.status :processing
    f.amount 30
    f.payment_method :credit_card
    f.association :subscription, factory: :subscription
  end

  factory :credit_card, class: Hash do |f|
    f.send(:card_number, '4929234122840114')
    f.send(:card_holder_name, 'Jose da Silva')
    f.send(:card_expiration_month, '03')
    f.send(:card_expiration_year, '18')
    f.send(:card_cvv, '875')

    initialize_with {attributes.stringify_keys}
  end
end
