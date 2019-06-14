class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update]
  before_action :correct_user, only: [:edit, :update]

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def index
    @users = User.paginate(page: params[:page]) # paginateはkeyがpageでparamsがページ番号のハッシュを取る
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

  def edit
  end

  def update
      if @user.update_attributes(user_params)
        flash[:success] = "Profile updated"
        redirect_to @user
      else
        render 'edit'
      end
  end
  

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def logged_in_user
      unless logged_in?
        store_location # getリクエストをcookieへ保存
        flash[:danger] = "Please log in"
        redirect_to login_url
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

end
