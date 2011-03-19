# Copyright (c) 2011 Florian Pilz
# See MIT-LICENSE for license information.

require 'base'
require 'mutations'
require 'recombinations'
require 'selections'

require 'ostruct'
require 'optparse'

class Parser
  attr_accessor :banner, :version

  def initialize
    @options = []
    @used_short = []
    yield self
  end

  def option(name, desc, settings = {})
    @options << [name, desc, settings]
  end

  def short_from(name)
    name.to_s.chars.each do |c|
      next if @used_short.include?(c) || c == "_"
      return c # returns from short_from method
    end
  end

  def validate(options) # remove this method if you want fewer lines of code and don't need validations
    options.each_pair do |key, value|
      opt = @options.find_all{ |o| o[0] == key }.first
      key = "--" << key.to_s.gsub("_", "-")
      unless opt[2][:value_in_set].nil? || opt[2][:value_in_set].include?(value)
        puts "Parameter for #{key} must be one of [" << opt[2][:value_in_set].join(", ") << "]" ; exit(1)
      end
      unless opt[2][:value_matches].nil? || opt[2][:value_matches] =~ value
        puts "Parameter for #{key} must match /" << opt[2][:value_matches].source << "/" ; exit(1)
      end
      unless opt[2][:value_satisfies].nil? || opt[2][:value_satisfies].call(value)
        puts "Parameter for #{key} must satisfy given conditions (see description)" ; exit(1)
      end
    end
  end

  def process!
    options = {}
    optionparser = OptionParser.new do |p|
      @options.each do |o|
        @used_short << short = o[2][:short] || short_from(o[0])
        options[o[0]] = o[2][:default] || false # set default
        klass = o[2][:default].class == Fixnum ? Integer : o[2][:default].class

        if [TrueClass, FalseClass, NilClass].include?(klass) # boolean switch
          p.on("-" << short, "--[no-]" << o[0].to_s.gsub("_", "-"), o[1]) {|x| options[o[0]] = x}
        else # argument with parameter
          p.on("-" << short, "--" << o[0].to_s.gsub("_", "-") << " " << o[2][:default].to_s, klass, o[1]) {|x| options[o[0]] = x}
        end
      end

      p.banner = @banner unless @banner.nil?
      p.on_tail("-h", "--help", "Show this message") {puts p ; exit}
      short = @used_short.include?("v") ? "-V" : "-v"
      p.on_tail(short, "--version", "Print version") {puts @version ; exit} unless @version.nil?
    end

    begin
      optionparser.parse!(ARGV)
    rescue OptionParser::ParseError => e
      puts e.message ; exit(1)
    end

    validate(options) if self.respond_to?("validate")
    options
  end
end

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
    
    while individuals.first.fitness > 0 && (values[:time_limit] == 0 || values[:time_limit] > Time.now - time) && (values[:iterations] == 0 || values[:iterations] > iterations) && (values[:evaluations] == 0 || values[:evaluations] > values[:childs] * iterations)
      iterations += 1
      
      new_individuals = []
      values[:childs].times do
        if rand <= values[:recombination_chance]
          child = individuals.sample.recombinate_with(individuals.sample)
          if child.fitness > 0 && rand <= values[:mutation_chance]
            child = child.mutate
          end
          new_individuals << child
        else
          new_individuals << individuals.sample.mutate
        end
      end

      selectable_individuals = values[:parents_die] ? new_individuals : new_individuals + individuals
      selected_individuals = values[:environmental_selection].select(values[:population_size], selectable_individuals, values).sort_by(&:fitness)
      if selected_individuals.first.fitness < individuals.first.fitness || @print_info
        @print_info = false
        Timetabling::print_status(iterations, values[:childs] * iterations + values[:population_size], selected_individuals, time)
      end
      individuals = selected_individuals
    end
    
    if individuals.first.fitness > 0
      Timetabling::print_status(iterations, values[:childs] * iterations + values[:population_size], selected_individuals, time)
      puts "=== unfinished"
    else
      puts "=== finished"
    end
  end
  
  def self.print_status(iterations, evaluations, individuals, time)
    diversity_array = []
    individuals.each do |individual1|
      individuals.each do |individual2|
        diversity_array << individual1.distance_to(individual2)
      end
    end
    diversity = diversity_array.mean
    
    puts "Iterations: #{iterations}, Evaluations: #{evaluations}, Collisions: #{individuals.first.fitness}, Time: #{Time.now - time}, Diversity: #{diversity}"
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
    filtered_lines.each{|line| line.scan(/class (.*) < #{superclass}/){|m| matches << m.first.sub(superclass, "")}}
    matches
  end
end

Signal.trap("TSTP") do |x| # Control-Z
  Timetabling::print_info = true
end

options = Parser.new do |p|
  p.version = "hard timetabling 2.1 (c) Florian Pilz"
  p.banner = "Timetabling is an evolutionary algorithm to solve hard-timetabling problems."
  p.option :severity, "Severity of the timetabling problem", :default => 4, :value_in_set => [4,5,6,7,8]
  p.option :mutation, "Mutation used in the algorithm", :default => "TripleSwapperWithTwoCollidingPeriods", :value_in_set => Timetabling::read_possibilities("mutations.rb", "Mutation")
  p.option :recombination, "Recombination used in the algorithm", :default => "Mapping", :value_in_set => Timetabling::read_possibilities("recombinations.rb", "Recombination")
  p.option :iterations, "Algorithm will stop after given number of iterations or run indefinitely if 0", :default => 0
  p.option :time_limit, "Algorithm will stop after given time limit or run indefinitely if 0", :default => 0
  p.option :evaluations, "Algorithm will stop after given number of evaluations (= childs per generation * iterations + population size) or run indefinitely if 0", :default => 5_000_000
  p.option :cycles, "Determines how often the algorithm will be run", :default => 1, :value_satisfies => lambda{|x| x > 0}
  p.option :population_size, "Size of the population", :default => 1, :value_satisfies => lambda{|x| x > 0}
  p.option :childs, "Number of childs generated each iteration", :default => 1, :short => "l", :value_satisfies => lambda{|x| x > 0}
  p.option :recombination_chance, "Chance that recombination is used to generate child", :default => 0.0, :value_satisfies => lambda{|x| x >= 0.0 && x <= 1.0}
  p.option :mutation_chance, "Chance that mutation is used, after recombination was used", :default => 1.0, :value_satisfies => lambda{|x| x >= 0.0 && x <= 1.0}
  p.option :parents_die, "Parents will die each iteration if set, i.e. a comma-selection is used", :default => false
  p.option :environmental_selection, "Selection used to determine which individuals will form the next generation", :default => "Best", :value_in_set => Timetabling::read_possibilities("selections.rb", "Selection")
  p.option :stages, "Number of stages if NStageTournamentSelection is used", :default => 3
end.process!

# load mutation, recombination, selection
mutation = Kernel.const_get(options[:mutation] + "Mutation").new
recombination = Kernel.const_get(options[:recombination] + "Recombination").new
environmental_selection = Kernel.const_get(options[:environmental_selection] + "Selection").new

# start algorithm
constraints = Timetabling::read_timetable_data(options[:severity])

options[:cycles].times do
  Timetabling::run(options.merge({:constraints => constraints, :mutation => mutation, :recombination => recombination, :environmental_selection => environmental_selection, :number_of_slots => 30}))
end