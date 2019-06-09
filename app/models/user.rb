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
    before_save { email.downcase! }
    validates :name, presence: true, length: {maximum: 50}
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: {case_sensitive: false} # uniquenessはこれでtrue。大文字、小文字の区別がfalseということ。
    has_secure_password # ハッシュ化して、password_digest属性(自分で作る)に保存可能。confirmationも実装できる。validationも実装。passと一致するか確認できるauthenticateも使える。
    validates :password, presence: true, length: {minimum: 6}

    # 渡された文字列のハッシュ値を返す。
    # https://github.com/rails/rails/blob/master/activemodel/lib/active_model/secure_password.rb
    # secure_passwordメソッドのソースコードを参考に記述。
    class << self
      def digest(string)
        # cost開発環境と本番環境で
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
      end
    end
end
