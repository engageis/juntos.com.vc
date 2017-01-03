require 'rails_helper'

RSpec.describe ProjectPolicy do
  subject{ ProjectPolicy }

  shared_examples_for "create permissions" do
    it "should deny access if user is nil" do
      is_expected.not_to permit(nil, Project.new)
    end

    it "should deny access if user is not project owner" do
      is_expected.not_to permit(User.new, Project.new(user: User.new))
    end

    it "should permit access if user is project owner" do
      new_user = User.new
      is_expected.to permit(new_user, Project.new(user: new_user))
    end

    it "should permit access if user is admin" do
      admin = User.new
      admin.admin = true
      is_expected.to permit(admin, Project.new(user: User.new))
    end
  end

  describe 'UserScope' do
    describe ".resolve" do
      let(:current_user) { create(:user, admin: false) }
      let(:user) { create(:user) }

      before do
        create(:project, :draft, name: 'draft', user: user)
        create(:project, :online, name: 'online', user: user)
        create(:project, :in_analysis, name: 'in_analysis', user: user)
      end

      subject { ProjectPolicy::UserScope.new(current_user, user, user.projects).resolve.order('created_at desc').map(&:name) }

      context "when user is admin" do
        let(:current_user) { create(:user, admin: true) }

        it { is_expected.to match_array(['draft', 'online', 'in_analysis']) }
      end

      context "when user is a project owner" do
        let(:current_user) { user }

        it { is_expected.to eq(['in_analysis', 'online', 'draft']) }
      end

      context "when user is not an admin and project owner" do
        it { is_expected.to eq(['online']) }
      end
    end
  end

  permissions :create? do
    it_should_behave_like "create permissions"
  end


  permissions :update? do
    it_should_behave_like "create permissions"
  end

  permissions :send_to_analysis? do
    it_should_behave_like "create permissions"
  end

  permissions :edit_partner? do
    it "should deny access if user is nil" do
      is_expected.not_to permit(nil, Project.new)
    end

    it "should deny access if user is not project owner" do
      is_expected.not_to permit(User.new, Project.new(user: User.new))
    end

    it "should deny access if user is project owner" do
      new_user = User.new
      is_expected.not_to permit(new_user, Project.new(user: new_user))
    end

    it "should permit access if user is admin" do
      admin = User.new
      admin.admin = true
      is_expected.to permit(admin, Project.new(user: User.new))
    end
  end

  describe '#permitted_attributes' do
    let(:policy)  { ProjectPolicy.new(user, project) }
    let(:project) { create(:project, :online) }
    let(:basic_project_attributes) do
      [:about, :video_url, :uploaded_image, :headline]
    end
    let(:all_project_attributes) do
      project_attributes +
      nested_project_attributes +
      post_attributes
    end
    let(:project_attributes) do
      Project.attribute_names.map(&:to_sym) - [:created_at, :updated_at]
    end
    let(:project_owner_allowed_attributes) do
      [
        :name, :video_url, :about, :thank_you, :uploaded_image,
        :uploaded_cover_image, :headline, :original_uploaded_image,
        :original_uploaded_cover_image,
        project_images_attributes: [:original_image_url, :caption, :id, :_destroy],
        project_partners_attributes: [:original_image_url, :link, :id, :_destroy],
        posts_attributes: [:title, :comment, :exclusive, :user_id]
      ]
    end
    let(:nested_project_attributes) do
      [
        channel_ids: [],
        plan_ids: [],
        project_images_attributes: [:original_image_url, :caption, :id, :_destroy],
        project_partners_attributes: [:original_image_url, :link, :id, :_destroy]
      ]
    end
    let(:post_attributes) do
      [ posts_attributes: [:title, :comment, :exclusive, :user_id] ]
    end

    subject { policy.permitted_attributes.values.first }

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to match_array(basic_project_attributes) }
    end

    context 'when user is not nil' do
      let(:user) { create(:user) }

      context 'and user is admin' do
        let(:user) { create(:user, admin: true) }

        it 'should have all the project attributes' do
          is_expected.to match_array(all_project_attributes)
        end
      end

      context 'and user is not admin' do
        context 'and user is channel admin' do
          let(:channel) { create(:channel, users: [user]) }
          let(:project) { create(:project, channels: [channel]) }

          it 'should have all the project attributes' do
            is_expected.to match_array(all_project_attributes)
          end
        end

        context 'and user is not channel admin' do
          context 'and project is visible' do
            let(:project) { create(:project, :online) }

            context 'and user owns the project' do
              let(:project) { create(:project, :online, user: user) }

              it { is_expected.to match_array(project_owner_allowed_attributes) }
            end

            context 'and user does not own the project' do
              it { is_expected.to match_array(basic_project_attributes) }
            end
          end

          context 'and project is invisible' do
            context 'and project is draft' do
              let(:project) { create(:project, :draft) }

              it 'should have all the project attributes' do
                is_expected.to match_array(all_project_attributes)
              end
            end

            context 'and project is rejected' do
              let(:project) { create(:project, :rejected) }

              it 'should have all the project attributes' do
                is_expected.to match_array(all_project_attributes)
              end
            end

            context 'and project is in_analysis' do
              let(:project) { create(:project, :in_analysis) }

              it 'should have all the project attributes' do
                is_expected.to match_array(all_project_attributes)
              end
            end
          end
        end
      end
    end
  end
end
