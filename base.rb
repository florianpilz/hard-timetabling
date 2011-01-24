class Array
  def sum
    inject( nil ) { |sum,x| sum ? sum+x : x }
  end
  
  def mean
    sum / size
  end
end

class Constraint
  attr_accessor :klass, :teacher, :room
  
  def initialize(values = {})
    @klass = values[:klass]
    @teacher = values[:teacher]
    @room = values[:room]
  end
  
  def deep_clone
    self.clone
  end
  
  def to_s
    "Klasse: #{@klass}, Lehrer: #{@teacher}, Raum: #{@room}"
  end
end

class Period
  attr_accessor :constraints
  
  def initialize(values = {})
    @constraints = values[:constraints]
  end

  def collisions
    collisions = 0
    @constraints.each do |c1|
      @constraints.each do |c2|
        next if c1 == c2
        collisions += 1 if c1.klass == c2.klass or c1.teacher == c2.teacher or c1.room == c2.room
      end
    end
    collisions
  end
  
  def deep_clone
    clone = self.clone
    clone.constraints = self.constraints.map{|c| c.deep_clone}
    clone
  end

  def to_s
    i = 0
    @constraints.inject("") do |output, c|
      i += 1
      output << "Constraint #{i}: Klasse = #{c.klass}, Lehrer = #{c.teacher}, Raum = #{c.room}\n"
    end
  end
end
