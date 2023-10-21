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

if ! [ -z "$(sc git status --porcelain)" ]; then
    echo 'sc git working tree not clean'
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

doc_validation_errors=$(sc tidy -errors -q docs/index.html 2>&1 | grep -v -- ' - Warning: ') ||:
if ! [ -z "$doc_validation_errors" ]; then
    echo "docs/index.html contains invalid html:\n${doc_validation_errors}"
    exit 1
fi
echo 'validate html'
pause

echo 'update shard.yml version (no commit)'
pause

version=$(shards version)

rm -f ahk_x11.AppImage bin/ahk_x11 bin/ahk_x11.dev
docker run --rm -it -v /b/ahk_x11:/a -w /a --privileged ahk_x11-builder-ubuntu.20.04 \
    make ahk_x11.AppImage

bin=ahk_x11.AppImage
cp "$bin" "$bin.release"
ls -la "$bin"
pause

make ahk_x11.deb
bin_deb="ahk-x11_${version}-1_all.deb"
ls -la "$bin_deb"
pause

make test-appimage
pause

echo test installers
pause

sc git fetch
release_message=$(sc git log --reverse "$(sc git describe --tags --abbrev=0)".. --pretty=format:"%h___%B" |grep . |sed -E 's/^([0-9a-f]{6,})___(.)/- [`\1`](https:\/\/github.com\/phil294\/ahk_x11\/commit\/\1) \U\2/')

echo edit release message
pause
release_message=$(micro <<< "$release_message")
[ -z "$release_message" ] && exit 1
echo release_message:
echo "$release_message"

sc git add README.md ||:
sc git add shard.yml
sc git commit -m "$version"
sc git tag "$version"
echo 'committed, tagged'
pause

sc git push --tags origin master

if [[ -z $version || -z $release_message ]]; then
    echo version/release_message empty
    exit 1
fi
echo 'will create github release'
pause
gh release create "$version" --target master --title "$version" --notes "$release_message" --verify-tag "$bin" "$bin_deb"
echo 'github release created'

echo 'update dependent projects'
pause