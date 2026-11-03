WEB_HOST ?= 127.0.0.1
WEB_PORT ?= 8080
ANDROID_DEVICE ?=

.PHONY: dev dev-web dev-android dev-andorid devices test format

dev:
	flutter run -d web-server --web-hostname $(WEB_HOST) --web-port $(WEB_PORT)

dev-web: dev

dev-android:
	@device="$(ANDROID_DEVICE)"; \
	if [ -z "$$device" ]; then \
		device="$$(flutter devices --machine | python3 -c 'import json,sys; devices=json.load(sys.stdin); print(next((item["id"] for item in devices if str(item.get("targetPlatform", "")).startswith("android")), ""))')"; \
	fi; \
	if [ -z "$$device" ]; then \
		echo "No Android device found. Start an emulator or connect a device."; \
		exit 1; \
	fi; \
	echo "Starting KeyNest on $$device"; \
	flutter run -d "$$device"

dev-andorid: dev-android

devices:
	flutter devices

test:
	flutter test

format:
	dart format lib test
