require 'mutations'

describe Period do
  before(:all) do
    @attributes = {:klass => 1, :teacher => 1, :room => 1}
    @different_attributes = {:klass => 2, :teacher => 2, :room => 2}
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