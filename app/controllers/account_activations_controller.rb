class AccountActivationsController < ApplicationController
    def edit
        user = User.find_by(email: params[:email])
        # userが存在する かつ userが無効状態 かつ ハッシュ化したactivation_tokenがactivation_digestと一致するか
        if user && !user.activated && user.authenticated?(:activation, params[:id])
            user.activate
            log_in user
            flash[:success] = "Account activated!"
            redirect_to user
        else
            flash[:danger] = "Invalid activation link"
            redirect_to root_url
        end
    end
end
