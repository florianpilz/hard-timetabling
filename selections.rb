require 'ostruct'

class Selection
end

class RankbasedRouletteWheelSelection < Selection
  def select(x, population, options = {})
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

class BestSelection < Selection
  def select(x, population, options = {})
    population.sort_by(&:fitness).take(x)
  end
end

class NStageTournamentSelection < Selection
  def select(x, population, options = {:tournaments => 2})
    scores = []
    population.each do |individual|
      tournament_results = OpenStruct.new
      tournament_results.individual = individual
      tournament_results.wins = 0
      scores << tournament_results
      
      options[:tournaments].times do
        tournament_results.wins += 1 if individual.fitness < population.sample.fitness
      end
    end

    scores.sort_by(&:wins).reverse.take(x).map(&:individual)
  end
end

class UniformSelection < Selection
  def select(x, population)
    selection = []
    x.times { selection << population.sample }
    selection
  end
end