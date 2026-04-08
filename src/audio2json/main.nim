# main.nim

import std/[os, parseopt, streams, strformat, strutils]
import sndfile
import ./[types, peaks]


const
  ProgName = "audio2json"
  Version = "0.1.0"


# progress callback
proc progressCallback(percent: int): bool =
  stderr.write(&"\rconverting: {percent}%")
  return true


proc noProgress(percent: int): bool =
  return true


proc showVersion() =
    echo &"{ProgName} version {Version}"


## Print command line help
proc usageAndExit(exitCode: int = QuitSuccess) =
  showVersion()
  echo &"""

usage: {ProgName} [options] input_file_name

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
"""
  quit exitCode


## Parses command line options
proc parseOptions*(cmdline: seq[string] = @[]): Options =
  var
    opts = Options.default
    parser = initOptParser(
      cmdline,
      {'d', 'h', 'n', 'q', 'v'},
      @["db-scale", "help", "no-generator", "quiet", "version"],
      LaxMode
    )

  for kind, key, val in parser.getopt():
    try:
      case kind
      of cmdEnd: break
      of cmdArgument:
        opts.inputFileName = key
      of cmdLongOption, cmdShortOption:
        case key
        of "channels", "C":
          opts.channels = @[]
          for v in val.split(','):
            if v.strip() != "":
              opts.channels.add(parseEnum[ChannelName](v.strip().toUpperAscii))
        of "db-max": opts.dbMax = val.parseFloat
        of "db-min": opts.dbMin = val.parseFloat
        of "db-scale", "d": opts.useDbScale = true
        of "help", "h": opts.showHelp = true
        of "output", "o": opts.outputFileName = val
        of "precision", "p": opts.precision = clamp(val.parseInt, 1, 9)
        of "quiet", "q": opts.quiet = true
        of "samples", "s": opts.samples = val.parseInt
        of "version", "v": opts.showVersion = true
        of "no-generator", "n": opts.noGenerator = true
    except CatchableError as e:
      echo &"Could not parse command line option: {e.msg}"

  if opts.outputFileName == "" and opts.inputFileName != "":
    opts.outputFileName = splitFile(opts.inputFileName)[1] & ".json"

  return opts

proc main() =
  let opts = parseOptions()

  if opts.showHelp:
    usageAndExit()

  if opts.showVersion:
    showVersion()
    quit QuitSuccess

  if opts.inputFileName.len == 0:
    stderr.writeLine("Error: no input file supplied.")
    usageAndExit(2)

  # Open audio via sndfile
  var info: SFInfo
  let snd = open(opts.inputFileName.cstring, SFMode.READ, info.addr)

  if snd.isNil or error(snd) != 0:
    stderr.writeLine("Error opening audio file '" & opts.inputFileName & "'")

    if not snd.isNil:
      stderr.writeLine("Error was: " & $strError(snd))

    quit 2

  defer: snd.close()

  # http://www.mega-nerd.com/libsndfile/api.html#note2
  discard command(snd, SET_SCALE_FLOAT_INT_READ, nil, TRUE.cint)

  # Error if input is mono and user requested stereo-only channels
  if info.channels == 1:
    for ch in opts.channels:
      if ch in {MID, SIDE, RIGHT, MIN, MAX}:
        stderr.writeLine(
          &"Error: requested channel '{($ch).toLowerAscii}' requires a " &
           "stereo input but the input file is mono.")
        quit 3

  # Open output (stdout or file)
  var outStream: Stream
  var useStdOut = false

  if opts.outputFileName == "-" or opts.outputFileName == "":
    useStdOut = true
  else:
    try:
      outStream = newFileStream(opts.outputFileName, fmWrite)
    except OSError as e:
      stderr.writeLine("Error: cannot open output file: " & e.msg)
      quit 2

  let output = if useStdOut: newFileStream(stdout) else: outStream

  defer:
    if not useStdOut: outStream.close()

  # Print JSON header
  output.writeLine("{")
  if not opts.noGenerator:
    output.writeLine(&"  \"_generator\": \"{ProgName} (Nim) version {Version}\",\n")

  # Select progress callback according to quiet flag
  var prog = if opts.quiet:
      noProgress
    else:
      progressCallback

  # compute waveform
  let data = computePeaks(snd, info, opts.samples, opts.channels,
                          opts.useDbScale, opts.dbMin, opts.dbMax, prog)
  output.writeJson(data, opts.channels, opts.precision)

  # print duration with high precision
  let duration = float(info.frames) / float(info.samplerate)
  output.writeLine(&"  \"duration\": {formatFloat(duration, ffDecimal, 9)}")
  output.writeLine("}")

  if not opts.quiet:
    stderr.writeLine("")


when isMainModule:
  main()
