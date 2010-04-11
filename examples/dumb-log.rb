#! /usr/local/bin/macruby
require 'common'

# simple example of getting the head

r = GITRepo.repoWithRoot(@test_repo)

# TODO: commit = r.commitFromRef("master")

shaHash = GITObjectHash.objectHashWithString("ca82a6dff817ec66f44342007202690a93763949")
commit = r.objectWithSha1(shaHash, error:@err)

@enum = GITCommitEnumerator.enumeratorFromCommit(commit)
@objs = @enum.allObjects  # creates a new array by iterating -nextObject until it gets nil
@shas = @objs.each do |commit|
  puts "SHA1  : " + commit.sha1.unpackedString
  puts "Tree  : " + commit.tree.sha1.unpackedString
  puts "Author: " + commit.author.name + " <" + commit.author.email + ">"
  puts "Date  : " + commit.authorDate.date.description
  puts
  puts commit.message
  puts
  puts
end

# TODO: doesn't get the initial commit