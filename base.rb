NUMBER_OF_SLOTS = 30 # same for all sample data

class Array
  def sum
    inject( nil ) { |sum,x| sum ? sum+x : x }
  end
  
  def mean
    sum / size
  end
  
  def rand_index
    rand(self.length)
  end
  
  def sample
    self[rand_index]
  end
end

class Constraint
  attr_accessor :klass, :teacher, :room
  
  def initialize(values = {})
    @klass = values[:klass]
    @teacher = values[:teacher]
    @room = values[:room]
  end
  
  def to_s
    "Klasse: #{@klass}, Lehrer: #{@teacher}, Raum: #{@room}"
  end
end

class Individual
  attr_accessor :constraints, :collisions, :unfulfilled_constraints
  
  def initialize(values = {})
    values = {:granularity => 0, :debug => false}.merge(values)
    @constraints          = values[:current_constraints]
    @expected_constraints = values[:expected_constraints]
    @mutation             = values[:mutation]
    @recombination        = values[:recombination]
    @granularity          = values[:granularity]
    @debug                = values[:debug]
    @slot_size            = values[:slot_size]
    self.eval_fitness
  end
  
  def to_s
    "Individual with mutation #{@mutation.to_s} and recombination #{@recombination.to_s}"
  end
  
  def copy
    individual = self.clone
    individual.constraints = @constraints.clone # only attribute that may change
    individual
  end
  
  def mutate # must return individual
    @mutation.call(self)
  end
  
  def recombinate_with(individual) # must return two individuals
    @recombination.call(self, individual)
  end
  
  def fitness
    @collisions + @unfulfilled_constraints
  end
  
  def eval_fitness
    @collisions = eval_collisions
    @unfulfilled_constraints = eval_unfulfilled_constraints
    fitness
  end
  
  private
  
  def eval_collisions
    collisions = 0
    NUMBER_OF_SLOTS.times do |n|
      old_collisions = collisions
      
      0.upto(@slot_size - 1) do |i|
        c1 = @constraints[@slot_size * n + i]
        
        (i + 1).upto(@slot_size - 1) do |j|
          c2 = @constraints[@slot_size * n + j]

          if @granularity == 0
            collisions += 1 if c1.klass == c2.klass
            collisions += 1 if c1.teacher == c2.teacher
            collisions += 1 if c1.room == c2.room
          elsif @granularity == 1
            collisions += 1 if c1.klass == c2.klass || c1.teacher == c2.teacher || c1.room == c2.room
          else
            if old_collisions == collisions # only increase collisions once per period
              collisions += 1 if c1.klass == c2.klass || c1.teacher == c2.teacher || c1.room == c2.room
            end
          end
        end
      end
    end
    collisions
  end
  
  def eval_unfulfilled_constraints
    return 0 unless @debug # assume all constraints are fulfilled unless in debug mode
    
    # FIXME yields 0 if two identical constraints only occur once => should be solved
    expected_constraints = @expected_constraints.clone
    delete_constraints = []
    
    expected_constraints.each do |c1|
      constraints.each do |c2|
        delete_constraints << c1 if c1 == c2
      end
    end
    
    delete_constraints.each do |c|
      expected_constraints.delete(c)
    end
    
    expected_constraints.length
  end
end