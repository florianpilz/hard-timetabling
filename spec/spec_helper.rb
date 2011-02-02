require 'base'
require 'mutations'
require 'recombinations'

class Fixnum
  def fak_sum
    self == 0 ? 0 : self + (self - 1).fak_sum
  end
end

SLOTS = 100
SLOT_SIZE = 2
MAX_COLLISIONS = SLOTS * (SLOT_SIZE - 1).fak_sum * 3

def individual_generator(mutation = IdentityMutation.new, recombination = IdentityRecombination.new)
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
  subject{ individual_generator }
  it "has as many collisions as possible" do
    subject.collisions.should == MAX_COLLISIONS
  end
end