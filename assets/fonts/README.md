# Galmuri font attribution

Upstream: https://github.com/quiple/galmuri/tree/71e1cacf1437a11220307120e63e30bc275312d4
Author: quiple
License: SIL Open Font License 1.1 (see LICENSE.txt).

Galmuri11 Regular and Galmuri11 Bold are packaged into compressed Godot FontFile resources. The original TTF data and names are unchanged; this is not a glyph subset. WOFF2 was tested but did not decode in the current engine build, so runtime uses the packaged TTF resources.

Original source checksums:
- Galmuri11.ttf: SHA256 e24256f42e43713d2ea086a1e1669d78b968f5b3cc547e5c157f0606ffa5def1
- Galmuri11-Bold.ttf: SHA256 45d901e379138dd91873af157640f60aa4cf6beaa885c3efd2a8c279e039a237

To rebuild, download these two upstream dist/ TTF files into .tools/font-sources/ and run:
`godot --headless --path . --script res://tools/build_typefaces.gd`
