require './lib/cell'

class Board
  attr_reader :cells

  def initialize
    @cells = {}
    create_cells
  end

  def create_cells
    ('A'..'J').each do |row|
      (1..10).each do |col|
        coordinate = "#{row}#{col}"
        @cells[coordinate] = Cell.new(coordinate)
      end
    end
  end

  def valid_coordinate?(coordinate)
    @cells.key?(coordinate)
  end

  def valid_placement?(ship, coordinates)
    return false unless coordinates.length == ship.length
    return false unless coordinates.all? { |coord| valid_coordinate?(coord) && @cells[coord].empty? }

    rows = coordinates.map { |coord| coord[0] }
    cols = coordinates.map { |coord| coord[1..-1].to_i }

    rows.uniq.size == 1 && cols.each_cons(2).all? { |a, b| b == a + 1 } ||
      cols.uniq.size == 1 && rows.each_cons(2).all? { |a, b| b.ord == a.ord + 1 }
  end

  def place_ship(ship, coordinates)
    return unless valid_placement?(ship, coordinates)

    coordinates.each { |coord| @cells[coord].place_ship(ship) }
  end

  def render(fog_of_war = false)
    "  1 2 3 4 5 6 7 8 9 10\n" +
    ('A'..'J').map do |row|
      row + " " + (1..10).map do |col|
        @cells["#{row}#{col}"].render(fog_of_war)
      end.join(" ")
    end.join("\n")
  end
end
