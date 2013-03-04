require 'spec_helper'

def create_user(username = "test1", name = "Tester")
  user = JSONModel(:user).from_hash(:username => username,
                                    :name => name)

  # Probably more realistic than we'd care to think
  user.save(:password => "password")
end


describe 'User controller' do

  before(:each) do
    create_user
  end


  it "allows admin users to create new users" do
    expect {
      build(:json_user).save(:password => '123')
    }.to_not raise_error(AccessDeniedException)
  end


  it "reports an error when requesting a nonexistent user" do
    resp = get "/users/343439"
    resp.status.should eq (404)
  end
  

  it "can give a list of users" do
    a_user = create(:user)
    users = JSONModel(:user).all(:page => 1)['results']

    users.any? { |user| user.username == "admin" }.should be_true
    users.any? { |user| user.username == "test1" }.should be_true
    users.any? { |user| user.username == a_user.username }.should be_true
  end


  it "allows admin users to update existing usernames" do
    new_username = generate(:username) 
    
    otheruser = build(:json_user)
    otheruser.save(:password => '123')
    otheruser.username.should_not eq(new_username)
    
    updated = build(:json_user, {:username => new_username})
    otheruser.update(updated)
    otheruser.username.should eq(new_username)
    otheruser.save(:password => '456')
    user = JSONModel(:user).find(otheruser.id)
    user.username.should eq(new_username)
  end 


  it "allows usernames with hyphens" do
    user = build(:json_user, :username => "herman-toothrot")
    user.save(:password => '123')

    user.username.should eq("herman-toothrot")
  end


  it "does allow anonymous users to create new users and hence become non-anonymous users" do
    expect {
      as_anonymous_user do
        build(:json_user).save(:password => '123')
      end
    }.to_not raise_error(AccessDeniedException)
  end


  it "rejects a login attempt against an unknown username" do
    post '/users/notauserXXXXXX/login', params = { "password" => "wrongpwXXXXX"}
    last_response.should_not be_ok
    last_response.status.should eq(403)
  end


  it "expects a password" do
    post '/users/test1/login', params = {}
    last_response.should_not be_ok
    last_response.status.should eq(400)
  end


  it "rejects a bad password" do
    post '/users/test1/login', params = { "password" => "wrongpwXXXXX"}
    last_response.should_not be_ok
    last_response.status.should eq(403)
  end


  it "returns a session id if login is successful" do
    post '/users/test1/login', params = { "password" => "password"}
    last_response.should be_ok
    JSON(last_response.body)["session"].should match /^[0-9a-f]+$/
  end


  it "treats the username as case insensitive" do
    post '/users/TEST1/login', params = { "password" => "password"}
    last_response.should be_ok
    last_response.status.should eq(200)
  end


  it "rejects an invalid session" do
    get '/', params = {}, {"HTTP_X_ARCHIVESSPACE_SESSION" => "rubbish"}

    last_response.status.should eq(412)
    JSON(last_response.body)["code"].should eq ('SESSION_GONE')
  end


  it "yields a list of the user's permissions" do
    repo = create(:repo)

    group = JSONModel(:group).from_hash("group_code" => "newgroup",
                                        "description" => "A test group")
    group.grants_permissions = ["manage_repository"]
    group.member_usernames = ["test1"]
    id = group.save

    # as a part of the login process...
    post '/users/test1/login', params = { "password" => "password"}
    last_response.should be_ok
    auth_response = JSON(last_response.body)
    auth_response["user"]["permissions"][repo.repo_code].should eq(["manage_repository"])

    # But also with the user
    user = JSONModel(:user).find_by_uri(auth_response["user"]["uri"])
    user.permissions[repo.repo_code].should eq(["manage_repository"])
  end


  it "allows admin users to create a user with a set of groups" do

    group_a = create(:json_group)
    group_b = create(:json_group)

    user = build(:json_user)
    user.save(:password => '123', "groups[]" => [group_a.uri, group_b.uri])

    JSONModel(:group).find(group_a.id).member_usernames.should include(user.username)
    JSONModel(:group).find(group_b.id).member_usernames.should include(user.username)

  end
  
  
  it "does not allow anonymous users to place themselves in groups" do
    
    group_a = create(:json_group)
    
    expect {
      as_anonymous_user do
        build(:json_user).save(:password => '123', "groups[]" => [group_a.uri])
      end
    }.to raise_error(AccessDeniedException)
  end


  it "throws an exception when a user is created with an invalid group" do

    expect {
      build(:json_user).save(:password => '123', "groups[]" => ["/repositories/0/groups/999999999"])
    }.to raise_error(JSONModel::ValidationException)

  end

end
