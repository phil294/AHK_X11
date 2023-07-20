#!/bin/bash

# Semi-automated script to create a new release, including generating changelog, tag, building etc.
# Adopted from https://github.com/phil294/git-log--graph/blob/master/release.sh

set -e
set -o pipefail

pause() {
    read -r -n 1 -s -p 'Press any key to continue. . .'
    echo
}

echo update readme
pause

if ! [ -z "$(git status --porcelain)" ]; then
    echo 'git working tree not clean'
    exit 1
fi

if grep -R -n -E '\s$' src; then
    echo 'trailing whitespace found'
    exit 1
fi
if grep -R -n 'p! ' src; then
    echo 'p! found'
    exit 1
fi

doc_validation_errors=$(tidy -errors -q docs/index.html 2>&1 | grep -v -- ' - Warning: ') ||:
if ! [ -z "$doc_validation_errors" ]; then
    echo "docs/index.html contains invalid html:\n${doc_validation_errors}"
    exit 1
fi
echo 'validate html'
pause

echo 'update shard.yml version (no commit)'
pause

version=$(shards version)

docker run --rm -it -v /b/ahk_x11:/a --privileged ahk_x11-builder-ubuntu.20.04 bash -c \
    'cd /a/build && ./build.sh --release'

bin=$(ls -tr build/*.AppImage | tail -1)
cp "$bin" "$bin.release"
echo "$bin"
pause

"$bin" ./tests.ahk
pause

git fetch
release_message=$(git log --reverse "$(git describe --tags --abbrev=0)".. --pretty=format:"%h___%B" |grep . |sed -E 's/^([0-9a-f]{6,})___(.)/- [`\1`](https:\/\/github.com\/phil294\/ahk_x11\/commit\/\1) \U\2/')

echo edit release message
pause
release_message=$(micro <<< "$release_message")
[ -z "$release_message" ] && exit 1
echo release_message:
echo "$release_message"

git add README.md ||:
git add shard.yml
git commit -m "$version"
git tag "$version"
echo 'committed, tagged'
pause

git push --tags origin master

if [[ -z $version || -z $release_message ]]; then
    echo version/release_message empty
    exit 1
fi
echo 'will create github release'
pause
gh release create "$version" --target master --title "$version" --notes "$release_message" --verify-tag "$bin"
echo 'github release created'

echo 'update dependent projects'
pause