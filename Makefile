elm-stuff: elm-package.json
	elm package install --yes

tests/elm-stuff: tests/elm-package.json
	cd tests && elm package install --yes

test: elm-stuff tests/elm-stuff
	elm test
