require 'spec_helper'

shared_examples_for 'platform user with reader rights' do
  include_examples 'platform user with show rights'

  [:members, :advisories].each do |action|
    it 'should be able to perform advisories action' do
      get action, id: @platform.id
      expect(response).to render_template(action)
      expect(response).to be_success
    end
  end
end

shared_examples_for 'platform user with owner rights' do

  context 'platform user with update rights' do
    before do
      put :update, {platform: {description: 'new description'}, id: @platform.id}
    end

    it 'should be able to perform update action' do
      expect(response).to redirect_to(platform_path(@platform))
    end
    it 'ensures that platform has been updated' do
      expect(@platform.reload.description).to eq 'new description'
    end
  end

  context 'perform change_visibility action' do
    before do
      @visibility = @platform.visibility
      post :change_visibility, id: @platform.id
    end

    it 'should be able to perform action' do
      expect(response).to redirect_to(platform_path(@platform))
    end

    it 'ensures that visibility of platform has been changed' do
      expect(@platform.reload.visibility).to_not eq @visibility
    end
  end

  context 'platform user with destroy rights for main platforms only' do
    it 'should be able to perform destroy action for main platform' do
      delete :destroy, id: @platform.id
      expect(response).to redirect_to(platforms_path)
    end
    it 'ensures that main platform has been destroyed' do
      expect do
        delete :destroy, id: @platform.id
      end.to change(Platform, :count).by(-1)
    end
    it 'should not be able to perform destroy action for personal platform' do
      delete :destroy, id: @personal_platform.id
      expect(response).to_not be_success
    end
    it 'ensures that personal platform has not been destroyed' do
      expect do
        delete :destroy, id: @personal_platform.id
      end.to_not change(Platform, :count)
    end
  end
end

shared_examples_for 'platform user without owner rights' do
  context 'platform user without update rights' do
    before do
      put :update, {platform: {description: 'new description'}, id: @platform.id}
    end

    it 'should not be able to perform update action' do
      expect(response).to_not be_success
    end
    it 'ensures that platform has not been updated' do
      expect(@platform.reload.description).to_not eq 'new description'
    end
  end

  context 'perform change_visibility action' do
    before do
      @visibility = @platform.visibility
      post :change_visibility, id: @platform.id
    end

    it 'should not be able to perform action' do
      expect(response).to_not be_success
    end

    it 'ensures that visibility of platform has not been changed' do
      expect(@platform.reload.visibility).to eq @visibility
    end
  end

  context 'platform user without destroy rights' do
    it 'should not be able to perform destroy action for main platform' do
      delete :destroy, id: @platform.id
      expect(response).to_not be_success
    end
    it 'ensures that main platform has not been destroyed' do
      expect do
        delete :destroy, id: @platform.id
      end.to_not change(Platform, :count)
    end
    it 'should not be able to perform destroy action for personal platform' do
      delete :destroy, id: @personal_platform.id
      expect(response).to_not be_success
    end
    it 'ensures that personal platform has not been destroyed' do
      expect do
        delete :destroy, id: @personal_platform.id
      end.to_not change(Platform, :count)
    end
  end

end

shared_examples_for 'platform user with member rights' do

  context 'platform user with add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {member_id: member.id, id: @platform.id}
    end

    it 'should be able to perform add_member action' do
      expect(response).to redirect_to(members_platform_path(@platform))
    end
    it 'ensures that new member has been added to platform' do
      expect(@platform.members).to include(member)
    end
  end

  context 'platform user with remove_members rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @platform.add_member(member)
      post :remove_members, members: [member.id], id: @platform.id
    end

    it 'should be able to perform remove_members action' do
      expect(response).to redirect_to(members_platform_path(@platform))
    end
    it 'ensures that member has been removed from platform' do
      expect(@platform.members).to_not include(member)
    end
  end

end

shared_examples_for 'platform user without member rights' do |guest = false|

  context 'platform user without add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {member_id: member.id, id: @platform.id}
    end

    it 'should not be able to perform add_member action' do
      expect(response).to redirect_to(guest ? new_user_session_path : forbidden_path)
    end
    it 'ensures that new member has not been added to platform' do
      expect(@platform.members).to_not include(member)
    end
  end

  context 'platform user without remove_members rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @platform.add_member(member)
      post :remove_members, members: [member.id], id: @platform.id
    end

    it 'should not be able to perform remove_members action' do
      expect(response).to redirect_to(guest ? new_user_session_path : forbidden_path)
    end
    it 'ensures that member has not been removed from platform' do
      expect(@platform.members).to include(member)
    end
  end

end

