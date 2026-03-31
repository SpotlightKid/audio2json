# types.nim

type
  ChannelName* {.pure.} = enum
    LEFT, RIGHT, MID, SIDE, MIN, MAX

  ChannelNames* = seq[ChannelName]

  Options* = object
    samples* = 800
    precision* = 9
    dbMin* = -48.0
    dbMax* = 0.0
    channels*: ChannelNames = @[LEFT, RIGHT]
    noGenerator* = false
    useDbScale* = false
    showVersion* = false
    showHelp* = false
    quiet* = false
    outputFileName* = ""
    inputFileName* = ""

  ProgressCallback* = proc(percent: int): bool
