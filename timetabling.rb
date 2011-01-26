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
  individual1.class.new(periods, individual1.constraints)
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
  individual1.class.new(periods, individual1.constraints)
end

def edge_recombination(individual1, individual2, variation = 0)
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
      if variation == 0
        possibilities = possibilities.sort_by { |c| (edges[c.hash.to_s.to_sym] - used_nodes).length }
      elsif variation == 1 # variation which orderes by least collisions with neighbours
        possibilities = possibilities.sort_by { |c| calc_collisions(constraints.last, c) }
      else # another variant with least collisions between last #rooms nodes
        rooms = individual1.periods.first.constraints.length
        last_index = constraints.index(constraints.last)
        latest_constraints = []
        (last_index - rooms + 1).upto(last_index) do |i|
          next if i < 0
          latest_constraints << constraints[i]
        end
        
        possibilities = possibilities.sort_by do |c1|
          collisions = 0
          collisions += latest_constraints.map { |c2| calc_collisions(c1, c2) }.sum
          collisions
        end
      end
      
      k = []
      unless possibilities.empty?
        i = 0
        if variation == 0 #######################
          while i < possibilities.length and (edges[possibilities[0].hash.to_s.to_sym] - used_nodes).length == (edges[possibilities[i].hash.to_s.to_sym] - used_nodes).length
            k << possibilities[i]
            i += 1
          end
        elsif variation == 1        
          while i < possibilities.length and calc_collisions(constraints.last, possibilities[0]) == calc_collisions(constraints.last, possibilities[i])
            k << possibilities[i]
            i += 1
          end
        else
          while i < possibilities.length and latest_constraints.map{|c| calc_collisions(c, possibilities[0])}.sum == latest_constraints.map{|c| calc_collisions(c, possibilities[i])}.sum
            k << possibilities[i]
            i += 1
          end
        end #########################################
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
  individual1.class.new(periods, individual1.constraints)
end

def calc_collisions(c1, c2)
  collisions = 0
  collisions += 1 if c1.klass == c2.klass
  collisions += 1 if c1.teacher == c2.teacher
  collisions += 1 if c1.room == c2.room
  collisions
end

def dual_hillclimber(individuals)
  population_size = individuals.length
  iterations = 0
  puts "Start timetabling with #{population_size} individuals, mutation: #{individuals.first.class}"

  while individuals.sort_by(&:fitness).first.fitness > 0
    iterations += 1

    new_individuals = []
    population_size.times do
      new_individuals << edge_recombination(individuals[rand(individuals.length)], individuals[rand(individuals.length)], 2)
    end
    new_individuals.each(&:mutate)
    new_individuals += individuals # place old individuals at the end to prefer childs when fitness is same

    individuals = new_individuals.sort_by(&:fitness).take(population_size)
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
def hillclimber(individual, limit = 0)
  iterations = 0
  puts "=== Start hillclimber with " << individual.class.to_s
  time = Time.now
  
  while individual.fitness > 0 and ((Time.now - time) < limit or limit == 0)
    new_individual = individual.deep_clone
    new_individual.mutate
    iterations += 1
    
    if new_individual.fitness < individual.fitness
      puts "Iterations: #{iterations}, collisions: #{new_individual.collisions}, valid: #{new_individual.unfulfilled_constraints == 0}, time: #{Time.now - time}"
    end
    
    individual, _ = [new_individual, individual].sort_by(&:fitness) # its important that new_individual is set before individual, so its preferred if both have the same fitness -- influences algorithm a big deal
  end
  
  if individual.fitness == 0
    puts "=== finished, time: #{Time.now - time}"
  else
    puts "=== unfinished, time: #{Time.now - time}"
  end
  
  iterations
end

def parse_constraint(text_constraint)
  klass, teacher, room = text_constraint.scan(/C(\d).*S\d.*T(\d).*R(\d).*/).first.map!{ |number_as_string| number_as_string.to_i }
  Constraint.new(:klass => klass, :teacher => teacher, :room => room)
end

timetable_data = ARGV[0] || 4
File.open("hard-timetabling-data/hdtt#{timetable_data}list.txt", "r") do |file|
  constraints = []
  lines = 0
  while line = file.gets
    constraints << parse_constraint(line)
    lines += 1
  end
  
  rooms = lines / NUMBER_OF_PERIODS
  constraints.shuffle!
  
  periods = []
  NUMBER_OF_PERIODS.times do |i|
    period_constraints = []
    rooms.times do |j|
      period_constraints << constraints[i * rooms + j]
    end
    periods << Period.new(:constraints => period_constraints)
  end
  
  # individuals = []
  # 10.times do
  #   new_periods = mutate_on_constraints(periods) do |temp_constraints|
  #     temp_constraints.shuffle
  #   end
  #   individuals << TripleSwappingWithCollidingConstraint.new(new_periods, constraints)
  # end
  # iterations = dual_hillclimber(individuals)
  
  time = Time.now
  limit = ARGV[1].to_f || 0
  100.times do
    iterations = hillclimber(TripleSwappingWithCollidingConstraint.new(periods, constraints), limit)
    puts "--- iterations: #{iterations}, summed up runtime: #{Time.now - time}"
  end
end