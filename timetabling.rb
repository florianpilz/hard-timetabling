# Copyright (c) 2011 Florian Pilz
# See MIT-LICENSE for license information.

require 'base'
require 'mutations'
require 'recombinations'
require 'rubygems'
require 'trollop'

# offene Fragen:
# - Beweis, dass Menge von clashing_periods durch gegenseitigen Austausch nicht zwingend zur Lösung führt
# - Beweis, dass nur Austausch der Constraints die clashing hervorrufen genügt
# - Beweis, dass Austausch von Constraints zwischen clashing_periods und nonclashing_periods genügt
# - zurücktauschen bei brute force wichtig?

module Timetabling
  @print_info = false
  
  def self.print_info=(bool)
    @print_info = bool
  end
  
  def self.run(values)
    individuals = []
    values[:population_size].times do
      individuals << Individual.new(
        values.merge({:current_constraints => values[:constraints].shuffle,
                      :expected_constraints => values[:constraints]}))
    end
    
    time = Time.now
    iterations = 0
    individuals = individuals.sort_by(&:fitness)
    puts "=== Start with population size of #{values[:population_size]} and #{values[:childs]} child(s) per iteration"
    puts "=== Mutation: #{values[:mutation]} (chance: #{values[:mutation_chance]})"
    puts "=== Recombination: #{values[:recombination]} (chance: #{values[:recombination_chance]})"
    
    while individuals.first.fitness > 0 && (values[:time_limit] == 0 || values[:time_limit] > Time.now - time) && (values[:iteration_limit] == 0 || values[:iteration_limit] > iterations)
      iterations += 1
      
      new_individuals = []
      values[:childs].times do
        if rand <= values[:recombination_chance]
          child = individuals.sample.recombinate_with(individuals.sample)
          if rand <= values[:mutation_chance]
            child = child.mutate
          end
          new_individuals << child
        else
          new_individuals << individuals.sample.mutate
        end
      end
      
      sorted_individuals = (new_individuals + individuals).sort_by(&:fitness).take(values[:population_size])
      if sorted_individuals.first.fitness < individuals.first.fitness || @print_info
        @print_info = false
        Timetabling::print_status(iterations, sorted_individuals, time)
      end
      individuals = sorted_individuals
    end
    
    if individuals.first.fitness > 0
      Timetabling::print_status(iterations, individuals, time)
      puts "=== unfinished"
    else
      puts "=== finished"
    end
  end
  
  def self.print_status(iterations, individuals, time)
    diversity_array = []
    individuals.each do |individual1|
      individuals.each do |individual2|
        diversity_array << individual1.distance_to(individual2)
      end
    end
    diversity = diversity_array.mean
    
    puts "Iterations: #{iterations}, Collisions: #{individuals.first.fitness}, Time: #{Time.now - time}, Diversity: #{diversity}"
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
  
  def self.read_possibilities(file, superclass)
    lines = File.read(file).split("\n")
    filtered_lines = lines.grep(/class .* < #{superclass}/)
    matches = []
    filtered_lines.each{|line| line.scan(/class (.*) < #{superclass}/){|m| matches <<  m.first.first}}
    matches.join("\n")
  end
end

Signal.trap("TSTP") do |x| # Control-Z
  Timetabling::print_info = true
end

options = Trollop::options do
  version "hard timetabling 2.1 (c) Florian Pilz"
  banner <<-EOS
timetabling is an evolutionary algorithm to solve hard-timetabling problems.

Usage:
  ruby timetabling.rb [options]
where [options] are:
EOS
  opt :severity, "Severity of the timetabling problem", :default => 4
  opt :mutation, "Mutation used in the algorithm, see lib/mutations.rb for options", :default => "TripleSwapperWithTwoCollidingConstraintsMutation"
  opt :recombination, "Recombination used in the algorithm, see lib/recombinations.rb for options", :default => "IdentityRecombination"
  opt :iterations, "Algorithm will stop after given number of iterations or run indefinitely if 0", :default => 5_000_000
  opt :time_limit, "Algorithm will stop after given time limit or run indefinitely if 0", :default => 0
  opt :cycles, "Determines how often the algorithm will be run", :default => 1
  opt :population, "Size of the population", :default => 1
  opt :childs, "Number of childs generated each iteration", :default => 1, :short => "l"
  opt :recombination_chance, "Chance that recombination is used to generate child", :default => 0.0
  opt :mutation_chance, "Chance that mutation is used, after recombination was used", :default => 1.0
end

# validations
Trollop::die :severity, "must be in [4, 5, 6, 7, 8]" unless [4,5,6,7,8].include?(options[:severity])

mutation = Kernel.const_get(options[:mutation]) rescue Trollop::die(:mutation, "is invalid, must be one of the following:\n" << Timetabling::read_possibilities("mutations.rb", "Mutation"))

recombination = Kernel.const_get(options[:recombination]) rescue Trollop::die(:recombination, "is invalid, must be one of the following:\n" << Timetabling::read_possibilities("recombinations.rb", "Recombination"))

Trollop::die :cycles, "must be 1 or greater" unless options[:cycles] > 0
Trollop::die :population, "must be 1 or greater" unless options[:population] > 0
Trollop::die :childs, "must be 1 or greater" unless options[:childs] > 0
Trollop::die :recombination_chance, "must be in [0, 1]" unless options[:recombination_chance] >= 0.0 && options[:recombination_chance] <= 1.0
Trollop::die :mutation_chance, "must be in [0, 1]" unless options[:mutation_chance] >= 0.0 && options[:mutation_chance] <= 1.0

# start algorithm
constraints = Timetabling::read_timetable_data(options[:severity])

options[:cycles].times do
  Timetabling::run(:constraints => constraints, :mutation => mutation.new, :recombination => recombination.new, :number_of_slots => 30, :population_size => options[:population], :childs => options[:childs], :recombination_chance => options[:recombination_chance], :mutation_chance => options[:mutation_chance], :iteration_limit => options[:iterations], :time_limit => options[:time_limit])
end