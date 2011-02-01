class Mutation
  def to_s
    self.class.to_s
  end
end

class IdentityMutation < Mutation
  def call(individual)
    individual.copy
  end
end

class DumbSwappingMutation < Mutation
  def call(individual)
    child = individual.copy
    r1 = child.constraints.rand_index
    r2 = child.constraints.rand_index

    child.constraints[r1], child.constraints[r2] = child.constraints[r2], child.constraints[r1]
    child.eval_fitness
    child
  end
end

class CollidingPeriodsSwapperMutation < Mutation
  def call(individual)
    child = individual.copy
    periods = child.constraints.to_periods(child.number_of_slots)
    
    cp = periods.select {|p| p.collision?}
    rp1 = cp.rand_index
    rp2 = cp.rand_index
    rc1 = cp[rp1].rand_colliding_constraint_index
    rc2 = cp[rp2].rand_colliding_constraint_index
    
    cp[rp1].constraints[rc1], cp[rp2].constraints[rc2] = cp[rp2].constraints[rc2], cp[rp1].constraints[rc1]
    
    child.constraints = periods.to_constraints
    child.eval_fitness
    child
  end
end

class InvertingMutation < Mutation
  def call(individual)
    child = individual.copy
    constraints_copy = child.constraints.clone
    
    rn1 = child.constraints.rand_index
    rn2 = child.constraints.rand_index
    rn1, rn2 = rn2, rn1 if rn1 > rn2
    
    rn1.upto(rn2) do |i|
      child.constraints[rn2 + rn1 - i] = constraints_copy[i]
    end
    
    child.eval_fitness
    child
  end
end

class InvertingWithCollisionMutation < Mutation
  def call(individual)
    child = individual.copy
    constraints_copy = child.constraints.clone
    periods = child.constraints.to_periods(child.number_of_slots)
    cp = periods.select{|p| p.collision?}
    
    rn1 = child.constraints.rand_index
    rp = cp.rand_index
    rc = cp[rp].rand_colliding_constraint_index
    rn2 = child.constraints.index(cp[rp].constraints[rc])
    rn1, rn2 = rn2, rn1 if rn1 > rn2
    
    rn1.upto(rn2) do |i|
      child.constraints[rn2 + rn1 - i] = constraints_copy[i]
    end
    
    child.eval_fitness
    child
  end
end

class MixingMutation < Mutation
  def call(individual)
    child = individual.copy
    
    rn1 = child.constraints.rand_index
    rn2 = child.constraints.rand_index
    rn1, rn2 = rn2, rn1 if rn1 > rn2

    start = child.constraints[0..rn1-1] # yields all constraints if range is 0..-1, next line prevents this
    start = [] if rn1 == 0
    
    child.constraints = start + child.constraints[rn1..rn2].shuffle + child.constraints[rn2+1..child.constraints.length-1]
    child.eval_fitness
    child
  end
end

class ShiftingMutation < Mutation
  def call(individual)
    child = individual.copy
    constraints_copy = child.constraints.clone
    
    rn1 = child.constraints.rand_index
    rn2 = child.constraints.rand_index    
    rn1, rn2 = rn2, rn1 if rn1 > rn2
    
    child.constraints[rn2] = constraints_copy[rn1]
    rn1.upto(rn2 - 1) do |i|
      child.constraints[i] = constraints_copy[i + 1]
    end
    
    child.eval_fitness
    child
  end
end
###########################################
# local optima, runs fast into local optima
class SwappingBetweenCollidingPeriods < Individual
  def mutate
    rand_period_nr1 = rand(@colliding_periods.length)
    rand_constraint_nr1 = rand(@colliding_periods.first.constraints.length)
    rand_period_nr2 = rand(@colliding_periods.length)
    rand_constraint_nr2 = rand(@colliding_periods.first.constraints.length)
    
    @colliding_periods[rand_period_nr1].constraints[rand_constraint_nr1], @colliding_periods[rand_period_nr2].constraints[rand_constraint_nr2] =
      @colliding_periods[rand_period_nr2].constraints[rand_constraint_nr2], @colliding_periods[rand_period_nr1].constraints[rand_constraint_nr1]
    self.update
  end
end

# global optima
class SwappingBetweenPeriods < Individual
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

