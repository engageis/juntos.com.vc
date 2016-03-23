require 'rails_helper'

RSpec.describe ProjectImage, type: :model do
  it { is_expected.to belong_to :project }
  it { is_expected.to validate_presence_of :original_image_url }
end
