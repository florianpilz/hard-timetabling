watch('spec/.*_spec\.rb') {|match| system "rspec -c spec/" }
watch('.*\.rb') {|match| system "rspec -c spec/" }

