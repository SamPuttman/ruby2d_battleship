require 'ruby2d'
require './lib/game'

GRID_SIZE = 10
CELL_SIZE = 40
OFFSET_X = 50
OFFSET_Y = 50
SPACING_Y = 100
WINDOW_WIDTH = OFFSET_X * 2 + CELL_SIZE * GRID_SIZE
WINDOW_HEIGHT = OFFSET_Y * 5 + CELL_SIZE * GRID_SIZE * 2 + SPACING_Y

set title: "Battleship", width: WINDOW_WIDTH, height: WINDOW_HEIGHT

class BattleshipGame
  SHIP_QUEUE_TEXT_OFFSET_Y = OFFSET_Y + GRID_SIZE * CELL_SIZE + 10

  def initialize
    @game = Game.new
    @player_ships_placed = false
    @current_ship_index = 0
    @orientation = :horizontal
    @game_started = false
    @game_over = false
    @winner = nil
    @ship_queue_text = nil
    @dragging = false
    @drag_start = nil
    @drag_end = nil
    @error_text = nil

    draw_start_screen
  end

  def draw_start_screen
    clear_screen
    Text.new("Welcome to Battleship", x: WINDOW_WIDTH / 4, y: WINDOW_HEIGHT / 3, size: 30, color: 'white')
    Text.new("Press 'P' to Play", x: WINDOW_WIDTH / 3, y: WINDOW_HEIGHT / 2, size: 25, color: 'white')
  end

  def draw_win_loss_screen
    clear_screen
    if @winner == "Player"
      Text.new("Congratulations, You Won!", x: WINDOW_WIDTH / 4, y: WINDOW_HEIGHT / 3, size: 30, color: 'white')
    else
      Text.new("Game Over, You Lost!", x: WINDOW_WIDTH / 4, y: WINDOW_HEIGHT / 3, size: 30, color: 'white')
    end
    Text.new("Press 'R' to Restart", x: WINDOW_WIDTH / 3, y: WINDOW_HEIGHT / 2, size: 25, color: 'white')
  end

  def start_game
    @game_started = true
    draw_grid
    draw_ship_queue
    update
  end

  def restart_game
    initialize
  end

  def place_player_ship(coordinates)
    ship = @game.player_ships[@current_ship_index]

    if @game.player_board.valid_placement?(ship, coordinates)
      @game.player_board.place_ship(ship, coordinates)
      @current_ship_index += 1
      if @current_ship_index >= @game.player_ships.size
        @player_ships_placed = true
        @game.place_computer_ships
      else
        update_ship_queue
      end
      @error_text.remove if @error_text
      update
    else
      show_error("Invalid placement. Please try again.")
    end
  end

  def draw_grid
    # Player grid
    (0..GRID_SIZE).each do |i|
      Line.new(
        x1: OFFSET_X, y1: OFFSET_Y + i * CELL_SIZE,
        x2: OFFSET_X + GRID_SIZE * CELL_SIZE, y2: OFFSET_Y + i * CELL_SIZE,
        width: 2, color: 'black'
      )
      Line.new(
        x1: OFFSET_X + i * CELL_SIZE, y1: OFFSET_Y,
        x2: OFFSET_X + i * CELL_SIZE, y2: OFFSET_Y + GRID_SIZE * CELL_SIZE,
        width: 2, color: 'black'
      )
    end

    # Computer grid
    (0..GRID_SIZE).each do |i|
      Line.new(
        x1: OFFSET_X, y1: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y + i * CELL_SIZE,
        x2: OFFSET_X + GRID_SIZE * CELL_SIZE, y2: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y + i * CELL_SIZE,
        width: 2, color: 'black'
      )
      Line.new(
        x1: OFFSET_X + i * CELL_SIZE, y1: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y,
        x2: OFFSET_X + i * CELL_SIZE, y2: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + GRID_SIZE * CELL_SIZE + SPACING_Y,
        width: 2, color: 'black'
      )
    end

    draw_labels
  end

  def draw_labels
    ('A'..'J').each_with_index do |letter, i|
      Text.new(letter, x: OFFSET_X - 20, y: OFFSET_Y + i * CELL_SIZE + 15, size: 15, color: 'white')
      Text.new(letter, x: OFFSET_X - 20, y: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y + i * CELL_SIZE + 15, size: 15, color: 'white')
    end

    (1..10).each do |number|
      Text.new(number.to_s, x: OFFSET_X + (number - 1) * CELL_SIZE + 15, y: OFFSET_Y - 30, size: 15, color: 'white')
      Text.new(number.to_s, x: OFFSET_X + (number - 1) * CELL_SIZE + 15, y: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y - 30, size: 15, color: 'white')
    end

    Text.new("Player's Board", x: OFFSET_X, y: OFFSET_Y - 50, size: 20, color: 'white')
    Text.new("Computer's Board", x: OFFSET_X, y: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y - 50, size: 20, color: 'white')
  end

  def draw_ship_queue
    @ship_queue_text = Text.new("", x: OFFSET_X, y: SHIP_QUEUE_TEXT_OFFSET_Y, size: 20, color: 'white')
    update_ship_queue
  end

  def update_ship_queue
    if @current_ship_index < @game.player_ships.size
      ship = @game.player_ships[@current_ship_index]
      @ship_queue_text.text = "Place your #{ship.name} (#{ship.length} spaces)"
    else
      @ship_queue_text.text = ""
    end
  end

  def update
    return unless @game_started

    clear_board
    draw_board(@game.player_board, OFFSET_X, OFFSET_Y, true)
    draw_board(@game.computer_board, OFFSET_X, OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y, false)
  end

  def draw_board(board, offset_x, offset_y, fog_of_war)
    board.cells.each do |coordinate, cell|
      row = coordinate[0].ord - 'A'.ord
      col = coordinate[1..-1].to_i - 1
      x = offset_x + col * CELL_SIZE
      y = offset_y + row * CELL_SIZE

      color = case cell.render(fog_of_war)
              when 'M' then 'white'
              when 'H' then 'red'
              when 'X' then 'black'
              when 'S' then 'gray'
              else 'blue'
              end

      Rectangle.new(
        x: x, y: y,
        width: CELL_SIZE, height: CELL_SIZE,
        color: color
      )
    end

    # grid lines
    (0..GRID_SIZE).each do |i|
      Line.new(
        x1: offset_x, y1: offset_y + i * CELL_SIZE,
        x2: offset_x + GRID_SIZE * CELL_SIZE, y2: offset_y + i * CELL_SIZE,
        width: 1, color: 'black', z: 1
      )
      Line.new(
        x1: offset_x + i * CELL_SIZE, y1: offset_y,
        x2: offset_x + i * CELL_SIZE, y2: offset_y + GRID_SIZE * CELL_SIZE,
        width: 1, color: 'black', z: 1
      )
    end
  end

  def clear_board
    Window.clear
    draw_grid
    draw_ship_queue unless @player_ships_placed
    @error_text.remove if @error_text
  end

  def clear_screen
    Window.clear
  end

  def player_turn(coordinate)
    if !@game.computer_board.valid_coordinate?(coordinate)
      show_error("Not a valid coordinate. Please try again.")
    elsif @game.computer_board.cells[coordinate].fired_upon?
      show_error("This coordinate has already been fired upon. Please try again.")
    else
      @game.player_turn(coordinate)
      update
      check_game_over
      unless @game_over
        @game.computer_turn
        update
        check_game_over
      end
    end
  end

  def check_game_over
    if @game.game_over?
      @winner = @game.winner
      @game_over = true
      clear_screen
      draw_win_loss_screen
    end
  end

  def draw_ship_preview(start_coord, end_coord)
    return unless @game_started && !@player_ships_placed

    ship = @game.player_ships[@current_ship_index]
    start_row = start_coord[0]
    start_col = start_coord[1..-1].to_i
    end_row = end_coord[0]
    end_col = end_coord[1..-1].to_i

    coordinates = if start_row == end_row
      (start_col..end_col).map { |col| "#{start_row}#{col}" }
    else
      (start_row.ord..end_row.ord).map { |row| "#{row.chr}#{start_col}" }
    end

    coordinates.each do |coordinate|
      if @game.player_board.valid_coordinate?(coordinate) && @game.player_board.cells[coordinate].empty?
        cell_x = OFFSET_X + ((coordinate[1..-1].to_i - 1) * CELL_SIZE)
        cell_y = OFFSET_Y + ((coordinate[0].ord - 'A'.ord) * CELL_SIZE)

        Rectangle.new(
          x: cell_x, y: cell_y,
          width: CELL_SIZE, height: CELL_SIZE,
          color: 'green',
          z: 2
        )
      else
        cell_x = OFFSET_X + ((coordinate[1..-1].to_i - 1) * CELL_SIZE)
        cell_y = OFFSET_Y + ((coordinate[0].ord - 'A'.ord) * CELL_SIZE)

        Rectangle.new(
          x: cell_x, y: cell_y,
          width: CELL_SIZE, height: CELL_SIZE,
          color: 'red',
          z: 2
        )
      end
    end
  end

  # def highlight_grid_cells(coordinate)
  #   row = coordinate[0].ord - 'A'.ord
  #   col = coordinate[1..-1].to_i - 1
  #   x = OFFSET_X + col * CELL_SIZE
  #   y = OFFSET_Y + row * CELL_SIZE

  #   Rectangle.new(
  #     x: x, y: y,
  #     width: CELL_SIZE, height: CELL_SIZE,
  #     color: [0.5, 0.5, 0.5, 0.3],
  #     z: 3
  #   )
  # end

  def show_error(message)
    @error_text.remove if @error_text
    @error_text = Text.new(message, x: OFFSET_X, y: OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y - 25, size: 20, color: 'red')
  end
