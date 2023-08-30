Feature: Kim pixelsorting

	The kim CLI subtask should be able to reproduce a pixelsorted image
	reliably, and also reject unrecognised options.

	Background:
		Given I use a fixture named "images"

	Scenario: Default options
		When I run `pxlsrt kim test-input.png test-output.png`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-kim.png"

	Scenario: Black method
		When I run `pxlsrt kim test-input.png test-output.png --method black`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-kim-black.png"

	Scenario: White method
		When I run `pxlsrt kim test-input.png test-output.png --method white`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-kim-white.png"
