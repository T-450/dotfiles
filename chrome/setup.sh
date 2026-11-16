#!/usr/bin/env bash
# chrome/setup.sh: Chrome is the default browser (web links, HTML files, super+b).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
types=(x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about x-scheme-handler/unknown
	text/html application/xhtml+xml)
default_app google-chrome.desktop "${types[@]}"