end

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
    @last_hits.clear
    @current_target_ship = nil
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
      @last_hits.each { |hit| @previous_shots << hit }
      reset_direction
    end
  end
end

battleship_game = BattleshipGame.new

on :key_down do |event|
  if event.key == 'p' && !battleship_game.instance_variable_get(:@game_started)
    battleship_game.start_game
  elsif event.key == 'r' && battleship_game.instance_variable_get(:@game_over)
    battleship_game.restart_game
  elsif event.key == 'r'
    battleship_game.instance_variable_set(:@orientation, battleship_game.instance_variable_get(:@orientation) == :horizontal ? :vertical : :horizontal)
  end
end

on :mouse_down do |event|
  if event.button == :left
    if !battleship_game.instance_variable_get(:@player_ships_placed)
      if event.x.between?(OFFSET_X, OFFSET_X + GRID_SIZE * CELL_SIZE) && event.y.between?(OFFSET_Y, OFFSET_Y + GRID_SIZE * CELL_SIZE)
        row = ((event.y - OFFSET_Y) / CELL_SIZE).to_i
        col = ((event.x - OFFSET_X) / CELL_SIZE).to_i
        battleship_game.instance_variable_set(:@dragging, true)
        battleship_game.instance_variable_set(:@drag_start, "#{('A'.ord + row).chr}#{col + 1}")
      end
    else
      if event.x.between?(OFFSET_X, OFFSET_X + GRID_SIZE * CELL_SIZE) && event.y.between?(OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y, OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + GRID_SIZE * CELL_SIZE + SPACING_Y)
        row = ((event.y - (OFFSET_Y * 2 + GRID_SIZE * CELL_SIZE + SPACING_Y)) / CELL_SIZE).to_i
        col = ((event.x - OFFSET_X) / CELL_SIZE).to_i
        coordinate = "#{('A'.ord + row).chr}#{col + 1}"
        battleship_game.player_turn(coordinate)
      end
    end
  end
