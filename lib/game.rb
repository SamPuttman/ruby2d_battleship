require './lib/board'
require './lib/ship'
require './lib/artificial_player'

class Game
  attr_reader :player_board, :computer_board, :player_ships, :computer_ships, :computer_player

  def initialize
    @player_board = Board.new
    @computer_board = Board.new
    @computer_player = ArtificialPlayer.new(@player_board)
    @player_ships = [
      Ship.new("Carrier", 5),
      Ship.new("Battleship", 4),
      Ship.new("Cruiser", 3),
      Ship.new("Submarine", 3),
      Ship.new("Destroyer", 2)
    ]
    @computer_ships = [
      Ship.new("Carrier", 5),
      Ship.new("Battleship", 4),
      Ship.new("Cruiser", 3),
      Ship.new("Submarine", 3),
      Ship.new("Destroyer", 2)
    ]
  end

  def place_computer_ships
    @computer_ships.each do |ship|
      coordinates = []
      until @computer_board.valid_placement?(ship, coordinates)
        row = ('A'..'J').to_a.sample
        col = (1..10).to_a.sample
        orientation = [:horizontal, :vertical].sample

        if orientation == :horizontal
          coordinates = (col...(col + ship.length)).map { |c| "#{row}#{c}" }
        else
          coordinates = (row.ord...(row.ord + ship.length)).map { |r| "#{r.chr}#{col}" }
        end
      end
      @computer_board.place_ship(ship, coordinates)
    end
  end

  def player_turn(coordinate)
    @computer_board.cells[coordinate].fire_upon
  end

  def computer_turn
    loop do
      coordinate = @computer_player.select_coordinate
      target_cell = @player_board.cells[coordinate]
      hit = !target_cell.empty?
      target_cell.fire_upon
      @computer_player.record_shot(coordinate, hit)
      break
    end
  end

  def game_over?
    @player_ships.all?(&:sunk?) || @computer_ships.all?(&:sunk?)
  end

  def winner
    if @player_ships.all?(&:sunk?)
      "Computer"
    elsif @computer_ships.all?(&:sunk?)
      "Player"
    else
      nil
    end
  end
end
