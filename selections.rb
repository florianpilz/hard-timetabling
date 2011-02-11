class Selection
end

class RankbasedStochasticUniversalSamplingSelection < Selection
  def select(x, population)
    sorted_population = population.sort_by(&:fitness).reverse
    sums = []
    sum = 0
    sorted_population.each_with_index do |individual, i|
      sum += i + 1 # use position + 1 as fitness
      sums << {:individual => individual, :sum => sum}
    end
    
    u = rand * sum / x.to_f
    u = rand * sum / x.to_f while u == sum / x.to_f
    j = 0
    selection = []
    x.times do
      j += 1 while sums[j][:sum] < u
      u += sum / x.to_f
      selection << sums[j][:individual]
    end
    selection
  end
end