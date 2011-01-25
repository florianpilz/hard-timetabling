require 'base' # contains constraint, period, individual and extension of array
require 'mutations' # contains implementations of all permutating mutations

NUMBER_OF_PERIODS = 30

def mutate_on_constraints(old_periods)
  constraints = []
  old_periods.each do |period|
    constraints << period.constraints
  end
  constraints = constraints.flatten

  constraints = yield constraints
  
  rooms = old_periods.first.constraints.length
  periods = []
  NUMBER_OF_PERIODS.times do |i|
    period_constraints = []
    rooms.times do |j|
      period_constraints << constraints[i * rooms + j]
    end
    periods << Period.new(:constraints => period_constraints)
  end
  periods
end

# offene Fragen:
# - Beweis, dass Menge von clashing_periods durch gegenseitigen Austausch nicht zwingend zur Lösung führt
# - Beweis, dass nur Austausch der Constraints die clashing hervorrufen genügt
# - Beweis, dass Austausch von Constraints zwischen clashing_periods und nonclashing_periods genügt
# - zurücktauschen bei brute force wichtig?

def ordnungsrekombination(individual1, individual2)
  periods = mutate_on_constraints(individual1.periods) do |individual1_constraints|
    constraints = []
    rn = rand(individual1_constraints.length)
    0.upto(rn) do |i|
      constraints << individual1_constraints[i]
    end
    mutate_on_constraints(individual2.periods) do |individual2_constraints|
      individual2_constraints.each do |constraint|
        constraints << constraint unless constraints.include?(constraint)
      end
      constraints
    end
    constraints
  end
  MixingConstraints.new(periods, individual1.constraints)
end

def mapping_recombination(individual1, individual2)
  periods = mutate_on_constraints(individual1.periods) do |individual1_constraints|
    constraints = []
    rn_start = rand(individual1_constraints.length)
    rn_end = rand(individual1_constraints.length)
    rn_start, rn_end = rn_end, rn_start if rn_start > rn_end
    
    rn_start.upto(rn_end) do |i|
      constraints[i] = individual1_constraints[i]
    end
    
    mutate_on_constraints(individual2.periods) do |individual2_constraints|
      0.upto(rn_start - 1) do |i|
        c = individual2_constraints[i]
        c = individual1_constraints[individual2_constraints.index(c)] while constraints.include?(c)
        constraints[i] = c
      end

      (rn_end + 1).upto(individual2_constraints.length - 1) do |i|
        c = individual2_constraints[i]
        c = individual1_constraints[individual2_constraints.index(c)] while constraints.include?(c)
        constraints[i] = c
      end

      constraints
    end
    constraints
  end
  MixingConstraints.new(periods, individual1.constraints)
end

def edge_recombination(individual1, individual2)
  periods = mutate_on_constraints(individual1.periods) do |individual1_constraints|
    l = individual1_constraints.length
    constraints = []
    used_nodes = []
    edges = {}
    
    individual1_constraints.each do |c|
      edges[c.hash.to_s.to_sym] = []
    end
    
    individual1_constraints.each_with_index do |c, i|
      c1 = individual1_constraints[(i + 1) % l]
      c2 = individual1_constraints[(i - 1) % l]
      edges[c.hash.to_s.to_sym] << c1 << c2
    end
    
    mutate_on_constraints(individual2.periods) do |individual2_constraints|
      
      individual2_constraints.each_with_index do |c, i|
        c1 = individual2_constraints[(i + 1) % l]
        c2 = individual2_constraints[(i - 1) % l]
        edges[c.hash.to_s.to_sym] << c1 << c2
      end
            
      if rand(2) > 0
        constraints[0] = individual1_constraints.first
        used_nodes << individual1_constraints.first
      else
        constraints[0] = individual2_constraints.first
        used_nodes << individual2_constraints.first
      end
      
      individual2_constraints
    end
    
    1.upto(l - 1) do |i|
      possibilities = edges[constraints.last.hash.to_s.to_sym] - used_nodes
      possibilities = possibilities.sort_by { |c| (edges[c.hash.to_s.to_sym] - used_nodes).length }
      
      k = []
      unless possibilities.empty?
        i = 0
        while i < possibilities.length and (edges[possibilities[0].hash.to_s.to_sym] - used_nodes).length == (edges[possibilities[i].hash.to_s.to_sym] - used_nodes).length
          k << possibilities[i]
          i += 1
        end
      end
      
      if k.empty?
        temp_constraints = individual1_constraints - used_nodes
        node = temp_constraints[rand(temp_constraints.length)]
        constraints << node
        used_nodes << node
      else
        node = k[rand(k.length)]
        constraints << node
        used_nodes << node
      end
    end
    
    constraints
  end
  MixingConstraints.new(periods, individual1.constraints)
end

def dual_hillclimber(individuals)
  population_size = individuals.length
  iterations = 0
  puts "Start hillclimber with two individuals using recombination"

  while individuals.sort_by(&:fitness).first.fitness > 0
    iterations += 1

    new_individuals = []
    population_size.times do
      individuals << edge_recombination(individuals[rand(individuals.length)], individuals[rand(individuals.length)])
    end
    new_individuals.each(&:mutate)
    new_individuals += individuals # place old individuals at the end to prefer childs when fitness is same

    individuals = individuals.sort_by(&:fitness).take(population_size)
    puts "Iterations: #{iterations}, unfulfilled constraints: #{individuals.first.unfulfilled_constraints}, collisions: #{individuals.first.collisions}"
  end

  iterations
end

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
  puts "Start timetabling with " << individual.class.to_s
  
  while individual.fitness > 0
    new_individual = individual.deep_clone
    new_individual.mutate
    iterations += 1
    individual, _ = [new_individual, individual].sort_by(&:fitness) # its important that new_individual is set before individual, so its preferred if both have the same fitness -- influences algorithm a big deal
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
  # constraints = constraints.sort_by{rand}
  constraints.shuffle!
  
  periods = []
  NUMBER_OF_PERIODS.times do |i|
    period_constraints = []
    rooms.times do |j|
      period_constraints << constraints[i * rooms + j]
    end
    periods << Period.new(:constraints => period_constraints)
  end
  
  individuals = []
  10.times do
    new_periods = mutate_on_constraints(periods) do |temp_constraints|
      temp_constraints.shuffle
    end
    individuals << MixingConstraints.new(new_periods, constraints)
  end

  # iterations = hillclimber(individual)
  iterations = dual_hillclimber(individuals)
  puts "Iterations for random solver: #{iterations}"
  puts "Runtime in seconds: #{Time.new - time}"
end