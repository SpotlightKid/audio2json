# audio2json

Generate sample peak data in JSON format from audio files, which can be used
with e.g. [wavesurfer.js].

Implemented in [Nim] using the [sndfile] binding for libsndfile, so all audio
file formats supported by libsndfile can be used as input.


## Demo

To see the output used by [wavesurfer.js] to render an interactive waveform,
check out the [live version] of the [example](./example/).


## Build

[Install Nim] (includes `nimble`) if you dont have it yet, check out this
repository and then in the root of the repo run:

    nimble install

to build the `audio2json` command and and install it and the library to your
`~/.nimble` dir.

Run:

    nimble build

to just compile `audio2json` (will be placed in the `bin` sub-directory).


## Usage

Example:

```con
audio2json [options] input_file.wav
```

Options:

```con
General options:
  -v | --version          print version string
  -h | --help             print this help message and exit

Configuration:
  -C | --channels <ch>    comma-separated list of channel identifiers which
                          should be computed and included in the output:
                          left, right, mid, side, min, max
                          (default: left, right)
  -d | --db-scale         use logarithmic (e.g. decibel) scale instead of
                          linear scale for peak values
  --db-min <dB>           minimum value of the signal in dB, that will be
                          visible in the waveform (default: -48)
  --db-max <dB>           maximum value of the signal in dB, that will be
                          visible in the waveform (default: 0).
                          Useful if the signal peaks at a certain level.
  -o | --output <path>    name of output file, use "-" for standard output.
                          (defaults to basename of input file and its extension
                          replaced with '.json')
  -n | --no-generator     Do not include the '_generator' key in the output
  -q                      Do not report progress to standard error output.
  -s | --samples <num>    number of samples to generate (default: 800)
  -p | --precision <num>  precision (i.e. the number of digits after the comma)
                          of the floating point numbers in the output. Reducing
                          the precision yields smaller output files and 2 or 3
                          is usually sufficient
                          (1..9, default: 6)
```

Further examples:

```con
audio2json -s 800 --channels left right input.wav
audio2json --db-scale --db-min -48 --db-max 0 input.wav -o out.json
```


## License

This project is released under the [MIT] license. Please see the
[LICENSE](./LICENSE.md) file for details.


## Authors

Christopher Arndt ([@SpotlightKid](https://github.com/SpotlightKid))


## Acknowledgements

This project was re-implemented in Nim using [beschulz/wav2json] as a model
for the code structure. No code from the aforementioned project is used.


[beschulz/wav2json]: https://github.com/beschulz/wav2json
[install nim]: https://nim-lang.org/install.html
[live version]: https://chrisarndt.de/audio2json-demo
[mit]: https://choosealicense.com/licenses/mit/
[nim]: https://nim-lang.org/
[sndfile]: https://github.com/SpotlightKid/nim-sndfile
[wavesurfer.js]: https://wavesurfer.xyz
