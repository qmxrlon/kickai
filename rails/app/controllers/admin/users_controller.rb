module Admin
  class UsersController < Admin::BaseController
    def index
      @q     = User.ransack(params[:q])
      @pagy, @users = pagy(@q.result.order(created_at: :desc), limit: 30)
    end

    def show
      @user = User.find(params[:id])
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        flash[:notice] = "Benutzer aktualisiert."
        redirect_to admin_user_path(@user)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      flash[:notice] = "Benutzer gelöscht."
      redirect_to admin_users_path
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :role)
    end
  end
end
