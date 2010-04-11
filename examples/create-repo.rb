#! /usr/local/bin/macruby
require 'common'

FileUtils.rm_r("/tmp/test.git") rescue nil

GITRepo.initGitRepo("/tmp/test.git")
r = GITRepo.repoWithRoot("/tmp/test.git")

if r
  puts "PASS"
else
  puts "FU"
end