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
    attr_accessor :remember_token, :activation_token, :reset_token # remember_digestに保存するための仮置きの属性。# ここで属性を定義するのは、cookieにトークンを保存するため。
    before_save :downcase_email
    before_create :create_activation_digest # これ、newしたタイミングで生成されてない。
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

    # ============================callbackの調査=============================
    # before_validation -> {puts "before_validationが呼ばれました"}
    # after_validation -> {puts "after_validationが呼ばれました"}
    # before_save -> {puts "before_saveが呼ばれました"}
    # before_update -> {puts "before_updateが呼ばれました"}
    # before_create -> {puts "before_createが呼ばれました"}
    # after_create -> {puts "after_createが呼ばれました"}
    # after_update -> {puts "after_updateが呼ばれました"}
    # after_save -> {puts "after_saveが呼ばれました"}
    # after_commit -> {puts "after_commitが呼ばれました"}
    # ======================================================================

    class << self
      # ===========callbackの調査=============
      # def chk_calback
      #   user = User.new
      #   puts 'new完了'
      #   user.save
      # end
      # =====================================
      
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
  # ログインのための記憶トークン、認証のためのactivationトークン両方に対応するためsendメソッドを用意。
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest") # これがミソ。メタプロ。userインスタンスのカラム名を指定。(remember_digest or activation_digest)クラス内部のコードなのでselfも省略。
    # (すでにハッシュ化してある)remember_digestと、ハッシュ化したtokenが等しいか判定。
    return false if digest.nil? # test "authenticated? should return false for a user with nil digest"より
    BCrypt::Password.new(digest).is_password?(token) # self.remember_digestの省略
  end

  # ログイン情報の破棄
  def forget_digest
    update_attribute(:remember_digest, nil)
  end

  # アカウントの有効化
  def activate
    # 特定の行の特定のカラムを更新する。
    # 直接SQLが発行されバリデーションやコールバックは走らない。
    # 更新日時だけを更新したい場合や、コールバックを走らせたくない場合に便利。
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now # selfでuserを表す。
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def create_reset_digest
    # パスワード再設定の属性を設定。別クラス(PasswordResetsコントローラ)から読んでるのでprivateではない。
    self.reset_token = User.new_token
    update_columns(reset_digest:  User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  def password_reset_expired?
    # パスワード再設定の期限が切れている時true
    # この場合の<は少ない、というより「パスワード再設定メールの送信時刻が、現在時刻より2時間以上前 (早い) の場合」
    reset_sent_at < 2.hours.ago # 今の時刻の二時間前よりreset_sent_atが早い => 二時間以上経ってる
  end

  private

    def downcase_email
      self.email.downcase!
    end

    def create_activation_digest
      # 有効化トークンとダイジェストを作成および代入する。新規作成時なので代入。actionコールバックでクラスから直接読んでるのでprivate
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token) # User.newでトークンが生成されるため、updateでなく代入
    end


end



# 読者のJack Fahnestockから、現在の設計だと複数端末のログインに対応できないというフィードバックをもらいました。

# ブラウザＡを起動し、“remember me”をチェックしてログインする (ハッシュ化された記憶トークンをremember_digestに保存する)
# ブラウザＢを起動し、“remember me”をチェックしてログインする (ハッシュ化された記憶トークンをremember_digestに保存し、ブラウザＡが持つ記憶トークンを無効化する)
# ブラウザＡを閉じる (current_userメソッドが永続クッキーを使ってログインするようになる)
# ブラウザＡを起動する (ブラウザ内に永続クッキーはあるが、logged_in?がfalseを返してしまう)
# 確かに現在の設計ではユーザーが複数の端末からログインすることを想定していないため、ユーザーは２つ以上のブラウザでRemember me機能を使うことができません。現在の設計よりやや複雑になりますが、この問題に対する解決策は記憶ダイジェストを１つのテーブルとして新たに作成し、そのテーブルをユーザーのIDと紐づけることが考えられます。例えば現在のユーザーを見つけるときは、そのテーブルを通して記憶ダイジェストと対応する記憶トークンをチェックするようにします。また、リスト 9.11にあるforgetメソッドも同様に変更し、現在使っているブラウザに対応している記憶ダイジェストのみを削除させる必要があるでしょう。
# なお、セキュリティのことを考慮して、ユーザーがログアウトをした場合はそのユーザーに紐付いているすべてのダイジェストを削除しておくと良さそうです。