require 'base' # contains constraint, individual and extension of array
require 'mutations' # contains implementations of all permutating mutations
require 'recombinations' # contains implementations of all permutating recombinations

NUMBER_OF_PERIODS = 30

# offene Fragen:
# - Beweis, dass Menge von clashing_periods durch gegenseitigen Austausch nicht zwingend zur Lösung führt
# - Beweis, dass nur Austausch der Constraints die clashing hervorrufen genügt
# - Beweis, dass Austausch von Constraints zwischen clashing_periods und nonclashing_periods genügt
# - zurücktauschen bei brute force wichtig?

def dual_hillclimber(individuals)
  population_size = individuals.length
  iterations = 0
  puts "Start timetabling with #{population_size} individuals, mutation: #{individuals.first.class}"

  while individuals.sort_by(&:fitness).first.fitness > 0
    iterations += 1

    new_individuals = []
    population_size.times do
      new_individuals << own_recombination(individuals[rand(individuals.length)], individuals[rand(individuals.length)])
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
  puts "=== Start hillclimber with " << individual.to_s
  time = Time.now
  
  while individual.fitness > 0 and ((Time.now - time) < limit or limit == 0)
    new_individual = individual.mutate
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
  individual = Individual.new(
    :current_constraints => constraints.shuffle,
    :expected_constraints => constraints,
    :mutation => DumbSwappingMutation.new,
    :recombination => IdentityRecombination.new,
    :number_of_slots => 30,
    :debug => true
  )
  # 100.times do
    iterations = hillclimber(individual, limit)
    puts "--- iterations: #{iterations}, summed up runtime: #{Time.now - time}"
  # end
end