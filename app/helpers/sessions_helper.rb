module SessionsHelper
    def log_in(user)
        # Railsに元から用意してあるcookieにハッシュ形式で保存するためのメソッド。
        # cookieメソッドと違って、有効期限はブラウザを閉じるまで。
        # これで作成した一時cookieは暗号化されるし、これが盗まれてもログインは成功しない。
        session[:user_id] = user.id
    end

    # 現在ログイン中のユーザーを返す。いない場合はnilが返る。
    def current_user
        # 結構奥の深いメソッド。
        # 例外を発生させてはいけないのと、
        # 一度呼び出したuserは再利用したいのでインスタンス変数を利用することに注意。
        # Userの論理値は常にtrueなので、@current_userに何も入っていない時だけfind_byが呼び出される。
        # これにより無駄なデータベースの呼び出しがなくなる。
        if session[:user_id]
            @current_user ||= User.find_by(id: session[:user_id])
        end
    end

    def logged_in?
        !current_user.nil? # 上のメソッド呼び出し。nilが返ってないということはユーザーが存在=> true
    end

    def log_out
        session.delete(:user_id)
        @current_user = nil
    end
end
