require 'spec_helper'

describe "Mutations" do
  before(:all) do
    @all_mutations_enhanced_fitness = []
  end

  after(:all) do
    puts "\nAll Mutations enhanced fitness!" if @all_mutations_enhanced_fitness.all?
  end
  
  describe IdentityMutation do
    subject{ individual_generator(:mutation => IdentityMutation.new) }    
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
        individual = individual_generator(:mutation => klass.new)
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