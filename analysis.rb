require 'ostruct'
require 'base'

folder = "all-output"

significance_by_degrees_of_freedom = []
significance_by_degrees_of_freedom[4] = 2.777
significance_by_degrees_of_freedom[5] = 2.571
significance_by_degrees_of_freedom[8] = 2.306
significance_by_degrees_of_freedom[9] = 2.262
significance_by_degrees_of_freedom[10] = 2.228
significance_by_degrees_of_freedom[11] = 2.201
significance_by_degrees_of_freedom[12] = 2.179
significance_by_degrees_of_freedom[13] = 2.160
significance_by_degrees_of_freedom[14] = 2.145
significance_by_degrees_of_freedom[15] = 2.131
significance_by_degrees_of_freedom[16] = 2.120
significance_by_degrees_of_freedom[17] = 2.110
significance_by_degrees_of_freedom[18] = 2.101
significance_by_degrees_of_freedom[19] = 2.093
significance_by_degrees_of_freedom[20] = 2.086
significance_by_degrees_of_freedom[21] = 2.080
significance_by_degrees_of_freedom[22] = 2.074
significance_by_degrees_of_freedom[23] = 2.069
significance_by_degrees_of_freedom[24] = 2.064
significance_by_degrees_of_freedom[25] = 2.060
significance_by_degrees_of_freedom[26] = 2.056
significance_by_degrees_of_freedom[27] = 2.052
significance_by_degrees_of_freedom[28] = 2.048
significance_by_degrees_of_freedom[29] = 2.045
significance_by_degrees_of_freedom[30] = 2.042
significance_by_degrees_of_freedom[31] = 2.040
significance_by_degrees_of_freedom[32] = 2.037
significance_by_degrees_of_freedom[34] = 2.032
significance_by_degrees_of_freedom[35] = 2.030
significance_by_degrees_of_freedom[36] = 2.028
significance_by_degrees_of_freedom[37] = 2.026
significance_by_degrees_of_freedom[38] = 2.024
significance_by_degrees_of_freedom[39] = 2.023
significance_by_degrees_of_freedom[41] = 2.020
significance_by_degrees_of_freedom[43] = 2.017
significance_by_degrees_of_freedom[44] = 2.015
significance_by_degrees_of_freedom[45] = 2.014
significance_by_degrees_of_freedom[46] = 2.013
significance_by_degrees_of_freedom[50] = 2.009
significance_by_degrees_of_freedom[51] = 2.008
significance_by_degrees_of_freedom[52] = 2.007
significance_by_degrees_of_freedom[54] = 2.005
significance_by_degrees_of_freedom[55] = 2.004
significance_by_degrees_of_freedom[57] = 2.002
significance_by_degrees_of_freedom[60] = 2.000
significance_by_degrees_of_freedom[62] = 1.999
significance_by_degrees_of_freedom[66] = 1.997
significance_by_degrees_of_freedom[68] = 1.995
significance_by_degrees_of_freedom[73] = 1.993
significance_by_degrees_of_freedom[80] = 1.990
significance_by_degrees_of_freedom[88] = 1.987
significance_by_degrees_of_freedom[89] = 1.987
significance_by_degrees_of_freedom[92] = 1.986
significance_by_degrees_of_freedom[93] = 1.986
significance_by_degrees_of_freedom[95] = 1.985
significance_by_degrees_of_freedom[98] = 1.984
significance_by_degrees_of_freedom[100] = 1.984
significance_by_degrees_of_freedom[101] = 1.984
significance_by_degrees_of_freedom[102] = 1.983
significance_by_degrees_of_freedom[104] = 1.983
significance_by_degrees_of_freedom[105] = 1.983
significance_by_degrees_of_freedom[106] = 1.983
significance_by_degrees_of_freedom[108] = 1.982
significance_by_degrees_of_freedom[111] = 1.982
significance_by_degrees_of_freedom[112] = 1.981
significance_by_degrees_of_freedom[113] = 1.981
significance_by_degrees_of_freedom[117] = 1.980
significance_by_degrees_of_freedom[118] = 1.980
significance_by_degrees_of_freedom[119] = 1.980
significance_by_degrees_of_freedom[124] = 1.979
significance_by_degrees_of_freedom[131] = 1.978
significance_by_degrees_of_freedom[134] = 1.978
significance_by_degrees_of_freedom[147] = 1.976
significance_by_degrees_of_freedom[185] = 1.973
significance_by_degrees_of_freedom[193] = 1.972
significance_by_degrees_of_freedom[198] = 1.972

