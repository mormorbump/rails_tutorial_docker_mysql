require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  def setup
    # deliveriesは配列なので、setupで初期化しておかないと他のテストで実行されたメールが残る。
    ActionMailer::Base.deliveries.clear
  end

  test "invalid signup information" do
    get signup_path
    # postでブロック内部のパラムスを送っても、User.countに変化がない事を確認。
    assert_no_difference 'User.count' do
      post signup_path, params: { user: {
        name: "",
        email: "user@invalid",
        password: "foo",
        password_confirmation: "bar"
      }}
    end
    assert_template "users/new"
    assert_select 'div#error_explanation'
    assert_select 'div.alert'
    assert_select 'form[action="/signup"]'
  end

  test "valid signup information with account activation" do
    get signup_path
    # postでparams送って、User.countが一つ変わる事を確認。
    assert_difference "User.count", 1 do
      post signup_path, params: { user: {
        name: "Example User",
        email: "user@example.com",
        password: "password",
        password_confirmation: "password"
      }}
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    puts ActionMailer::Base.deliveries.size
    user = assigns(:user) # 引数のインスタンスにアクセスするメソッド
    assert_not user.activated?
    # 有効化していないアカウントでログイン
    log_in_as(user)
    assert_not is_logged_in?
    # 有効化トークンが不正な場合
    get edit_account_activation_path("invalid token", email: user.email) # 引数にid: "invalid token"ということ
    assert_not is_logged_in?
    # トークンは正しいがメールアドレスが無効な場合
    get edit_account_activation_path(user.activation_token, email: "wrong")
    assert_not is_logged_in?
    # 有効化トークンが正しい場合
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template "users/show"
    assert_not flash.nil?
    assert is_logged_in?
  end
end
