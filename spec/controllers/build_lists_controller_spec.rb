require 'spec_helper'

describe BuildListsController do
  context 'crud' do
    context 'for guest' do
      it 'should not be able to perform all action' do
        get :all
        response.should redirect_to(new_user_session_path)
      end
    end

    context 'for user' do
      before(:each) { set_session_for Factory(:user) }
  
      it 'should not be able to perform all action' do
        get :all
        response.should redirect_to(forbidden_url)
      end
    end

    context 'for admin' do
      before(:each) { set_session_for Factory(:admin) }

      it "should be able to perform all action without exception" do
        any_instance_of(XMLRPC::Client) do |xml_rpc|
          stub(xml_rpc).call do |args|
            raise Timeout::Error
          end
        end
        get :all
        assigns[:build_server_status].should == {}
        response.should be_success
      end    
    end
  end

  context 'filter' do
    let(:build_list1) { Factory(:build_list_core) }
    let(:build_list2) { Factory(:build_list_core) }
    let(:build_list3) { Factory(:build_list_core) }
    let(:build_list4) do
      b = Factory(:build_list_core)
      b.created_at = b.created_at - 1.day
      b.project = build_list3.project
      b.pl = build_list3.pl
      b.arch = build_list3.arch
      b.save
      b
    end
    before(:each) { set_session_for Factory(:admin); stub_rsync_methods; }

    it 'should filter by bs_id' do
      get :all, :filter => {:bs_id => build_list1.bs_id, :project_name => 'fdsfdf', :any_other_field => 'do not matter'}
      assigns[:build_lists].should include(build_list1)
      assigns[:build_lists].should_not include(build_list2)
      assigns[:build_lists].should_not include(build_list3)
    end

    it 'should filter by project_name' do
      # Project.where(:id => build_list2.project.id).update_all(:name => 'project_name')
      get :all, :filter => {:project_name => build_list2.project.name}
      assigns[:build_lists].should_not include(build_list1)
      assigns[:build_lists].should include(build_list2)
      assigns[:build_lists].should_not include(build_list3)
    end

    it 'should filter by project_name and start_date' do
      get :all, :filter => {:project_name => build_list3.project.name, 
                            "created_at_start(1i)"=>build_list3.created_at.year.to_s,
                            "created_at_start(2i)"=>build_list3.created_at.month.to_s,
                            "created_at_start(3i)"=>build_list3.created_at.day.to_s}
      assigns[:build_lists].should_not include(build_list1)
      assigns[:build_lists].should_not include(build_list2)
      assigns[:build_lists].should include(build_list3)
      assigns[:build_lists].should_not include(build_list4)
#      response.should be_success
    end
  end

  context 'callbacks' do
  end
end
