module Admin
  class LeaguesController < Admin::BaseController
    def index
      @pagy, @leagues = pagy(League.includes(:sport).order(:country, :name), limit: 30)
    end

    def new
      @league = League.new
    end

    def create
      @league = League.new(league_params)
      if @league.save
        flash[:notice] = "Liga erstellt."
        redirect_to admin_leagues_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @league = League.find(params[:id])
    end

    def update
      @league = League.find(params[:id])
      if @league.update(league_params)
        flash[:notice] = "Liga aktualisiert."
        redirect_to admin_leagues_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @league = League.find(params[:id])
      @league.destroy
      flash[:notice] = "Liga gelöscht."
      redirect_to admin_leagues_path
    end

    private

    def league_params
      params.require(:league).permit(:name, :country, :external_id, :active, :sport_id, :logo_url)
    end
  end
end
