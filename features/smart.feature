Feature: Smart pixelsorting

	The smart CLI subtask should be able to reproduce a pixelsorted image
	reliably, and also reject unrecognised options.

	Background:
		Given I use a fixture named "images"

	Scenario: Default options
		When I run `pxlsrt smart test-input.png test-output.png`
		Then the file "test-output.png" should exist
		And the file "test-output.png" should be equal to file "example-smart.png"
