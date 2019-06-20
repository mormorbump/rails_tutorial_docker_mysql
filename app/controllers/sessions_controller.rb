class SessionsController < ApplicationController
  def new
  end
  
  def create
    # ログイン時に送られてきたparamsの情報を使いUserから検索。
    @user = User.find_by(email: params[:session][:email].downcase)
    # ユーザーが有効 かつ ユーザーのパスワードが一致してるか
    if @user && @user.authenticate(params[:session][:password])
      # rubyは、bool型に?をつけるとfalseを推測してそれ以外をtrueを返すので、こちらが推奨。
      # https://lukesilvia.hatenablog.com/entry/20080316/1205644760
      if @user.activated?
        log_in @user # ここで保存されたcookieの値は検証のApplication => Storage => Cookiesでみれる。
        # チェックボックスの値によってログイン永続化するか、cookieに保存してあるtoken, user_idを消すか三項演算子で分岐。
        # ログイン永続化のため、tokenを生成、ハッシュ化してdigestカラムに保存するヘルパーメソッド(modelのクラスメソッドとはちゃう)
        params[:session][:remember_me] ==  "1" ? remember(@user) : forget(@user)
        redirect_back_or @user # sessionで保存されているurlか、引数のとこへリダイレクト(その後、行き先のクッキーは消える。)
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'Invalid email/password combination' # 本当は正しくない
      render "new"
    end
  end
  
  def destroy
    log_out if logged_in? # ログアウトするときはログインしてる時だけ
    redirect_to root_url
  end
  
end
