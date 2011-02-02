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
SLOT_SIZE = 2
MAX_COLLISIONS = SLOTS * (SLOT_SIZE - 1).fak_sum * 3

def individual_generator(mutation)
  constraints = []
  (SLOTS * SLOT_SIZE).times {|i| constraints << Constraint.new(:klass => i / SLOT_SIZE, :teacher => i / SLOT_SIZE, :room => i / SLOT_SIZE)}

  Individual.new(
    :current_constraints => constraints,
    :expected_constraints => constraints,
    :mutation => mutation,
    :recombination => IdentityRecombination.new,
    :number_of_slots => SLOTS,
    :debug => true
  )
end

describe "individual_generator" do
  subject{ individual_generator(IdentityMutation.new) }
  it "has as many collisions as possible" do
    subject.collisions.should == MAX_COLLISIONS
  end
end

describe "Mutations" do
  before(:all) do
    @all_mutations_enhanced_fitness = []
  end

  after(:all) do
    puts "\nAll Mutations enhanced fitness!" if @all_mutations_enhanced_fitness.all?
  end
  
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
  
  describe "fitness-changing mutations" do
    subject{ [DumbSwappingMutation, CollidingConstraintsSwapperMutation, InvertingMutation, InvertingWithCollisionMutation, MixingMutation, SwappingWithCollidingPeriodMutation, SwappingWithCollidingConstraintMutation, DumbTripleSwapperMutation, DumbTripleSwapperMutation, TripleSwapperWithTwoCollidingPeriodsMutation, TripleSwapperWithTwoCollidingConstraintsMutation] }
    it "generates a child with the same constraint-permutation" do
      subject.each do |klass|
        individual = individual_generator(klass.new)
        child = individual.mutate
        child.class == Individual
        child.should_not == individual
        child.unfulfilled_constraints.should == 0 # check for permutation
        child.fitness.should <= individual.fitness
        @all_mutations_enhanced_fitness << (child.fitness != individual.fitness)
      end
    end
    
    it "returns its class as name" do
      subject.each do |klass|
        klass.new.to_s.should == klass.to_s
      end
    end
  end
end