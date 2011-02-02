require 'base'
require 'mutations'
require 'recombinations'

describe Array do
  subject { [1,2,3,4] }
  it "returns the sum of its content" do
    subject.sum.should == 10
  end

  it "returns the mean of its content" do
    subject.mean.should == 2.5
  end

  it "returns a valid random index" do
    subject.rand_index.should satisfy {|x| x >= 0 && x < subject.length}
  end

  it "returns a randomly selected item" do
    subject.sample.should satisfy {|sample| subject.include?(sample)}
  end
  
  it "transforms an array of constraints into an array of periods" do
    constraints = []
    4.times {constraints << Constraint.new(:klass => 1, :teacher => 1, :room => 1)}
    expected_periods = [Period.new([constraints[0], constraints[1]]), Period.new([constraints[2], constraints[3]])]
    
    actual_periods = constraints.to_periods(2)
    actual_periods.length.should == expected_periods.length
    actual_periods.length.times do |i|
      actual_periods[i].constraints.should == expected_periods[i].constraints
    end
  end
  
  it "transforms an array of periods into an array of constraints" do
    constraints = []
    4.times {constraints << Constraint.new(:klass => 1, :teacher => 1, :room => 1)}
    periods = [Period.new([constraints[0], constraints[1]]), Period.new([constraints[2], constraints[3]])]
    expected_constraints = constraints
    
    actual_constraints = periods.to_constraints
    actual_constraints.should == expected_constraints
  end
end

describe Constraint do
  subject { Constraint.new(:klass => 1, :teacher => 2, :room => 3) }
  it "returns it's room" do
    subject.room.should == 3
  end

  it "returns it's teacher" do
    subject.teacher.should == 2
  end


  it "returns it's klass" do
    subject.klass.should == 1
  end
end

describe Period do
  before(:all) do
    @attributes = {:klass => 1, :teacher => 1, :room => 1}
    @different_attributes = {:klass => 2, :teacher => 2, :room => 2}
  end
  
  it "raises an error if no collision is present, but asked for an colliding constraint" do
    p = Period.new([Constraint.new(@attributes), Constraint.new(@different_attributes)])
    expect{p.rand_colliding_constraint_index}.to raise_error(ScriptError)
  end
  
  it "has collision if two constraints collide" do
    p = Period.new([Constraint.new(@attributes), Constraint.new(@attributes)])
    p.collision?.should be_true
    
    p = Period.new([Constraint.new(@attributes), Constraint.new(@different_attributes)])
    p.collision?.should be_false
  end
  
  it "may yield the index of a randomly chosen constraint" do
    p = Period.new([Constraint.new(@attributes), Constraint.new(@attributes)])
    p.rand_constraint_index.should satisfy {|i| i >= 0 && i < p.constraints.length}
  end
  
  it "may yield the index of a randomly chosen colliding constraint" do
    constraints = []
    all_zero = {:klass => 0, :teacher => 0, :room => 0}
    c1, c2 = Constraint.new(all_zero), Constraint.new(all_zero)
    
    constraints << c1
    100.times {|i| constraints << Constraint.new(:klass => i + 1, :teacher => i + 1, :room => i + 1)}
    constraints << c2

    period = Period.new(constraints)
    index = period.rand_colliding_constraint_index
    period.constraints[index].should satisfy {|c| c == c1 || c == c2}
  end
end

describe Individual do # TODO add tests for different granularity
  before(:all) do
    @constraints = [Constraint.new(:klass => 1, :teacher => 2, :room => 3), Constraint.new(:klass => 1, :teacher => 2, :room => 3)]
    @expected_constraint = Constraint.new(:klass => 3, :teacher => 2, :room => 1)
  end
  subject { 
    Individual.new(:current_constraints => @constraints,
    :expected_constraints => [@expected_constraint],
    :mutation => IdentityMutation.new,
    :recombination => IdentityRecombination.new,
    :number_of_slots => 1,
    :debug => true)
  }

  it "has 1 unfulfilled constraint unless only attributes are compared" do
    similar_values = {:klass => 1, :teacher => 1, :room => 1}
    individual = Individual.new(
    :current_constraints => [Constraint.new(similar_values)],
    :expected_constraints => [Constraint.new(similar_values)],
    :number_of_slots => 1,
    :debug => true
    )

    # proves that eval_unfulfilled_constraints now uses == between objects, rather their attributes
    individual.unfulfilled_constraints.should == 1
  end

  it "has 1 unfulfilled constraint" do
    subject.unfulfilled_constraints.should == 1
  end

  it "has 3 collisions" do
    subject.collisions.should == 3
  end
  
  it "has 3 collisions per constraint-combination with granularity 0" do
    individual = Individual.new(:current_constraints => @constraints * 10,
    :number_of_slots => 5,
    :granularity => 0)
    individual.collisions.should == 6 * 5 * 3 # combinations * slots * 3 per combination
  end
  
  it "has 1 collision per constraint-combination with granularity 1" do
    individual = Individual.new(:current_constraints => @constraints * 10,
    :number_of_slots => 5,
    :granularity => 1)
    individual.collisions.should == 6 * 5 * 1 # combinations * slots * 1 per combination
  end

  it "has 1 collision per slot with granularity 2" do
    individual = Individual.new(:current_constraints => @constraints * 10,
    :number_of_slots => 5,
    :granularity => 2)
    individual.collisions.should == 5
  end

  it "has a fitness of 'collisions' + 'unfulfilled_constraints'" do
    subject.fitness.should == subject.collisions + subject.unfulfilled_constraints
  end

  it "contains given constraints" do
    subject.constraints.should == @constraints
  end

  it "changes its fitness if constraints got changed and eval_fitness was called" do
    subject.constraints[1] = @expected_constraint
    subject.eval_fitness
    subject.unfulfilled_constraints.should == 0
    subject.collisions.should == 1 # teacher
    subject.fitness.should == 1
  end

  it "returns an identical copy of itself" do
    child = subject.copy

    child.should_not == subject
    child.class.should == Individual
    child.constraints.should == subject.constraints
    child.fitness == subject.fitness
  end

  it "can create child via mutation" do
    child = subject.mutate
    child.class.should == Individual
    child.should_not == subject
  end

  it "can create child via recombination" do
    child = subject.recombinate_with(subject)
    child.class.should == Individual
    child.should_not == subject
  end
end