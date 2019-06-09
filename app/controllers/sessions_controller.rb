class SessionsController < ApplicationController
  def new
  end
  
  def create
    # ログイン時に送られてきたparamsの情報を使いUserから検索。
    user = User.find_by(email: params[:session][:email].downcase)
    # ユーザーが有効 かつ ユーザーのパスワードが一致してるか
    if user && user.authenticate(params[:session][:password])
      log_in user # ここで保存されたcookieの値は検証のApplication => Storage => Cookiesでみれる。
      redirect_to user
    else
      flash.now[:danger] = 'Invalid email/password combination' # 本当は正しくない
      render "new"
    end
  end
  
  def destroy
    log_out
    redirect_to root_url
  end
  
end
