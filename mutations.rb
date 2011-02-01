class Period
  attr_accessor :constraints
  
  def initialize(constraints)
    @constraints = constraints
  end
  
  def collision?
    @constraints.each do |c1|
      @constraints.each do |c2|
        next if c1 == c2
        return true if c1.klass == c2.klass || c1.teacher == c2.teacher || c1.room == c2.room
      end
    end
    false
  end
  
  def rand_colliding_constraint_index
    colliding_constraints = []
    @constraints.each do |c1|
      @constraints.each do |c2|
        next if c1 == c2
        if c1.klass == c2.klass || c1.teacher == c2.teacher || c1.room == c2.room
          colliding_constraints << c1
          colliding_constraints << c2
        end
      end
    end
    @constraints.index(colliding_constraints.uniq.sample)
  end
  
  def rand_constraint_index
    @constraints.rand_index
  end
end

class Mutation
  def to_s
    self.class.to_s
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

class IdentityMutation
  def call(individual)
    individual.copy
  end
end

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

# global optima, 700k Iterations
class InvertingConstraints < Individual
  def mutate
    @periods = mutate_on_constraints(@periods) do |constraints|
      copied_constraints = constraints.map {|c| c.deep_clone}
      rn1 = rand(constraints.length)
      rn2 = rand(constraints.length)
      rn1, rn2 = rn2, rn1 if rn1 > rn2

      rn1.upto(rn2) do |i|
        constraints[rn2 + rn1 - i] = copied_constraints[i]
      end
      constraints      
    end
    self.update
  end
end

# global optima, 100k iterations
class InvertingConstraintsWithCollisionAtStartOrEnd < Individual
  def mutate
    @periods = mutate_on_constraints(@periods) do |constraints|
      copied_constraints = constraints.map {|c| c.deep_clone}

      rand_period = rand(@colliding_periods.length)
      random_period = @colliding_periods[rand_period]
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
      rand_constraint = colliding_constraints[rand(colliding_constraints.length)]
      
      rn1 = constraints.index(rand_constraint)
      rn2 = rand(constraints.length)
      rn1, rn2 = rn2, rn1 if rn1 > rn2

      rn1.upto(rn2) do |i|
        constraints[rn2 + rn1 - i] = copied_constraints[i]
      end
      constraints      
    end
    self.update
  end
end

# glopbal optima, 300k iterations
class InvertingConstraintsContainingCollision < Individual
  def mutate
    @periods = mutate_on_constraints(@periods) do |constraints|
      copied_constraints = constraints.map {|c| c.deep_clone}

      rand_period = rand(@colliding_periods.length)
      random_period = @colliding_periods[rand_period]
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
      rand_constraint = colliding_constraints[rand(colliding_constraints.length)]
      
      middle = constraints.index(rand_constraint)
      length = rand(constraints.length) + 1
      if (middle - length / 2 < 0)
        index_start = 0
        index_end = length - 1
      elsif (middle + length / 2 + length % 2 - 1 > constraints.length - 1)
        index_start = constraints.length - length
        index_end = constraints.length - 1
      else
        index_start = middle - length / 2
        index_end = middle + length / 2 + length % 2 - 1
      end
      
      index_start.upto(index_end) do |i|
        constraints[index_start + index_end - i] = copied_constraints[i]
      end
      constraints      
    end
    self.update
  end
end

# theoretically global optima possible, practically local optima (too slow, 4kk iterations till 30 collisions)
# no domaoin specific knowledge usable, i.e. collisions
class MixingConstraints < Individual
  def mutate
    @periods = mutate_on_constraints(@periods) do |constraints|
      rn1 = rand(constraints.length)
      rn2 = rand(constraints.length)
      rn1, rn2 = rn2, rn1 if rn1 > rn2

      start = constraints[0..rn1-1] # yields all constraints if range is 0..-1, next line prevents this
      start = [] if rn1 == 0
      
      start + constraints[rn1..rn2].shuffle + constraints[rn2+1..constraints.length-1]
    end
    self.update
  end
end

# local optima, 4.4kk iterations
class ShiftingConstraints < Individual
  def mutate
    @periods = mutate_on_constraints(@periods) do |constraints|
      copied_constraints = constraints.map {|c| c.deep_clone}
      rn1 = rand(constraints.length)
      rn2 = rand(constraints.length)
      rn1, rn2 = rn2, rn1 if rn1 > rn2
      
      constraints[rn2] = copied_constraints[rn1]
      rn1.upto(rn2 - 1) do |i|
        constraints[i] = copied_constraints[i + 1]
      end
      constraints      
    end
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