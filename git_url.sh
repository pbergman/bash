#!/bin/bash
#
# @author Philip Bergman <pbergman@live>
#
# A function that will transform a git urls like example@example.com:foo/bar.git to
# https://example.com/foo/bar.git and opens that url in the default browser.
#
# This should work with most providers like github, gitlab gogs etc.
#
# Usage:
#
# ./git_url [remote]
#
[ -d "./.git" ] && sensible-browser $( git remote get-url ${1:-origin} | sed 's/^git@\(.\+\):/https:\/\/\1\//' )

