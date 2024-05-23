class Cell
  attr_reader :coordinate, :ship, :fired_upon

  def initialize(coordinate)
    @coordinate = coordinate
    @ship = nil
    @fired_upon = false
  end

  def empty?
    @ship.nil?
  end

  def place_ship(ship)
    @ship = ship
  end

  def fire_upon
    @fired_upon = true
    @ship.hit unless empty?
  end

  def fired_upon?
    @fired_upon
  end

  def render(fog_of_war = false)
    if fired_upon && empty?
      'M'
    elsif fired_upon && !empty? && !@ship.sunk?
      'H'
    elsif fired_upon && !empty? && @ship.sunk?
      'X'
    elsif fog_of_war && !empty?
      'S'
    else
      '.'
    end
  end
end
