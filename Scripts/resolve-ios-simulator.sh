#!/usr/bin/env bash

set -euo pipefail

xcrun simctl list devices available -j | ruby -rjson -e '
	devices = JSON.parse(STDIN.read).fetch("devices")
	iOS_devices = devices
		.select { |runtime, _| runtime.include?(".iOS-") }
		.values
		.flatten
	device = iOS_devices.find { |candidate| candidate.fetch("isAvailable", false) }
	abort "No available iOS Simulator device" if device.nil?
	print device.fetch("udid")
'
