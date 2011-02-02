class Recombination
  def to_s
    self.class.to_s
  end
end

class IdentityRecombination < Recombination
  def call(individual1, individual2)
    [individual1.copy, individual2.copy]
  end
end

class OrderingRecombination < Recombination
  def call(individual1, individual2)
    child1 = recombinate(individual1, individual2)
    child2 = recombinate(individual2, individual1)
    [child1, child2]
  end
  
  def recombinate(individual1, individual2)
    constraints = []
    rand_length = rand(individual1.constraints.length + 1)
    rand_length.times do |i|
      constraints << individual1.constraints[i]
    end
    
    individual2.constraints.each do |constraint|
      constraints << constraint unless constraints.include?(constraint)
    end
    
    child = individual1.copy
    child.constraints = constraints
    child.eval_fitness
    child
  end
end

########################################################################
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

def own_recombination(individual1, individual2)
  periods = individual1.periods - individual1.colliding_periods
  rest = []
  (individual2.periods - individual2.colliding_periods).each do |period|
    if periods.map{|p| period.constraints.map{|c| p.constraints.include?(c)}.any?}.any?
      rest << period
    else
      periods << period
    end
  end
  rest += individual1.colliding_periods + individual2.colliding_periods
  
  periods += mutate_on_constraints(rest) do |constraints|
    remaining_constraints = []
    constraints.each do |c|
      remaining_constraints << c unless periods.map{|p| p.constraints.include?(c)}.any?
    end
    rooms = individual1.periods.first.constraints.length
    new_constraints = remaining_constraints.take(rooms)
    while not remaining_constraints.empty?
      remaining_constraints.sort_by{}
    end
    new_constraints
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

def calc_collisions(c1, c2) # TODO remove
  collisions = 0
  collisions += 1 if c1.klass == c2.klass
  collisions += 1 if c1.teacher == c2.teacher
  collisions += 1 if c1.room == c2.room
  collisions
end
