# Rules borrowed from:
# https://hackernoon.com/dont-be-the-bad-cop-in-pull-request-reviews-let-software-do-that-job-1eb9e574c2d1
# https://github.com/realm/jazzy/blob/master/Dangerfile

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ~ Variables                                                              ~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
has_app_changes = !git.modified_files.grep(/^Sources\//).empty?
has_test_changes = !git.modified_files.grep(/^Tests\//).empty?


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ~ Required or suggested changes                                          ~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#
#  Rule: Exactly 1 reviewer is required.
#  Reason: No reviewer tends to leave a PR in a state where nobody is
#          responsible. Similarly, more than 1 reviewer doesn't clearly state
#          who is responsible for the review.
#
requested_reviewers = github.pr_json[:requested_reviewers]
reviewersCount = requested_reviewers.length
if reviewersCount == 0
  fail("🕵 Whoops, I don't see any reviewers. Remember to add one.")
else
  message("✅ Looks like you have enough reviewers selected.")
end

# Make it more obvious that a PR is a work in progress and/or shouldn't be merged yet
# github.pr_json[:labels].each do |label|
#   if label[:name] == "WIP"
#     warn("PR is classed as Work in Progress")
#   elsif label[:name] == "DO NOT MERGE"
#     warn("PR is classed as Do Not Merge")
#   end
# end

# App changes without tests
if has_app_changes && !has_test_changes
    warn "This PR likely needs tests. \
    If you believe that this is an exception, simply add a comment to your PR explaining why you think this PR warrants an exception. \
    A common exception for not adding tests is if you're refactoring code without adding any functionality."
end



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ~ Achievemnts                                                            ~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#
#  Rule: Celebrate PRs that remove more code than they add.
#  Reason: Less is more!
#
if github.pr_json[:deletions] > github.pr_json[:additions]
  message(
    "👏 Great jorb! I see more lines deleted than added. Thanks for keeping us lean!"
  )
end