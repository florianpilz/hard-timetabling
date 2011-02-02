require 'spec_helper'

describe "Recombinations" do
  before(:all) do
    @all_recombinations_enhanced_fitness = []
  end

  after(:all) do
    puts "\nAll Recombinations enhanced fitness!" if @all_recombinations_enhanced_fitness.all?
  end
  
  describe IdentityRecombination do
    subject { individual_generator(:recombination => IdentityRecombination.new) }
    
    it "generates two childs with the same constraint-permutation" do
      child1, child2 = subject.recombinate_with(subject)
      [child1, child2].each do |child|
        child.should_not == subject
        child.class.should == Individual
        child.constraints.should == subject.constraints
      end
    end
    
    it "returns its class as name" do
      IdentityRecombination.new.to_s.should == IdentityRecombination.to_s
    end
  end
  
  describe OrderingRecombination do
    it "generates valid childs with constraint-permutations" do
      individual1 = individual_generator(:recombination => OrderingRecombination.new)
      individual2 = individual1.copy
      individual2.constraints.shuffle!
      
      child1, child2 = individual1.recombinate_with(individual2)
      [child1, child2].each do |child|
        child.class.should == Individual
        child.should_not == individual1
        child.should_not == individual2
        child.unfulfilled_constraints.should == 0
        child.constraints.length.should == individual1.constraints.length
        @all_recombinations_enhanced_fitness << (child.fitness < individual1.fitness && child.fitness < individual2.fitness)
      end
    end
    
    it "returns its class as name" do
      OrderingRecombination.new.to_s.should == OrderingRecombination.to_s
    end
  end
end