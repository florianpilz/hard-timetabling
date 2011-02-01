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

describe Individual do
  before(:all) do
    @constraints = [Constraint.new(:klass => 1, :teacher => 2, :room => 3), Constraint.new(:klass => 1, :teacher => 2, :room => 3)]
    @expected_constraint = Constraint.new(:klass => 3, :teacher => 2, :room => 1)
  end
  subject { 
    Individual.new(:current_constraints => @constraints,
    :expected_constraints => [@expected_constraint],
    :mutation => IdentityMutation.new,
    :recombination => IdentityRecombination.new,
    :slot_size => 2,
    :number_of_slots => 1,
    :debug => true)
  }

  it "has 1 unfulfilled constraint unless only attributes are compared" do
    similar_values = {:klass => 1, :teacher => 1, :room => 1}
    individual = Individual.new(
    :current_constraints => [Constraint.new(similar_values)],
    :expected_constraints => [Constraint.new(similar_values)],
    :slot_size => 1,
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

  it "can create two childs via recombination" do
    child1, child2 = subject.recombinate_with(subject)
    [child1, child2].each do |child|
      child.class.should == Individual
      child.should_not == subject
    end
  end
end