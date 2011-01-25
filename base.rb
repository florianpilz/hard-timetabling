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
    self
    # self.clone
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

class Individual
  attr_accessor :periods, :colliding_periods, :constraints
  
  def initialize(periods, constraints)
    @periods = periods.map{|p| p.deep_clone}
    @constraints = constraints.map{|c| c.deep_clone}
    @colliding_periods = @periods.select{|p| p.collisions > 0}
    @old_colliding_periods = @colliding_periods
    # @rand_period_nr1 = 0
    # @rand_period_nr2 = 0
    # @rand_constraint_nr1 = 0
    # @rand_constraint_nr2 = 0
  end
  
  def fitness
    self.collisions + self.unfulfilled_constraints
  end
  
  def collisions
    @colliding_periods.inject(0){|sum, p| sum += p.collisions}
    # @colliding_periods.length
  end
  
  def unfulfilled_constraints # FIXME yields 0 if two identical constraints only occur once
    temp_constraints = @constraints.map{|c| c.deep_clone}
    delete_constraint = nil
    @periods.each do |period|
      period.constraints.each do |c1|
        temp_constraints.each do |c2|
          if c1.klass == c2.klass and c1.teacher == c2.teacher and c1.room == c2.room
            delete_constraint = c2
            break
          end
        end
        temp_constraints.delete(delete_constraint) if delete_constraint != nil
      end
    end
    temp_constraints.length
  end
  
  def deep_clone
    clone = self.clone
    # clone.periods = Marshal.load(Marshal.dump(@periods)) # short and safe, but expensive
    clone.periods = self.periods.map{|p| p.deep_clone}
    clone.update # FIXME should not update in clone method
    clone
  end
  
  def update
    @old_colliding_periods = @colliding_periods
    @colliding_periods = @periods.select{|p| p.collisions > 0}
  end
    
  # def print_last_mutation # TODO not used anymore
  #   unless @old_colliding_periods.include?(@periods[@rand_period_nr1]) # TODO why is this necessary?
  #     puts "Colliding (#{@rand_constraint_nr2}):"
  #     puts @old_colliding_periods[@rand_period_nr2]
  #     puts ""
  #     puts "Other (#{@rand_constraint_nr1}):"
  #     puts @periods[@rand_period_nr1].to_s
  #   end
  # end
end