files = `ls #{folder}/`.split("\n")
hdtt_all_files = []
(4..8).to_a.each do |i|
  short = "a"
  hdtt_files = files.grep(/^.*#{i}\.txt$/)
  next if i > 4 && hdtt_files.length != hdtt_all_files[0].length
  hdtt_files.map! do |file|
    file_data = OpenStruct.new
    file_data.name = file
    
    content = File.read("#{folder}/#{file}").split("\n")
    data = []
    content.each_with_index do |line, index|
      next unless line.include?("finished")
      d = OpenStruct.new
      if content[index - 1].include?("Evaluations")
        content[index - 1].scan(/^(?:Iterations: \d*), Evaluations: (\d*), Collisions: (\d*), Time: (\d*\.\d*), Diversity: (\d*\.\d*)$/) do |i, c, t, div|
          d.iterations, d.collisions, d.time, d.diversity = [i.to_i, c.to_i, t.to_f, div.to_f]
        end
      else
        content[index - 1].scan(/^Iterations: (\d*), Collisions: (\d*), Time: (\d*\.\d*), Diversity: (\d*\.\d*)$/) do |i, c, t, div|
          d.iterations, d.collisions, d.time, d.diversity = [i.to_i, c.to_i, t.to_f, div.to_f]
        end
      end
      data << d
    end
    
    file_data.time_score = 0
    file_data.collisions_score = 0
    file_data.short = short.dup
    short.succ!
    file_data.samples = content.grep(/finished/).length
    file_data.percentage_finished = content.grep("=== finished").length.to_f / file_data.samples.to_f
    
    file_data.time_expected = data.collect(&:time).mean
    file_data.time_variance = 1 / (data.length - 1).to_f * data.inject(0.0) do |sum, d|
       sum += (d.time.to_f - file_data.time_expected.to_f) ** 2
    end
    
    file_data.collisions_expected = data.collect{|x| x.collisions.to_f}.mean
    file_data.collisions_variance = 1 / (data.length - 1).to_f * data.inject(0.0) do |sum, d|
       sum += (d.collisions.to_f - file_data.collisions_expected.to_f) ** 2
    end
    
    div_expected = data.collect{|x| x.diversity.to_f}.mean
    div_variance = 1 / (data.length - 1).to_f * data.inject(0.0) do |sum, d|
       sum += (d.diversity.to_f - div_expected.to_f) ** 2
    end
    
    puts ((file_data.percentage_finished * 100.0).round / 100.0).to_s << " " << ((file_data.collisions_expected * 1000.0).round / 1000.0).to_s << " " << ((file_data.collisions_variance * 1000.0).round / 1000.0).to_s << " " << file_data.name
    puts file_data.samples.to_s << " " << file_data.time_expected.round.to_s << " " << file_data.time_variance.round.to_s << " " << file_data.name
    puts "muh " << ((div_expected * 1000.0).round / 1000.0).to_s << " " << ((div_variance * 1000.0).round / 1000.0).to_s << " " << file_data.name
    file_data
  end
  hdtt_all_files << hdtt_files
  puts ""
end

hdtt_all_files.each do |files|
  files.each do |file1|
    files.each do |file2|
      next if file1 == file2
      raise ArgumentError, "No Significance Value found for #{file1.samples + file2.samples - 2}" if significance_by_degrees_of_freedom[file1.samples + file2.samples - 2].nil?
      
      if file1.time_expected < file2.time_expected # fewer is better (collisions, time, evaluations)
        delta = 1
      elsif file1.time_expected == file2.time_expected
        delta = 0
      else
        delta = -1
      end
      
      s = ((file1.samples - 1) * file1.time_variance + (file2.samples - 1) * file2.time_variance) / (file1.samples + file2.samples - 2).to_f
      t_value = ((file1.time_expected - file2.time_expected).to_f / Math.sqrt(s)) * Math.sqrt((file1.samples * file2.samples).to_f / (file1.samples + file2.samples).to_f)      
      t_value = 0.0 if t_value.nan?
      file1.time_score += delta if t_value.abs > significance_by_degrees_of_freedom[file1.samples + file2.samples - 2]
      
      if file1.collisions_expected < file2.collisions_expected # fewer is better (collisions, time, evaluations)
        delta = 1
      elsif file1.collisions_expected == file2.collisions_expected
        delta = 0
      else
        delta = -1
      end
      
      s = ((file1.samples - 1) * file1.collisions_variance + (file2.samples - 1) * file2.collisions_variance) / (file1.samples + file2.samples - 2).to_f
      t_value = ((file1.collisions_expected - file2.collisions_expected).to_f / Math.sqrt(s)) * Math.sqrt((file1.samples * file2.samples).to_f / (file1.samples + file2.samples).to_f)
      t_value = 0.0 if t_value.nan?
      file1.collisions_score += delta if t_value.abs > significance_by_degrees_of_freedom[file1.samples + file2.samples - 2]
    end
    # puts file1.score.to_s << "\t" << file1.short << " - " << file1.name
  end
  sorted_files = files.sort_by do |file|
    [file.collisions_score, file.time_score]
  end.reverse
  sorted_files.each_index do |i|
    if i == 0
      print sorted_files[i].name.sub(/\d\.txt/, "").gsub(/[a-z]/, "")
      # print sorted_files[i].short
      next
    end
    
    if sorted_files[i].collisions_score == sorted_files[i - 1].collisions_score && sorted_files[i].time_score == sorted_files[i - 1].time_score
      print " = " << sorted_files[i].name.sub(/\d\.txt/, "").gsub(/[a-z]/, "")
      # print " = " << sorted_files[i].short
    else
      print " > " << sorted_files[i].name.sub(/\d\.txt/, "").gsub(/[a-z]/, "")
      # print " > " << sorted_files[i].short
    end
  end
  puts ""
end