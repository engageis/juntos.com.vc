require 'rails_helper'

RSpec.describe PlansController, :type => :controller do

  describe 'GET index' do
    let!(:recurring_contribution_plans) { create_list(:plan, 3).to_json }

    it 'should return all recurring contribution plans' do
      get :index, locale: :pt
      expect(response.body).to eq(recurring_contribution_plans)
    end
  end
end
