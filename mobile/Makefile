PROD_URL := https://drivevault-backend-250609806849.us-central1.run.app
LOCAL_URL := http://localhost:8000

# ── Run ───────────────────────────────────────────────────────────────────────

run:        ## Run on iOS simulator → local backend
	flutter run --dart-define=API_BASE_URL=$(LOCAL_URL)

run-prod:   ## Run on iOS simulator → production backend
	flutter run --dart-define=API_BASE_URL=$(PROD_URL)

run-android:        ## Run on Android emulator → local backend
	flutter run -d android --dart-define=API_BASE_URL=$(LOCAL_URL)

run-android-prod:   ## Run on Android emulator → production backend
	flutter run -d android --dart-define=API_BASE_URL=$(PROD_URL)

# ── Build ─────────────────────────────────────────────────────────────────────

build-apk:  ## Build release APK → production backend
	flutter build apk --dart-define=API_BASE_URL=$(PROD_URL)

build-ipa:  ## Build release IPA → production backend
	flutter build ipa --dart-define=API_BASE_URL=$(PROD_URL)

# ── Dev ───────────────────────────────────────────────────────────────────────

get:        ## Install dependencies
	flutter pub get

test:       ## Run unit tests
	flutter test

analyze:    ## Run static analysis
	flutter analyze

clean:      ## Clean build artifacts
	flutter clean

help:       ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-20s %s\n", $$1, $$2}'

.PHONY: run run-prod run-android run-android-prod build-apk build-ipa get test analyze clean help
