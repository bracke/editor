Pass580: corrected bounded static Character'Image handling for the apostrophe character.

Changes:
- Static Character'Image now emits Ada's canonical four-apostrophe image for the apostrophe character.
- Character'Value over a retained Character'Image apostrophe string now round-trips as a static Character value.
- String attributes over the retained apostrophe image now see length 4 rather than a malformed three-apostrophe spelling.
- Extended apostrophe static-representation regression coverage for Image length and Value/Image round-trip.
