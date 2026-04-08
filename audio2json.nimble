# nimble file for audio2json
version       = "0.1.1"
author        = "SpotlightKid"
description   = "Generate sample peak data in JSON format from audio files."
license       = "MIT"
srcDir        = "src"
binDir        = "bin"

# Nim toolchain requirement
requires "nim >= 2.0"

# Dependency on sndfile Nim package (nim-sndfile)
requires "sndfile"

namedBin["audio2json/main"] = "audio2json"
installExt = @["nim"]
