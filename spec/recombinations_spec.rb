require 'spec_helper'

describe "Recombinations" do
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
end