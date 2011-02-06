require 'rubygems'
require 'gruff'

class Array
  def second
    self[1]
  end
end

class LineStatistic
  attr_accessor :iterations, :collisions, :time

  def initialize(iterations, collisions, time)
    @iterations = iterations
    @collisions = collisions
    @time = time
  end
end

def calculate_statistic(filename)
  content = File.read("output/" + filename)
  lines = content.split("\n")

  results = []
  lines.each do |line|
    next if line.include?("===")
    match = line.match(/^Iterations: (\d*), Collisions: (\d*), Time: (.*), Diversity: (.*)$/)
    iterations = match[1].to_i
    collisions = match[2].to_i
    time = match[3].to_f
    results[collisions] ||= []
    results[collisions] << LineStatistic.new(iterations, collisions, time)
  end

  time_per_collision_results = []
  iterations_per_collision_results = []
  results.each_with_index do |result, i|
    next if result.nil?
    time_per_collision = 0
    iterations_per_collision = 0
    result.each do |line_statistic|
      time_per_collision += line_statistic.time
      iterations_per_collision += line_statistic.iterations
    end
    time_per_collision = time_per_collision / result.length.to_f
    iterations_per_collision = iterations_per_collision / result.length.to_f
    time_per_collision_results[i] = time_per_collision
    iterations_per_collision_results[i] = iterations_per_collision
  end
  [iterations_per_collision_results, time_per_collision_results]
end

files_hddt4 = [
  ["CollidingConstraintsSwapperMutation4.txt", "CCS"],
  ["DumbSwappingMutation4.txt", "DS"],
  ["DumbTripleSwapperMutation4.txt", "DTS"],
  ["InvertingMutation4.txt", "I"],
  ["InvertingWithCollisionMutation4.txt", "IWC"],
  ["MixingMutation4.txt", "M"],
  ["ShiftingMutation4.txt", "S"],
  ["SwappingWithCollidingConstraintMutation4.txt", "SWCC"],
  ["SwappingWithCollidingPeriodMutation4.txt", "SWCP"],
  ["TripleSwapperWithTwoCollidingConstraintsMutation4.txt", "TSWTCC"],
  ["TripleSwapperWithTwoCollidingPeriodsMutation4.txt", "TSWTCP"],
]

hddt4_iterations_per_collision = []
hddt4_time_per_collision = []
files_hddt4.each do |filename|
  iterations_per_collision, time_per_collision = calculate_statistic(filename.first)
  hddt4_iterations_per_collision << iterations_per_collision
  hddt4_time_per_collision << time_per_collision
end

hddt4_max_collision = hddt4_time_per_collision.inject(0) do |max, x|
  max_of_array = x.index(x.last)
  max = (max_of_array > max) ? max_of_array : max
end

temp = hddt4_iterations_per_collision.inject(0) do |max, x|
  max_of_array = x.index(x.last)
  max = (max_of_array > max) ? max_of_array : max
end

hddt4_max_collision = (temp > hddt4_max_collision) ? temp : hddt4_max_collision

hdtt4_labels = {}
(0..hddt4_max_collision/20).to_a.map do |x|
  hdtt4_labels[x * 20] = (x * 20).to_s #(hddt4_max_collision / 20 * 20 - x * 20).to_s
end

#################################
g = Gruff::Line.new
g.title = "Time per Collision" 
g.x_axis_label = "Collisions"
g.y_axis_label = "Time"
# g.theme = {
#   :background_colors => "transparent"
# }
files_hddt4.each_with_index do |filename, i|
  g.data(filename.second, hddt4_time_per_collision[i].compact)
end
g.labels = hdtt4_labels
g.write('output/time_per_collision4.png')
#################################
g = Gruff::Line.new
g.title = "Iterations per Collision" 
g.x_axis_label = "Collisions"
g.y_axis_label = "Iterations"
files_hddt4.each_with_index do |filename, i|
  g.data(filename.second, hddt4_iterations_per_collision[i].compact)
end
g.labels = hdtt4_labels
g.write('output/iterations_per_collision4.png')