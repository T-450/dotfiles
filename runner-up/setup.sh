#!/usr/bin/env bash
# runner-up/setup.sh: install the pinned runner-up and the KVM places' base image (idempotent).
# runner-up isn't packaged for Arch; the release archive and the Arch cloud image are checked
# against the SHA-256s pinned here. Bump both together with config.json when updating.
set -euo pipefail
version=v0.1.12
sha=d2f1baf41eda70827178e3117ea109aa39623c5fcd588734db72b5fff0c35c31 # runner-up-$version-linux-amd64.tar.gz
image=Arch-Linux-x86_64-cloudimg-20261101.620452.qcow2
image_url=https://geo.mirror.pkgbuild.com/images/v20261101.620452/$image
image_sha=794eb4889b39e1f0ed7d5ae998b2a1ed2137db8cf8c3476cf2962c7437ecb003
bin=$HOME/.local/bin/runner-up
images=$HOME/.local/share/runner-up/images

if ! gh auth status >/dev/null 2>&1; then
	echo "skip    runner-up: gh is not signed in (gh auth login), so it can't serve; re-run after"
	exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if [[ $("$bin" version 2>/dev/null) != "$version" ]]; then
	f=runner-up-$version-linux-amd64.tar.gz
	curl -fsSL -o "$tmp/$f" "https://github.com/kunchenguid/runner-up/releases/download/$version/$f"
	echo "$sha  $tmp/$f" | sha256sum -c --quiet -
	tar xzf "$tmp/$f" -C "$tmp" runner-up
	install -Dm755 "$tmp/runner-up" "$bin"
	echo "install $bin $version"
fi

mkdir -p "$images"
if [[ ! -f $images/$image ]]; then
	echo "fetch   $image_url" && curl -fsSL -o "$images/$image.part" "$image_url"
	echo "$image_sha  $images/$image.part" | sha256sum -c --quiet -
	mv "$images/$image.part" "$images/$image"
	echo "image   $images/$image"
fi

# keep the coordinator running while logged out
[[ $(loginctl show-user "$USER" -p Linger --value 2>/dev/null) == yes ]] || loginctl enable-linger "$USER"
