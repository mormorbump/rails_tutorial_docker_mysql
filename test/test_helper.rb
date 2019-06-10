ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  include ApplicationHelper

  # Add more helper methods to be used by all tests here...
  # ヘルパーメソッドはテストから呼び出せないので、ここテスト用のも作成していく。

  def is_logged_in?
    !session[:user_id].nil?
  end

  # テストユーザーとしてログインするメソッド
  def log_in_as(user)
    session[:user_id] = user.id
  end

  # 統合テスト用のメソッドも定義。
  class ActionDispatch::IntegrationTest

    # ログインするメソッド。通常テスト、統合テスト両方でlog_in_asと同じ名前にすることで、どちらのテストか関係なく、ログインしたいときはこの名前を呼べば良い
    def log_in_as(user, password: "password", remember_me: "1")
      post login_path, params:{session: {email: user.email,
                    password: password,
                    remember_me: remember_me}}
    end
  end
end
