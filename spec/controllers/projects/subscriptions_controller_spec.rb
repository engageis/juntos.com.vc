require 'rails_helper'

RSpec.describe Projects::SubscriptionsController, type: :controller do
  let(:ssl_options) {{ protocol: 'http', host: CatarseSettings[:secure_host] }}

  describe "POST update_status" do
    it_behaves_like "update status controller's method" do
      let!(:resource) { create(:subscription, subscription_code: 10, status: 'unpaid') }
      let(:pagarme_request_params) do
        {
          id:             '10',
          event:          'subscription_status_changed',
          object:         'subscription',
          old_status:     'unpaid',
          current_status: 'paid',
          desired_status: 'paid'
        }
      end
    end
  end

  describe "GET new" do
    let(:project) { create(:project) }

    context "when there is a logged user" do
      let(:current_user) { create(:user) }

      it "should instanciate a subscription" do
        sign_in current_user
        get :new, { locale: :pt, project_id: project.id }.merge(ssl_options)
        expect(assigns(:subscription)).to be_a_new(Subscription)
      end
    end

    context "when no user is logged in" do
      it "should return an unauthorized error" do
        get :new, { locale: :pt, project_id: project.id }.merge(ssl_options)
        expect(response).to redirect_to new_user_registration_path
      end
    end
  end

  describe "POST create" do
    let(:project) { create(:project) }
    let(:plan)    { create(:plan) }

    context "when there is a logged user" do
      let(:current_user) { create(:user) }
      let(:credit_card_params) { { credit_card_hash: build(:credit_card) } }
      let(:params) do
        {
          plan_id:          plan.id,
          charging_day:     7,
          project_id:       project.id,
          payment_method:   'credit_card',
          user_id:          current_user.id
        }.merge(credit_card_params)
      end

      before do
        allow_any_instance_of(RecurringContribution::Subscriptions::Processor)
          .to receive(:process).and_return(subscription)

        sign_in current_user

        post :create, { locale: :pt,
                        project_id: project.id,
                        subscription: params }.merge(ssl_options)
      end

      context "when the subscription is successfully created" do
        let(:subscription) { create(:subscription, project: project, plan: plan, user: current_user) }

        it "should send a success flash message to the user" do
          expect(flash[:notice]).to match I18n.t('project.subscription.create.success')
        end

        it "should redirect_to project show page" do
          expect(response).to redirect_to project_path project
        end
      end

      context "when the subscription is not created" do
        let(:subscription) do
          Subscription.create(
            plan:           nil,
            project:        project,
            user:           current_user,
            charging_day:   5,
            payment_method: :credit_card,
            status:         :unpaid
          )
        end

        let(:plan_error_message) do
          I18n.t('activerecord.attributes.subscription.plan_id') + ' ' + \
          I18n.t('errors.messages.blank')
        end

        before do
          allow_any_instance_of(RecurringContribution::Subscriptions::Processor)
            .to receive(:process).and_return(subscription)

          post :create, { locale: :pt,
                          project_id: project.id,
                          subscription: params }.merge(ssl_options)
        end

        it "should send a flash alert message to the user" do
          expect(flash[:alert]).to match plan_error_message
        end

        xit "should redirect to the new subscription page" do
          expect(response).to redirect_to :new
        end
      end
    end

    context "when no user is logged in" do
      let(:credit_card_params) { { credit_card_hash: build(:credit_card) } }
      let(:params) do
        {
          plan_id:          plan.id,
          charging_day:     7,
          project_id:       project.id,
          payment_method:   'credit_card',
          user_id:          nil
        }.merge(credit_card_params)
      end

      it "should return an unauthorized error" do
        post :create, { locale: :pt,
                        project_id: project.id,
                        subscription: params }.merge(ssl_options)

        expect(response).to redirect_to new_user_registration_path
      end
    end
  end

  describe "POST cancel" do
    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, user: user) }

    context "when no user is logged in" do
      it "should redirect to registrations path" do
        post :cancel, { id: subscription.id }.merge(ssl_options)
        expect(response).to redirect_to new_user_registration_path
      end
    end

    context "when there is a logged user" do
      before do
        sign_in user
      end

      context "when the subscription is successfully updated" do
        it "should return a success flash message" do
          allow_any_instance_of(RecurringContribution::Subscriptions::CancelOnPagarme)
            .to receive(:process).and_return(true)
            
          post :cancel, { id: subscription.id }.merge(ssl_options)

          expect(flash[:notice]).to match I18n.t('project.subscription.cancel.success')
        end
      end

      context "when a problem occurs on the subscription updation" do
        context "when the subscription was not found" do
          it "should return an flash message notifying the error" do
            allow_any_instance_of(RecurringContribution::Subscriptions::CancelOnPagarme)
              .to receive(:process).and_raise(Pagarme::API::ResourceNotFound)

            post :cancel, { id: subscription.id }.merge(ssl_options)

            expect(flash[:notice]).to match I18n.t('project.subscription.cancel.errors.not_found')
          end
        end

        context "when the connection with PagarMe API was lost" do
          it "should return an flash message notifying the error" do
            allow_any_instance_of(RecurringContribution::Subscriptions::CancelOnPagarme)
              .to receive(:process).and_raise(Pagarme::API::ConnectionError)

            post :cancel, { id: subscription.id }.merge(ssl_options)

            expect(flash[:notice]).to match I18n.t('project.subscription.cancel.errors.connection_fails')
          end
        end
      end
    end
  end
end
