class Recombination
  def to_s
    self.class.to_s
  end
end

class IdentityRecombination < Recombination
  def call(individual1, individual2)
    [individual1.copy, individual2.copy]
  end
end