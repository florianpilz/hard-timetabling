require 'selections'

class MockIndividual
  attr_reader :fitness
  def initialize(fitness)
    @fitness = fitness
  end
end

describe "Selections" do
  describe RankbasedStochasticUniversalSamplingSelection do
    subject{ RankbasedStochasticUniversalSamplingSelection.new }
    
    it "yields an appropriate amount of individuals" do
      one = MockIndividual.new(1) # best solution (least collisions)
      two = MockIndividual.new(2)
      three = MockIndividual.new(3)
      four = MockIndividual.new(4)
      five = MockIndividual.new(5)
      six = MockIndividual.new(6)
      seven = MockIndividual.new(7)
      eight = MockIndividual.new(8)
      nine = MockIndividual.new(9)
      ten = MockIndividual.new(10) # worst solution
      population = [one, two, three, four, five, six, seven, eight, nine, ten].shuffle
      
      selection = subject.select(5, population)
      
      if selection.include?(ten)
        selection.should include(six)
        selection.should include(four)
        selection.should include(three)
        selection.should include(two)
      else
        selection.should include(one)
      end
    end
  end
end