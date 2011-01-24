require 'base'

NUMBER_OF_PERIODS = 30

class Individual
  def mutate
    @rand_period_nr1 = rand(@periods.length)
    @rand_constraint_nr1 = rand(@periods.first.constraints.length)
    @rand_period_nr2 = rand(@colliding_periods.length)
    @rand_constraint_nr2 = rand(@colliding_periods.first.constraints.length)
    
    @periods[@rand_period_nr1].constraints[@rand_constraint_nr1], @colliding_periods[@rand_period_nr2].constraints[@rand_constraint_nr2] =
      @colliding_periods[@rand_period_nr2].constraints[@rand_constraint_nr2], @periods[@rand_period_nr1].constraints[@rand_constraint_nr1]

    # constraint = @periods[@rand_period_nr1].constraints[@rand_constraint_nr1]
    # constraint.klass = rand(4) + 1
    # constraint.teacher = rand(4) + 1
    # constraint.room = rand(4) + 1
    
    self.update
  end
end

# offene Fragen:
# - Beweis, dass Menge von clashing_periods durch gegenseitigen Austausch nicht zwingend zur Lösung führt
# - Beweis, dass nur Austausch der Constraints die clashing hervorrufen genügt
# - Beweis, dass Austausch von Constraints zwischen clashing_periods und nonclashing_periods genügt
# - zurücktauschen bei brute force wichtig?

# nur tauschen unter kaputten periods reicht nicht aus
# -> kaputt muss mit jeder period tauschen können
# aber scheinbar erlaubtes Constraint: es müssen zwischenzeitlich nicht mehr periods kaputt gemacht werden um zur optimalen Lösung zu gelangen
# Laufzeiten:
#   hdtt4: ~  1 Minute , 30k-50k Iterationen
#   hdtt5: ~ 10 Minuten, 300k-400k Iterationen
#   hdtt6: ~6.5 Stunden, 7.7kk Iterationen
#   hdtt7: nach 12 Stunden und 16kk Iterationen abgebrochen (war bei Güte 22)
def hillclimber(individual)
  iterations = 0
  
  while individual.collisions > 0 || individual.unfulfilled_constraints > 0
    new_individual = individual.deep_clone
    new_individual.mutate
    iterations += 1
    unless (new_individual.unfulfilled_constraints + new_individual.collisions) > (individual.unfulfilled_constraints + individual.collisions)
      individual = new_individual
    end
    puts "Iterations: #{iterations}, unfulfilled constraints: #{individual.unfulfilled_constraints}, collisions: #{individual.collisions}" if iterations % 1000 == 0
  end
  
  iterations
end

def population_based_hillclimber(individual, size)
  iterations = 0
  population = []
  size.times { population << individual.deep_clone }
  population.each do |i|
    i.periods = i.periods.sort_by{rand}
  end
  
  best = select_best(population)
  while best.collisions > 0
    childs = []
    population.each do |i|
      child = i.deep_clone
      child.mutate
      childs << child
    end
    
    selection_population = population + childs
    selection_population = selection_population.sort_by{|i| i.collisions}.reverse
    selection = []
    population.length.times {|i| selection << selection_population.pop}
    population = selection
    best = select_best(population)
    iterations += 1
    puts "Iterations: #{iterations}, collisions of best individual: #{best.collisions}" if iterations % 1000 == 0
  end
  iterations
end

def select_best(population)
  best = population.first
  population.each do |individual|
    if individual.collisions < best.collisions
      best = individual
    end
  end
  best
end

def exchange(p1, p2, pn1, cn1, pn2, cn2)
  p1[pn1].constraints[cn1], p2[pn2].constraints[cn2] = p2[pn2].constraints[cn2], p1[pn1].constraints[cn1]
end

def problem_creator(depth)
  all_constraints = []
  periods = []
  depth.times do |i|
    i += 1
    constraints = []
    depth.times do
      constraints << Constraint.new(:klass => i, :teacher => i, :room => i)
    end
    periods << Period.new(:constraints => constraints)
    all_constraints << constraints
  end
  all_constraints = all_constraints.flatten
  Individual.new(periods, all_constraints)
end

def parse_constraint(text_constraint)
  klass, teacher, room = text_constraint.scan(/C(\d).*S\d.*T(\d).*R(\d).*/).first.map!{ |number_as_string| number_as_string.to_i }
  Constraint.new(:klass => klass, :teacher => teacher, :room => room)
end

File.open("hard-timetabling-data/hdtt4list.txt", "r") do |file|
  time = Time.new
  constraints = []
  lines = 0
  while line = file.gets
    constraints << parse_constraint(line)
    lines += 1
  end
  
  rooms = lines / NUMBER_OF_PERIODS
  constraints = constraints.sort_by{rand}
  
  periods = []
  NUMBER_OF_PERIODS.times do |i|
    period_constraints = []
    rooms.times do |j|
      period_constraints << constraints[i * rooms + j]
      # period_constraints << Constraint.new(:klass => 1, :teacher => 1, :room => 1) # for binary-mutation approach
    end
    periods << Period.new(:constraints => period_constraints)
  end
  
  individual = Individual.new(periods, constraints)
  # individual = problem_creator(5)
  
  iterations = hillclimber(individual)
  # iterations = population_based_hillclimber(individual, 5)
  puts "Iterations for random solver: #{iterations}"
  puts "Runtime in seconds: #{Time.new - time}"
end