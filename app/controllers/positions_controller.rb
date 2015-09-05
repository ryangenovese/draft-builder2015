class PositionsController < LeaguesViewController

  def index
    if params[:position] && !NflPlayer.position_valid?(params[:position])
      redirect_to league_all_positions_path(params[:league_id])
    end

    if params[:position]
      @position = params[:position].upcase
      @players = NflPlayer.where(position: @position)
                  .includes(:nfl_team)
                  .includes(:leagues)
                  .order(:adp_ffc)
    else
      @position = 'All'
      @players = NflPlayer.all
                  .includes(:nfl_team)
                  .includes(:leagues)
                  .order(:adp_ffc)
    end

    if params[:rank] && params[:rank] == 'points'
      @points = true
      @players = @players.reorder(projected_points: :desc)
    elsif params[:rank] && params[:rank] == 'adp_espn'
      @adp_espn = true
      @players = @players.reorder(:adp_espn)
    else
      @adp_ffc = true
    end
  end

end
