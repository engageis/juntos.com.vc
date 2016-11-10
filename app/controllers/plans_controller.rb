class PlansController < ApplicationController
  def index
    render json: Plan.all
  end
end
