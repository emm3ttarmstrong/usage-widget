# Claude Code Usage Widget — Build & Install
#
# Usage:
#   make build     — Build Release .app
#   make install   — Build + copy to /Applications
#   make uninstall — Remove from /Applications
#   make clean     — Remove build artifacts
#   make setup BUNDLE_ID=com.yourname.UsageWidget — Change bundle ID

APP_NAME      := UsageWidget
PROJECT_DIR   := UsageWidget
PROJECT       := $(PROJECT_DIR)/$(APP_NAME).xcodeproj
SCHEME        := $(APP_NAME)
CONFIG        := Release
DERIVED_DATA  := build
BUILD_DIR     := $(DERIVED_DATA)/Build/Products/$(CONFIG)
APP_PATH      := $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR   := /Applications

# Ad-hoc signing — no Apple Developer account needed.
# The app uses /usr/bin/security CLI for Keychain access, so entitlements-based
# code signing is not required.
SIGN_FLAGS    := CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES

.PHONY: build install uninstall clean setup

build:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-derivedDataPath $(DERIVED_DATA) \
		$(SIGN_FLAGS) \
		build
	@echo "\n✓ Built: $(APP_PATH)"

install: build
	@mkdir -p $(INSTALL_DIR)
	cp -R $(APP_PATH) $(INSTALL_DIR)/$(APP_NAME).app
	@echo "✓ Installed to $(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "✓ Removed $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	rm -rf $(DERIVED_DATA)
	@echo "✓ Cleaned build artifacts"

# Replace the default bundle ID in all 3 locations.
# Usage: make setup BUNDLE_ID=com.yourname.UsageWidget
BUNDLE_ID ?= com.emmett.UsageWidget
DEFAULT_BUNDLE_ID := com.emmett.UsageWidget

setup:
ifeq ($(BUNDLE_ID),$(DEFAULT_BUNDLE_ID))
	@echo "Error: provide a BUNDLE_ID, e.g. make setup BUNDLE_ID=com.yourname.UsageWidget"
	@exit 1
endif
	@echo "Replacing $(DEFAULT_BUNDLE_ID) → $(BUNDLE_ID) in:"
	@echo "  - project.pbxproj (2 occurrences)"
	@echo "  - UsageWidget.entitlements (1 occurrence)"
	sed -i '' 's/$(DEFAULT_BUNDLE_ID)/$(BUNDLE_ID)/g' \
		$(PROJECT_DIR)/$(APP_NAME).xcodeproj/project.pbxproj \
		$(PROJECT_DIR)/$(APP_NAME)/UsageWidget.entitlements
	@echo "✓ Bundle ID updated to $(BUNDLE_ID)"
