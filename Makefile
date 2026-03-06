SHELL := /bin/bash

USER_DOMAIN := gui/$(shell id -u)
PLIST_PATH := $(HOME)/Library/LaunchAgents/com.mac-language-switcher.plist
SERVICE_LABEL := com.mac-language-switcher

.PHONY: test build run install install-clean install-debug restart stop reinstall uninstall status logs permissions

test:
	swift test

build:
	swift build -c release

run:
	swift run MacLanguageSwitcher

install:
	./scripts/install-launch-agent.sh

install-debug:
	./scripts/install-launch-agent.sh --debug

restart:
	launchctl kickstart -k "$(USER_DOMAIN)/$(SERVICE_LABEL)"

stop:
	@launchctl bootout "$(USER_DOMAIN)" "$(PLIST_PATH)" >/dev/null 2>&1 || \
		launchctl remove "$(SERVICE_LABEL)" >/dev/null 2>&1 || true

reinstall:
	@launchctl bootout "$(USER_DOMAIN)" "$(PLIST_PATH)" >/dev/null 2>&1 || \
		launchctl remove "$(SERVICE_LABEL)" >/dev/null 2>&1 || true
	rm -f "$(PLIST_PATH)"
	rm -f "$(HOME)/Library/Application Support/MacLanguageSwitcher/MacLanguageSwitcher"
	./scripts/install-launch-agent.sh

uninstall:
	@launchctl bootout "$(USER_DOMAIN)" "$(PLIST_PATH)" >/dev/null 2>&1 || \
		launchctl remove "$(SERVICE_LABEL)" >/dev/null 2>&1 || true
	rm -f "$(PLIST_PATH)"
	rm -rf "$(HOME)/Library/Application Support/MacLanguageSwitcher"
	rm -f /tmp/mac-language-switcher.log /tmp/mac-language-switcher.err.log

status:
	launchctl print "$(USER_DOMAIN)/$(SERVICE_LABEL)"

logs:
	tail -f /tmp/mac-language-switcher.err.log /tmp/mac-language-switcher.log

permissions:
	@echo "macOS TCC permissions cannot be granted automatically."
	@echo "Open System Settings -> Privacy & Security -> Accessibility and Input Monitoring."
