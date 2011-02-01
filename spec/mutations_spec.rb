# tests period and if every mutation can be run
# does not test the behaviour of a mutation

require 'base'
require 'mutations'

class Fixnum
  def fak_sum
    self == 0 ? 0 : self + (self - 1).fak_sum
  end
end

SLOTS = 100
SLOT_SIZE = 3
MAX_COLLISIONS = SLOTS * (SLOT_SIZE - 1).fak_sum * 3

def individual_generator(mutation)
  constraints = []
  (SLOTS * SLOT_SIZE).times {|i| constraints << Constraint.new(:klass => i / SLOT_SIZE, :teacher => i / SLOT_SIZE, :room => i / SLOT_SIZE)}

  Individual.new(
    :current_constraints => constraints,
    :expected_constraints => constraints,
    :mutation => mutation,
    :recombination => IdentityRecombination.new,
    :slot_size => SLOT_SIZE,
    :number_of_slots => SLOTS
  )
end

describe "individual_generator" do
  subject{ individual_generator(IdentityMutation.new) }
  it "has as many collisions as possible" do
    subject.collisions.should == MAX_COLLISIONS
  end
end

describe "Mutations" do
  describe IdentityMutation do
    subject{ individual_generator(IdentityMutation.new) }    
    it "generates a child with the same constraint-permutation" do
      child = subject.mutate
      child.class.should == Individual
      child.should_not == subject
      child.constraints.should == subject.constraints
    end
  end
  
  describe DumbSwappingMutation do
    subject{ individual_generator(DumbSwappingMutation.new) }
    it "generates a child with a better fitness" do
      child = subject.mutate
      child.class == Individual
      child.should_not == subject
      child.fitness.should < subject.fitness
    end
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