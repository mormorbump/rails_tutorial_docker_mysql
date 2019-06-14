require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @other_user = users(:archer)
  end
  # userのログイン判定のbefore_actionをコメントアウトしてもtestが通ってしまうのでそれ用のテストを用意
  # beforeフィルターは基本アクションごとの適用なので、Userコントローラのテストもアクションごとにする。
  # アクションごとにテストを書く必要があるのは、パスが違うため。
  test "should redirect edit when not logged in" do
    get edit_user_path(@user)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect update when not logged in" do
    patch user_path(@user), params: {user: {name: @user.name,
                                      email: @user.email }}
    assert_not flash.empty?
    assert_redirected_to login_url
  end
  
  test "should redirect edit when logged in as wrong user" do
    log_in_as(@other_user)
    get edit_user_path(@user)
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect update when logged in as wrong user" do
    log_in_as(@other_user)
    patch user_path(@user), params: {user: {name: @user.name,
                                    email: @user.email}}
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect index when not logged in" do
    get users_path
    assert_redirected_to login_url
  end

  test "should not allow the admin attribute to be edited via the web" do # via: 経由
    log_in_as(@other_user) # 管理者じゃないアカウント
    assert_not @other_user.admin?
    patch user_path(@other_user), params: { user: {
      password: "",
      password_confirmation: "",
      admin: true
    }}
    assert_not @other_user.reload.admin?
  end

  # logged_in_userのbefore_actionにdestroyを追加していないと、ログインしてないのにadmin_userが走り、例外となる。
  # http://etoh1220.hatenablog.com/entry/2016/01/02/220000
  test "should redirect destroy when not logged in" do
    assert_no_difference 'User.count' do # 違いがなかったらtrueなので通る。
      delete user_path(@user)
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when logged in as a non-admin" do
    log_in_as(@other_user) # 管理者じゃないアカウント
    assert_no_difference 'User.count' do # 違いがなかったらtrueなので通る。
      delete user_path(@user)
    end
    assert_redirected_to root_url
  end
end
