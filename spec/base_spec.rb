require 'base'

describe Constraint do
  describe "attributes" do
    it "yields the given number of rooms" do
      c = Constraint.new(:klass => 1, :teacher => 1, :room => 1)
      c.room.should == 1
    end
  end
end