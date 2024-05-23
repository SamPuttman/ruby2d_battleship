class ArtificialPlayer
  attr_reader :player_board

  def initialize(board)
    @player_board = board
    @previous_shots = []
    @last_hits = []
    @current_target_ship = nil
    @directions = [:horizontal, :vertical]
    @direction = nil
  end

  def select_coordinate
    if @last_hits.any?
      target = determine_target
      return target if target
    end

    loop do
      row = ('A'..'J').to_a.sample
      column = (1..10).to_a.sample
      coordinate = "#{row}#{column}"
      unless @previous_shots.include?(coordinate)
        return coordinate
      end
    end
  end

  def record_shot(coordinate, hit)
    @previous_shots << coordinate
    if hit
      @last_hits << coordinate
      @current_target_ship = @player_board.cells[coordinate].ship unless @current_target_ship
      determine_direction if @last_hits.size > 1
    else
      reset_direction if @last_hits.empty?
    end
    check_sunk_ship
  end

  private

  def determine_target
    if @direction
      next_coordinate_in_direction
    else
      adjacent_coordinates(@last_hits.last).find { |coordinate| valid_shot?(coordinate) }
    end
  end

  def determine_direction
    return unless @last_hits.size >= 2
    first_hit = @last_hits[-2]
    second_hit = @last_hits[-1]
    if first_hit[0] == second_hit[0]
      @direction = :horizontal
    elsif first_hit[1] == second_hit[1]
      @direction = :vertical
    end
  end

  def next_coordinate_in_direction
    last_hit = @last_hits.last
    if @direction == :horizontal
      adjacent_coordinates(last_hit).select { |coordinate| coordinate[0] == last_hit[0] }.find { |coordinate| valid_shot?(coordinate) }
    elsif @direction == :vertical
      adjacent_coordinates(last_hit).select { |coordinate| coordinate[1] == last_hit[1] }.find { |coordinate| valid_shot?(coordinate) }
    end
  end

  def reset_direction
    @direction = nil
  end

  def adjacent_coordinates(coordinate)
    row = coordinate[0]
    column = coordinate[1..-1].to_i
    [
      "#{row}#{column - 1}",
      "#{row}#{column + 1}",
      "#{(row.ord - 1).chr}#{column}",
      "#{(row.ord + 1).chr}#{column}"
    ].select { |coord| valid_coordinate?(coord) }
  end

  def valid_coordinate?(coordinate)
    ('A'..'J').include?(coordinate[0]) && (1..10).include?(coordinate[1..-1].to_i)
  end

  def valid_shot?(coordinate)
    valid_coordinate?(coordinate) && !@previous_shots.include?(coordinate)
  end

  def check_sunk_ship
    if @current_target_ship&.sunk?
      @last_hits.clear
      @current_target_ship = nil
      reset_direction
    end
  end
end
