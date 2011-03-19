require 'selections'

class MockIndividual
  attr_reader :fitness
  def initialize(fitness)
    @fitness = fitness
  end
end

describe "Selections" do
  before(:all) do
    @one = MockIndividual.new(1) # best solution (least collisions)
    @two = MockIndividual.new(2)
    @three = MockIndividual.new(3)
    @four = MockIndividual.new(4)
    @five = MockIndividual.new(5)
    @six = MockIndividual.new(6)
    @seven = MockIndividual.new(7)
    @eight = MockIndividual.new(8)
    @nine = MockIndividual.new(9)
    @ten = MockIndividual.new(10) # worst solution
    @population = [@one, @two, @three, @four, @five, @six, @seven, @eight, @nine, @ten].shuffle
  end
  
  describe RankbasedRouletteWheelSelection do
    subject{ RankbasedRouletteWheelSelection.new }
    
    it "yields appropriately chosen individuals" do
      selection = subject.select(5, @population)
      selection.length.should == 5
      
      if selection.include?(@ten)
        selection.should include(@six)
        selection.should include(@four)
        selection.should include(@three)
        selection.should include(@two)
      else
        selection.should include(@one)
      end
    end
    
    it "accepts an option hash" do
      subject.select(5, @population, {}).length.should == 5
    end
  end
  
  describe BestSelection do
    subject{ BestSelection.new }
    
    it "yields appropriately chosen individuals" do
      selection = subject.select(5, @population)
      selection.length.should == 5
      selection.should == [@one, @two, @three, @four, @five]
    end
    
    it "accepts an option hash" do
      subject.select(5, @population, {}).length.should == 5
    end
  end
  
  describe NStageTournamentSelection do
    subject { NStageTournamentSelection.new }
    
    it "yields appropriately chosen individuals" do
      selection = subject.select(5, @population, {:stages => 2})
      selection.length.should == 5
      selection.should_not include(@ten) # may fail if (nearly) every individual won 0 times
      selection.should == selection.uniq # no duplicates
      selection.each do |individual|
        individual.class.should == MockIndividual
      end
    end
    
    it "accepts an option hash" do
      options = {:stages => 1}
      subject.select(5, @population, options).length.should == 5
    end
  end

  describe UniformSelection do
    subject { UniformSelection.new }
    
    it "yields appropriately chosen individuals" do
      selection = subject.select(5, @population)
      selection.length.should == 5
      selection.each do |individual|
        individual.class.should == MockIndividual
      end
    end
    
    it "accepts an option hash" do
      subject.select(5, @population, {}).length.should == 5
    end
  end
end