shared_examples_for 'platform user without global admin rights' do
  context 'should not be able to perform clear action' do
    it 'for personal platform' do
      put :clear, id: @personal_platform.id
      expect(response).to_not be_success
    end
    it 'for main platform' do
      put :clear, id: @platform.id
      expect(response).to_not be_success
    end
  end

  context 'should not be able to perform clone action' do
    it 'for personal platform' do
      get :clone, id: @personal_platform.id
      expect(response).to_not be_success
    end
    it 'for main platform' do
      get :clone, id: @platform.id
      expect(response).to_not be_success
    end
  end

  it 'should not be able to perform new action' do
    get :new
    expect(response).to_not be_success
  end

  [:create, :make_clone].each do |action|
    context "platform user without #{action} rights" do
      it "should not be able to perform #{action} action" do
        post action, clone_or_create_params
        expect(response).to_not be_success
      end
      it "ensures that platform has not been #{action}d" do
        expect do
          post action, clone_or_create_params
        end.to_not change(Platform, :count)
      end
    end
  end
end

shared_examples_for 'platform user with reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'platform user with show rights'
end

shared_examples_for 'platform user without reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  [:show, :members].each do |action|
    it "should not be able to perform #{ action } action" do
      get action, id: @platform.id
      expect(response).to redirect_to(forbidden_path)
    end
  end
end

shared_examples_for 'platform user with show rights' do
  it 'should be able to perform show action' do
    get :show, id: @platform.id
    expect(response).to render_template(:show)
    expect(assigns(:platform)).to eq @platform
  end
end

describe Platforms::PlatformsController, type: :controller do
  let(:clone_or_create_params) { {id: @platform.id, platform: {description: 'new description', name: 'new_name', owner_id: @user.id, distrib_type: APP_CONFIG['distr_types'].first, default_branch: 'new_name'}} }
  before do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @personal_platform = FactoryGirl.create(:platform, platform_type: 'personal')

    @user = FactoryGirl.create(:user)
  end

  context 'for guest' do

    it "should not be able to perform index action" do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    [:show, :members, :advisories].each do |action|
      it "should not be able to perform #{ action } action", anonymous_access: false do
        get action, id: @platform
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it_should_behave_like 'platform user with show rights' if APP_CONFIG['anonymous_access']
    it_should_behave_like 'platform user without reader rights for hidden platform' if APP_CONFIG['anonymous_access']
    it_should_behave_like 'platform user without member rights', true
    it_should_behave_like 'platform user without owner rights'
    it_should_behave_like 'platform user without global admin rights'
  end

  context 'for global admin' do
    before do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'platform user with reader rights'
    it_should_behave_like 'platform user with reader rights for hidden platform'
    it_should_behave_like 'platform user with member rights'
    it_should_behave_like 'platform user with owner rights'

    it "should be able to perform new action" do
      get :new, id: @platform
      expect(response).to render_template(:new)
    end

    it "should be able to perform clone action" do
      get :clone, id: @platform
      expect(response).to render_template(:clone)
    end

    [:make_clone, :create].each do |action|
      context "with #{action} rights" do
        before do
          clone_or_create_params[:platform][:owner_id] = @admin.id
        end
        it "should be able to perform #{action} action" do
          post action, clone_or_create_params
          expect(response).to redirect_to(platform_path(Platform.last))
        end
        it "ensures that platform has been #{action}d" do
          expect do
            post action, clone_or_create_params
          end.to change(Platform, :count).by(1)
        end
      end
    end
  end

  context 'for owner user' do
    before do
      http_login(@user)
      @platform.owner = @user; @platform.save
      create_relation(@platform, @user, 'admin')
    end

    it_should_behave_like 'platform user with reader rights'
    it_should_behave_like 'platform user with reader rights for hidden platform'
    it_should_behave_like 'platform user with member rights'
    it_should_behave_like 'platform user with owner rights'
    it_should_behave_like 'platform user without global admin rights'
  end

  context 'for member of platform' do
    before do
      http_login(@user)
      @platform.add_member(@user)
      @personal_platform.add_member(@user)
    end

    it_should_behave_like 'platform user with reader rights'
    it_should_behave_like 'platform user with reader rights for hidden platform'
    it_should_behave_like 'platform user with member rights'
    it_should_behave_like 'platform user without owner rights'
    it_should_behave_like 'platform user without global admin rights'
  end

  context 'for member of repository' do
    before do
      http_login(@user)
      repository = FactoryGirl.create(:repository, platform: @platform)
      repository.add_member(@user)
      personal_repository = FactoryGirl.create(:repository, platform: @personal_platform)
      personal_repository.add_member(@user)
    end

    it_should_behave_like 'platform user with reader rights'
    it_should_behave_like 'platform user with reader rights for hidden platform'
    it_should_behave_like 'platform user without member rights'
    it_should_behave_like 'platform user without owner rights'
    it_should_behave_like 'platform user without global admin rights'
  end

  context 'for simple user' do
    before do
      http_login(@user)
    end

    it "should be able to perform index action" do
      get :index
      expect(response).to render_template(:index)
    end

    it_should_behave_like 'platform user with reader rights'
    it_should_behave_like 'platform user without reader rights for hidden platform'
    it_should_behave_like 'platform user without member rights'
    it_should_behave_like 'platform user without owner rights'
    it_should_behave_like 'platform user without global admin rights'
  end

end
