class PasswordResetsController < ApplicationController
  before_action :get_user, only: [:edit, :update]
  berore_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update] # 1

  #■password変更の時に注意すべきこと
  #１。パスワード再設定の有効期限が切れていないか
  #２。無効なパスワードであれば失敗させる (失敗した理由も表示する)
  #３。新しいパスワードが空文字列になっていないか (ユーザー情報の編集ではOKだった)
  #４。新しいパスワードが正しければ、更新する

  def new
    # 再設定用URLが届くemail送信フォーム
  end

  def create
    # 再設定時の認証のためのtoken, digestの生成と、再設定用ページまでのURLが入ったメールの送信。
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash.now[:danger] = "Email address not found"
      render 'new'
    end
  end

  def edit
    # password入力ページ。
  end

  def update
    if params[:user][:password].empty? # 3
      @user.errors.add(:password, :blank)
    elsif
      @user.update_attributes(user_params) # 4
      log_in @user
      @user.update_attribute(:reset_digest, nil) # 2時間以内にもう一度このURLにログインした時、再変更を防ぐ。
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      render 'edit' # 2
    end
  end

  private

    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    def get_user
      @user = User.find_by(email: params[:email])
    end

    def valid_user
      unless (@user && @user.activated && @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end

    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = "Password reset has expired."
        redirect_to new_password_reset_url
      end
    end
end
