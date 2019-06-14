# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ApplicationRecord
    attr_accessor :remember_token # remember_digestに保存するための仮置きの属性。# ここで属性を定義するのは、cookieにトークンを保存するため。
    before_save { email.downcase! }
    validates :name, presence: true, length: {maximum: 50}
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: {case_sensitive: false} # uniquenessはこれでtrue。大文字、小文字の区別がfalseということ。
    has_secure_password # ハッシュ化して、password_digest属性(自分で作る)に保存可能。confirmationも実装できる。validationも実装。passと一致するか確認できるauthenticateも使える。
    validates :password, presence: true, length: {minimum: 6}, allow_nil: true

    # 渡された文字列のハッシュ値を返す。
    # https://github.com/rails/rails/blob/master/activemodel/lib/active_model/secure_password.rb
    # secure_passwordメソッドのソースコードを参考に記述。
    # 「オブジェクトに依存しない」メソッドをクラスメソッドにする
    class << self
      def digest(string)
        # cost開発環境と本番環境で
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
      end

      # 記憶トークン用のランダムな文字列を作成するメソッド。
      # これ(とそれにひもづくuser_id)をさらに暗号化してcookieとdatabaseに保存し、アクセス時に照合する。
      def new_token
        SecureRandom.urlsafe_base64
      end
    end

  # 生成されたトークンをuserのremember_digestにハッシュ化して保存するメソッド
  def save_remember
    # remember_digestに保存するための仮置きの属性、remember_tokenにユーザーのトークンを保存
    # トークンを平文のまま保存できないため
    # ここで属性を定義するのは、cookieにトークンを保存するため。
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token)) # # self.remember_tokenの省略
  end

  # 渡されたtokenがdigestと一致したらtrueを返す。
  # has_secure_passwordで得られるヘルパーメソッドのauthenticateとはちゃうよ
  def authenticated?(token)
    # (すでにハッシュ化してある)remember_digestと、ハッシュ化したtokenが等しいか判定。
    return false if remember_digest.nil? # test "authenticated? should return false for a user with nil digest"より
    BCrypt::Password.new(remember_digest).is_password?(token) # self.remember_digestの省略
  end

  # ログイン情報の破棄
  def forget_digest
    update_attribute(:remember_digest, nil)
  end
end



# 読者のJack Fahnestockから、現在の設計だと複数端末のログインに対応できないというフィードバックをもらいました。

# ブラウザＡを起動し、“remember me”をチェックしてログインする (ハッシュ化された記憶トークンをremember_digestに保存する)
# ブラウザＢを起動し、“remember me”をチェックしてログインする (ハッシュ化された記憶トークンをremember_digestに保存し、ブラウザＡが持つ記憶トークンを無効化する)
# ブラウザＡを閉じる (current_userメソッドが永続クッキーを使ってログインするようになる)
# ブラウザＡを起動する (ブラウザ内に永続クッキーはあるが、logged_in?がfalseを返してしまう)
# 確かに現在の設計ではユーザーが複数の端末からログインすることを想定していないため、ユーザーは２つ以上のブラウザでRemember me機能を使うことができません。現在の設計よりやや複雑になりますが、この問題に対する解決策は記憶ダイジェストを１つのテーブルとして新たに作成し、そのテーブルをユーザーのIDと紐づけることが考えられます。例えば現在のユーザーを見つけるときは、そのテーブルを通して記憶ダイジェストと対応する記憶トークンをチェックするようにします。また、リスト 9.11にあるforgetメソッドも同様に変更し、現在使っているブラウザに対応している記憶ダイジェストのみを削除させる必要があるでしょう。
# なお、セキュリティのことを考慮して、ユーザーがログアウトをした場合はそのユーザーに紐付いているすべてのダイジェストを削除しておくと良さそうです。