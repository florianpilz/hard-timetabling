require 'base'
require 'mutations'
require 'recombinations'

# offene Fragen:
# - Beweis, dass Menge von clashing_periods durch gegenseitigen Austausch nicht zwingend zur Lösung führt
# - Beweis, dass nur Austausch der Constraints die clashing hervorrufen genügt
# - Beweis, dass Austausch von Constraints zwischen clashing_periods und nonclashing_periods genügt
# - zurücktauschen bei brute force wichtig?

module Main
  def self.run(values)
    individuals = []
    values[:population_size].times do
      individuals << Individual.new(
        values.merge({:current_constraints => values[:constraints].shuffle,
                      :expected_constraints => values[:constraints]}))
    end
    
    iterations = 0
    puts "Start with population size of #{values[:population_size]} -- Mutation: #{values[:mutation]}, Recombination: #{values[:recombination]}"
    
    while individuals.sort_by(&:fitness).first.fitness > 0
      iterations += 1
      
      new_individuals = []
      values[:population_size].times do
        new_individuals += individuals.sample.recombinate_with(individuals.sample)
      end
      new_individuals = new_individuals.map(&:mutate)
      new_individuals += individuals # place old individuals at the end to prefer childs when fitness is same

      individuals = new_individuals.sort_by(&:fitness).take(values[:population_size])
      puts "Iterations: #{iterations}, collisions: #{individuals.first.collisions}" if iterations % 1000 == 0
    end

    iterations
  end

  def self.read_timetable_data(number)
    constraints = []
    File.open("hard-timetabling-data/hdtt#{number}list.txt", "r") do |file|
      while line = file.gets
        constraints << Constraint.parse(line)
      end
    end
    constraints
  end
end

constraints = Main::read_timetable_data(4)
Main::run(:constraints => constraints, :mutation => TripleSwapperWithTwoCollidingConstraintsMutation.new, :recombination => IdentityRecombination.new, :number_of_slots => 30, :population_size => 1)