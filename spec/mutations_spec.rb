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
    
    it "returns its class as name" do
      IdentityMutation.new.to_s.should == IdentityMutation.to_s
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
  
  describe CollidingPeriodsSwapperMutation do
    subject{ individual_generator(CollidingPeriodsSwapperMutation.new) }
    it "generates a child with a better fitness" do
      child = subject.mutate
      child.class == Individual
      child.should_not == subject
      child.fitness.should < subject.fitness
    end
  end
end