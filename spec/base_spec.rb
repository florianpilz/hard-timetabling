require 'base'

describe "base" do
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
      subject.should include(subject.sample)
    end
  end
  
  describe Constraint do
    it "yields the given number of rooms" do
      c = Constraint.new(:klass => 1, :teacher => 1, :room => 1)
      c.room.should == 1
    end
  end
end