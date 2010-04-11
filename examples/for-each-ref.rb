#! /usr/local/bin/macruby
require 'common'

# simple example of getting the head

r = GITRepo.repoWithRoot(@test_repo)
r.branches.each do |branch|
  pp branch.name
  c = branch.ref.target # this is broken - supposed to return the commit object

  puts sha = branch.ref.targetName.strip
  shaHash = GITObjectHash.objectHashWithString(sha)
  c = r.objectWithSha1(shaHash, error:@err)

  puts c.parents
  puts c.tree
  puts c.author
  puts c.committer
  puts c.authorDate
  puts c.committerDate
  puts c.message
  puts c.treeSha1
  puts c.parentShas
  puts c.cachedData
end
