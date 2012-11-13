# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'product build list admin' do

  it "should be able to perform create action" do
    expect {
      post :create, valid_attributes
    }.to change(ProductBuildList, :count).by(1)
    response.should redirect_to([@product.platform, @product])
  end

  it "should be able to perform destroy action" do
    @pbl.update_column(:project_id, nil)
    expect {
      delete :destroy, valid_attributes_for_destroy
    }.to change(ProductBuildList, :count).by(-1)
    response.should redirect_to([@pbl.product.platform, @pbl.product])
  end

  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end

  it 'should be able to perform stop action' do
    get :stop, valid_attributes_for_show
    response.should redirect_to(platform_product_product_build_list_path(@product.platform, @product, @pbl))
  end

  it 'should be able to perform show action' do
    get :show, valid_attributes_for_show
    response.should render_template(:show)
  end

  it 'should be able to perform log action' do
    get :log, valid_attributes_for_show
    response.should be_success
  end

end

shared_examples_for 'product build list user without admin rights' do
  it 'should not be able to perform create action' do
    expect {
      post :create, valid_attributes
    }.to change(ProductBuildList, :count).by(0)
    response.should_not be_success
  end

  it 'should not be able to perform destroy action' do
    @pbl.update_column(:project_id, nil)
    expect {
      delete :destroy, valid_attributes_for_destroy
    }.to change(ProductBuildList, :count).by(0)
    response.should_not be_success
  end

  it 'should not be able to perform stop action' do
    get :stop, valid_attributes_for_show
    response.should_not redirect_to(platform_product_product_build_list_path(@product.platform, @product, @pbl))
  end
end

shared_examples_for 'product build list user' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, valid_attributes_for_show
    response.should render_template(:show)
  end

  it 'should be able to perform log action' do
    get :log, valid_attributes_for_show
    response.should be_success
  end
end

describe Platforms::ProductBuildListsController do
  before(:each) do
    stub_symlink_methods
  end

  context 'crud' do

    before(:each) do
      @product = FactoryGirl.create(:product)
      @arch = FactoryGirl.create(:arch)
      @pbl = FactoryGirl.create(:product_build_list, :product => @product)
    end

    def valid_attributes
      {:product_id => @product.id, :platform_id => @product.platform_id, :product_build_list => {:main_script => 'build.sh', :time_living => 60, :project_version => 'latest_master', :arch_id => @arch.id}}
    end

    def valid_attributes_for_destroy
      {:id => @pbl.id, :product_id => @pbl.product.id, :platform_id => @pbl.product.platform.id }
    end
    
    def valid_attributes_for_show
      valid_attributes_for_destroy
    end

    context 'for guest' do
      it_should_behave_like 'product build list user without admin rights'

      if APP_CONFIG['anonymous_access']
        it_should_behave_like 'product build list user'
      else
        [:index, :show, :log].each do |action|
          it "should not be able to perform #{action}" do
            get action, valid_attributes_for_show
            response.should redirect_to(new_user_session_path)
          end
        end
      end
    end

    context 'for user' do
      before(:each) { set_session_for FactoryGirl.create(:user) }
  
      it_should_behave_like 'product build list user'
      it_should_behave_like 'product build list user without admin rights'

    end

    context 'for platform admin' do
      before(:each) do
        @user = FactoryGirl.create(:user)
        set_session_for(@user)
        @pbl.product.platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      end

      it_should_behave_like 'product build list admin'
      it_should_behave_like 'product build list user'
    end

    context 'for global admin' do
      before(:each)  {  set_session_for FactoryGirl.create(:admin) }

      it_should_behave_like 'product build list admin'
      it_should_behave_like 'product build list user'
      
    end
  end

  context 'callbacks' do

    let(:pbl) { FactoryGirl.create(:product_build_list) }
  
    before(:each) do
      mock(controller).authenticate_product_builder! {true}
    end

    def do_get
      get :status_build, :id => pbl.id, :status => ProductBuildList::BUILD_FAILED
      pbl.reload
    end

    it "should update ProductBuildList status" do
      expect { do_get }.to change(pbl, :status).to(ProductBuildList::BUILD_FAILED)
      response.should be_success
      response.body.should be_blank
    end
  end
end