end

on :mouse_up do |event|
  if event.button == :left && battleship_game.instance_variable_get(:@dragging)
    battleship_game.instance_variable_set(:@dragging, false)
    if event.x.between?(OFFSET_X, OFFSET_X + GRID_SIZE * CELL_SIZE) && event.y.between?(OFFSET_Y, OFFSET_Y + GRID_SIZE * CELL_SIZE)
      row = ((event.y - OFFSET_Y) / CELL_SIZE).to_i
      col = ((event.x - OFFSET_X) / CELL_SIZE).to_i
      drag_start = battleship_game.instance_variable_get(:@drag_start)
      drag_end = "#{('A'.ord + row).chr}#{col + 1}"
      if drag_start && drag_end
        start_row, start_col = drag_start[0], drag_start[1..-1].to_i
        end_row, end_col = drag_end[0], drag_end[1..-1].to_i
        if start_row == end_row
          coordinates = (start_col..end_col).map { |col| "#{start_row}#{col}" }
        else
          coordinates = (start_row.ord..end_row.ord).map { |row| "#{row.chr}#{start_col}" }
        end
        battleship_game.place_player_ship(coordinates)
      end
    end
  end
end

on :mouse_move do |event|
  if battleship_game.instance_variable_get(:@dragging)
    drag_start = battleship_game.instance_variable_get(:@drag_start)
    if event.x.between?(OFFSET_X, OFFSET_X + GRID_SIZE * CELL_SIZE) && event.y.between?(OFFSET_Y, OFFSET_Y + GRID_SIZE * CELL_SIZE)
      row = ((event.y - OFFSET_Y) / CELL_SIZE).to_i
      col = ((event.x - OFFSET_X) / CELL_SIZE).to_i
      drag_end = "#{('A'.ord + row).chr}#{col + 1}"
      battleship_game.clear_board
      battleship_game.draw_ship_preview(drag_start, drag_end)
      # battleship_game.highlight_grid_cells(drag_end)
    end
  end
end

update do
  battleship_game.update
  battleship_game.check_game_over if battleship_game.instance_variable_get(:@game_over)
end

show
