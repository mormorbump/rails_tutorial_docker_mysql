module SessionsHelper
    def log_in(user)
        # Railsに元から用意してあるcookieにハッシュ形式で保存するためのメソッド。
        # cookieメソッドと違って、有効期限はブラウザを閉じるまで。
        # これで作成した一時cookieは暗号化されるし、これが盗まれてもログインは成功しない。
        session[:user_id] = user.id
    end

    def remember(user)
        user.save_remember # userモデルのクラスメソッドを呼び出し、トークンの生成、ハッシュ化、remember_digestへの保存。
        cookies.permanent.signed[:user_id] = user.id  # 期間最長で暗号化したユーザーidをクッキーに保存。
        cookies.permanent[:remember_token] = user.remember_token # モデルに定義してある仮置きの属性に保存してあるトークンも(平文のまま)クッキーに保存。
    end

    # 現在ログイン中のユーザーを返す。いない場合はnilが返る。
    def current_user
        # 結構奥の深いメソッド。
        # 例外を発生させてはいけないのと、
        # 一度呼び出したuserは再利用したいのでインスタンス変数を利用することに注意。
        # Userの論理値は常にtrueなので、@current_userに何も入っていない時だけfind_byが呼び出される。
        # これにより無駄なデータベースの呼び出しがなくなる。
        if (user_id = session[:user_id])
            @current_user ||= User.find_by(id: user_id)
        elsif (user_id = cookies.signed[:user_id]) # セッションがなくてもクッキーに保存してあった場合
            # raise # テストがパスしてしまう => この部分がテストされていない。
            user = User.find_by(id: user_id)
            # 同じようにuserが存在してかつユーザーのトークンが一致するかどうか確認。
            # # (すでにハッシュ化してある)remember_digestと、ハッシュ化したtokenが等しいか判定しとる。
            if user && user.authenticated?(cookies[:remember_token])
                log_in user
                @current_user = user
            end
        end
    end

    def current_user?(user)
        user == current_user
    end

    def logged_in?
        !current_user.nil? # 上のメソッド呼び出し。nilが返ってないということはユーザーが存在=> true
    end

    def forget(user)
        user.forget_digest
        cookies.delete(:user_id)
        cookies.delete(:remember_token)
    end


    def log_out
        forget(current_user)
        session.delete(:user_id)
        @current_user = nil
    end

    # 記憶したURL(もしくはデフォルト値)にリダイレクト
    def redirect_back_or(default)
        redirect_to(session[:forwarding_url] || default)
        session.delete(:forwarding_url)
    end

    # アクセスしようとしたurlの保存(getリクエストの時だけ)
    def store_location
        session[:forwarding_url] = request.original_url if request.get?
    end
end
