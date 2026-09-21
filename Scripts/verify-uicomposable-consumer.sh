#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 3 ]]; then
	echo "Usage: $0 <revision|exact> <reference> <expected-revision>" >&2
	exit 1
fi

mode="$1"
reference="$2"
expected_revision="$3"

if [[ ! "$expected_revision" =~ ^[0-9a-f]{40}$ ]]; then
	echo "Expected revision must be a 40-character commit hash" >&2
	exit 1
fi

case "$mode" in
	revision)
		if [[ ! "$reference" =~ ^[0-9a-f]{40}$ ]]; then
			echo "Revision must be a 40-character commit hash" >&2
			exit 1
		fi
		;;
	exact)
		if [[ ! "$reference" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
			echo "Version must use semantic versioning such as 0.1.0" >&2
			exit 1
		fi
		;;
	*)
		echo "Unsupported dependency mode: $mode" >&2
		exit 1
		;;
esac

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/uicomposable-consumer.XXXXXX")"
trap 'rm -rf "$temporary_directory"' EXIT
fixture_directory="$temporary_directory/UIComposableConsumer"
manifest="$fixture_directory/Package.swift"

cp -R "$repository_root/Tests/IntegrationFixtures/UIComposableConsumer" "$fixture_directory"

UI_COMPOSABLE_DEPENDENCY_MODE="$mode" UI_COMPOSABLE_DEPENDENCY_REFERENCE="$reference" perl -0pi -e '
	my $mode = $ENV{UI_COMPOSABLE_DEPENDENCY_MODE};
	my $reference = $ENV{UI_COMPOSABLE_DEPENDENCY_REFERENCE};
	my $replacement = qq{.package(url: "https://github.com/opficdev/UIComposable.git", $mode: "$reference")};
	my $count = s{\.package\(path: "\.\./\.\./\.\."\)}{$replacement};
	die "Unable to replace local UIComposable dependency\n" unless $count == 1;
' "$manifest"

swift package resolve \
	--package-path "$fixture_directory" \
	--scratch-path "$temporary_directory/SwiftPM"

(
	cd "$fixture_directory"
	xcodebuild \
		-scheme UIComposableConsumer \
		-sdk iphonesimulator \
		-destination 'generic/platform=iOS Simulator' \
		-derivedDataPath "$temporary_directory/DerivedData" \
		build
)

resolved="$fixture_directory/Package.resolved"
if [[ ! -f "$resolved" ]]; then
	echo "Missing resolved package state" >&2
	exit 1
fi

resolved_revision="$(ruby -rjson -e '
	resolved = JSON.parse(File.read(ARGV.fetch(0)))
	pin = resolved.fetch("pins").find { |candidate| candidate.fetch("identity") == "uicomposable" }
	abort "Missing UIComposable resolved package" if pin.nil?
	print pin.fetch("state").fetch("revision")
' "$resolved")"

if [[ "$resolved_revision" != "$expected_revision" ]]; then
	echo "Resolved revision does not match expected revision" >&2
	exit 1
fi

if [[ "$mode" == "exact" ]]; then
	resolved_version="$(ruby -rjson -e '
		resolved = JSON.parse(File.read(ARGV.fetch(0)))
		pin = resolved.fetch("pins").find { |candidate| candidate.fetch("identity") == "uicomposable" }
		abort "Missing UIComposable resolved package" if pin.nil?
		print pin.fetch("state").fetch("version")
	' "$resolved")"

	if [[ "$resolved_version" != "$reference" ]]; then
		echo "Resolved version does not match requested version" >&2
		exit 1
	fi
fi

echo "UIComposable consumer build and resolved revision verification succeeded for $mode $reference"
