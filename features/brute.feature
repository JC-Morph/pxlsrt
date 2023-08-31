Feature: Brute pixelsorting

	The brute CLI subtask should be able to reproduce a pixelsorted image
	reliably, and also reject unrecognised options.

	Background:
		Given I use a fixture named "images"

	Scenario: Default options
		When I run `pxlsrt brute test-input.png test-output.png`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-brute.png"

	Scenario: Vertical option
		When I run `pxlsrt brute test-input.png test-output.png --vertical`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-brute-vertical.png"

	Scenario: Smooth option
		When I run `pxlsrt brute test-input.png test-output.png --smooth`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-brute-smooth.png"

	Scenario: Reverse option
		When I run `pxlsrt brute test-input.png test-output.png --reverse`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-brute-reverse.png"

	Scenario: Diagonal option
		When I run `pxlsrt brute test-input.png test-output.png --diagonal`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-brute-diagonal.png"

	Scenario: Diagonal option with vertical option
		When I run `pxlsrt brute test-input.png test-output.png --diagonal --vertical`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-brute-diagonal-vertical.png"

	Scenario: Middle option
		When I run `pxlsrt brute test-input.png test-output.png --middle`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-brute-middle.png"