# global optima, 100 runs within 90min
# ran into local optima with hdtt8: reached 4 collisions after 100k iterations, still at 4 collisions after 3k iterations
class SwappingBetweenConstraints < Individual
  def mutate
    rand_period_nr1 = rand(@periods.length)
    rand_constraint_nr1 = rand(@periods.first.constraints.length)
    rand_period_nr2 = rand(@colliding_periods.length)
    
    random_period = @colliding_periods[rand_period_nr2]
    colliding_constraints = []
    random_period.constraints.each do |c1|
      random_period.constraints.each do |c2|
        next if c1 == c2
        if c1.klass == c2.klass or c1.teacher == c2.teacher or c1.room == c2.room
          colliding_constraints << c1
          colliding_constraints << c2
        end
      end
    end
    colliding_constraints = colliding_constraints.uniq
    rand_constraint_nr2 = random_period.constraints.index(colliding_constraints[rand(colliding_constraints.length)])
    
    @periods[rand_period_nr1].constraints[rand_constraint_nr1], @colliding_periods[rand_period_nr2].constraints[rand_constraint_nr2] =
      @colliding_periods[rand_period_nr2].constraints[rand_constraint_nr2], @periods[rand_period_nr1].constraints[rand_constraint_nr1]
    self.update
  end
end

# global optima, 15k iterations, try variation with only one colliding period
# hdtt4: 18k iterations, 80s
# hdtt5: 60k iterations, ca. 8min
class TripleSwappingWithCollidingPeriod < Individual
  def mutate
    rnp1 = rand(@periods.length)
    rnc1 = rand(@periods.first.constraints.length)
    rnp2 = rand(@colliding_periods.length)
    rnc2 = rand(@colliding_periods.first.constraints.length)
    rnp3 = rand(@colliding_periods.length)
    rnc3 = rand(@colliding_periods.first.constraints.length)
    
    c1 = @periods[rnp1].constraints[rnc1]
    c2 = @colliding_periods[rnp2].constraints[rnc2]
    c3 = @colliding_periods[rnp3].constraints[rnc3]

    unless c1 == c3
      @periods[rnp1].constraints[rnc1] = c2
      @colliding_periods[rnp2].constraints[rnc2] = c3
      @colliding_periods[rnp3].constraints[rnc3] = c1
    else
      @colliding_periods[rnp2].constraints[rnc2] = c3
      @colliding_periods[rnp3].constraints[rnc3] = c2
    end
    self.update
  end
end

# global optima, 6k iterations, try variation with only one colliding constraint
# hdtt5: 23k iterations, ca. 5min
# hdtt6: 80k iterations, ca. 26min
# ran into local optima in hdtt7: reacher 6 remaining collisions after 100k iterations, still have 6 remaining after 3kk iterations
class TripleSwappingWithCollidingConstraint < Individual
  def mutate
    rnp1 = rand(@periods.length)
    rnc1 = rand(@periods.first.constraints.length)
    
    rnp2 = rand(@colliding_periods.length)
    random_period = @colliding_periods[rnp2]
    colliding_constraints = []
    random_period.constraints.each do |c1|
      random_period.constraints.each do |c2|
        next if c1 == c2
        if c1.klass == c2.klass or c1.teacher == c2.teacher or c1.room == c2.room
          colliding_constraints << c1
          colliding_constraints << c2
        end
      end
    end
    colliding_constraints = colliding_constraints.uniq
    rnc2 = random_period.constraints.index(colliding_constraints[rand(colliding_constraints.length)])
    
    rnp3 = rand(@colliding_periods.length)
    random_period = @colliding_periods[rnp3]
    colliding_constraints = []
    random_period.constraints.each do |c1|
      random_period.constraints.each do |c2|
        next if c1 == c2
        if c1.klass == c2.klass or c1.teacher == c2.teacher or c1.room == c2.room
          colliding_constraints << c1
          colliding_constraints << c2
        end
      end
    end
    colliding_constraints = colliding_constraints.uniq
    rnc3 = random_period.constraints.index(colliding_constraints[rand(colliding_constraints.length)])
    
    c1 = @periods[rnp1].constraints[rnc1]
    c2 = @colliding_periods[rnp2].constraints[rnc2]
    c3 = @colliding_periods[rnp3].constraints[rnc3]

    unless c1 == c3
      @periods[rnp1].constraints[rnc1] = c2
      @colliding_periods[rnp2].constraints[rnc2] = c3
      @colliding_periods[rnp3].constraints[rnc3] = c1
    else
      @colliding_periods[rnp2].constraints[rnc2] = c3
      @colliding_periods[rnp3].constraints[rnc3] = c2
    end
    self.update
  end
end

class OwnIndividual < Individual
  def mutate
    periods = mutate_on_constraints(@colliding_periods) do |constraints|
      constraints.shuffle! # krass schlecht
    end
    @periods = @periods - @colliding_periods + periods
    self.update
  end
end