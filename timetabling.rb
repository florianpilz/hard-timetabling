require 'base' # contains constraint, period, individual and extension of array

NUMBER_OF_PERIODS = 30

class Individual
  def mutate
    rand_period_nr1 = rand(@periods.length)
    rand_constraint_nr1 = rand(@periods.first.constraints.length)
    rand_period_nr2 = rand(@colliding_periods.length)
    rand_constraint_nr2 = rand(@colliding_periods.first.constraints.length)
    
    @periods[rand_period_nr1].constraints[rand_constraint_nr1], @colliding_periods[rand_period_nr2].constraints[rand_constraint_nr2] =
      @colliding_periods[rand_period_nr2].constraints[rand_constraint_nr2], @periods[rand_period_nr1].constraints[rand_constraint_nr1]
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
    end
    periods << Period.new(:constraints => period_constraints)
  end
  
  individual = Individual.new(periods, constraints)
  
  iterations = hillclimber(individual)
  puts "Iterations for random solver: #{iterations}"
  puts "Runtime in seconds: #{Time.new - time}"
end