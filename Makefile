.PHONY: test build app dmg verify clean

test:
	swift test

build:
	swift build -c release

app:
	./Scripts/build_app.sh

dmg: app
	./Scripts/create_dmg.sh

verify: test dmg
	codesign --verify --deep --strict --verbose=2 dist/ItoCanvas.app
	hdiutil imageinfo dist/ItoCanvas.dmg >/dev/null

clean:
	swift package clean
	/usr/bin/python3 -c 'import shutil; shutil.rmtree("dist", ignore_errors=True)'
