require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:michael)
    @non_admin = users(:archer)
  end

  # 管理者、一般ユーザー、pagination, 削除リンクなど諸々まとめたテスト
  test "index as admin including pagination and delete links" do
    # 管理者権限でログインの確認。
    log_in_as(@admin)
    # 描画の確認
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination', count: 2 # will_paginateタグは二つあり
    # 最初のページのユーザーが存在するか確認。
    # (管理者でログインしているので)管理者以外のuserに削除ボタンがあることも確認。
    first_page_of_users = User.paginate(page: 1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      unless user == @admin
        assert_select 'a[href=?]', user_path(user), text: 'delete'
      end
    end
    # 削除ボタンを押した時、User.countが−1することの確認
    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
  end

  # 管理者でないときは削除ボタンが存在しないときの確認。
  test 'index as non-admin' do
    log_in_as(@non_admin)
    get users_path
    assert_select 'a', text: 'delete', count: 0 
  end
end

