class UsersController < ApplicationController

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    # paramsにはhtmlのinputタグのname属性をkeyとした値が入ってる
    @user = User.new(user_params)    # 実装は終わっていないことに注意!
    if @user.save
      log_in @user # ユーザーを新規作成しただけではログインしていないので、成功したタイミングでsessionを作成。
      flash[:success] = "Welcome to the Sample App!"
      redirect_to @user
    else
      render 'new'
    end
  end

  private 
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

end
