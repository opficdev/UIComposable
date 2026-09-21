#!/usr/bin/env bash

set -euo pipefail

built_products_directory="$1"
sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"

xcrun swiftc \
    -typecheck \
    -target arm64-apple-ios17.0-simulator \
    -sdk "$sdk_path" \
    -I "$built_products_directory" \
    Tests/UIComposableCompileFixtures/ComposableUIView.swift

for fixture in Tests/UIComposableCompileFailureFixtures/*.swift; do
    case "$fixture" in
        *NonComposableUIView.swift)
            expected_diagnostic="has no member 'composable'"
            ;;
        *NonisolatedComposableView.swift)
            expected_diagnostic="main actor-isolated"
            ;;
    esac

    if diagnostics="$(xcrun swiftc \
        -typecheck \
        -target arm64-apple-ios17.0-simulator \
        -sdk "$sdk_path" \
        -I "$built_products_directory" \
        "$fixture" 2>&1)"; then
        echo "Expected compilation to fail: $fixture" >&2
        exit 1
    fi

    if ! grep -Fq "$expected_diagnostic" <<<"$diagnostics"; then
        echo "Expected diagnostic was not emitted: $fixture" >&2
        echo "$diagnostics" >&2
        exit 1
    fi
done
