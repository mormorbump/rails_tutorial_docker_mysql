require 'test_helper'

class SessionsHelperTest < ActionView::TestCase

    def setup
        @user = users(:michael)
        remember @user # cookieにトークンと暗号化したuser_idを保存。
    end

    # session情報がきれていても、cookieにトークンがあればログインは継続されているか
    test "current_user returns right user when session is nil" do
        assert_equal @user, current_user # assert_equalの引数は「期待する値, 実際の値」の順序で書く
        assert is_logged_in?
    end

    test "current_user returns nil when rememberDigest is wrong" do
        @user.update_attribute(:remember_digest, User.digest(User.new_token))
        assert_nil current_user
    end
end