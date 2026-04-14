# audio2json.nim

import std/[math, streams, strformat, strutils]
import sndfile
import ./types


# sample_scale for short (16-bit)
const MaxShortValue = cshort.high.int


proc float2db(x: float): float =
  let ax = abs(x)

  if ax > 0.0f:
    return 20.0f * log10(ax)
  else:
    return -9999.9f


proc normalize(x, inMin, inMax: float): float =
  if inMax == inMin:
    0.0
  else:
    clamp((x - inMin) / (inMax - inMin), 0.0, 1.0)


# compute single sample depending on channel selection
proc getSample(samples: openArray[cshort], i, nChannels: int, ch: ChannelName): cshort =
  case ch
  of LEFT: return samples[i]
  of RIGHT:
    assert nChannels == 2
    return samples[i+1]
  of MID:
    assert nChannels == 2
    return cshort((samples[i].int + samples[i+1].int) div 2)
  of SIDE:
    assert nChannels == 2
    return cshort((samples[i].int - samples[i+1].int) div 2)
  of MIN:
    assert nChannels == 2
    return max(samples[i], samples[i+1])
  of MAX:
    assert nChannels == 2
    return min(samples[i], samples[i+1])


proc computePeaks*(
  snd: ptr SndFile,
  info: var SFInfo,
  samples: int,
  channels: ChannelNames,
  useDbScale: bool,
  dbMin: float,
  dbMax: float,
  progressCallback: ProgressCallback
): seq[seq[float]] =
  # clamp samples to file frames
  var
    totalFrames = info.frames.int
    numSamples = clamp(samples, 0, totalFrames)

  let framesPerPixel = max(1, if numSamples == 0: 1 else: totalFrames div numSamples)
  let samplesPerPixel = int(info.channels) * framesPerPixel
  let progressDivisor = max(1, numSamples div 100)

  # Temp sample block buffer
  var buffer = newSeq[cshort](samplesPerPixel)
  # Prepare output bins
  result = newSeq[seq[float]](channels.len)

  for i in 0 ..< channels.len:
    result[i] = @[]

  for x in 0 ..< numSamples:
    # Read audio frames
    let framesRead = readFShort(snd, addr buffer[0], framesPerPixel)
    var samplesCount = int(framesRead) * int(info.channels)

    if samplesCount > buffer.len:
      samplesCount = buffer.len

    for channelIdx in 0 ..< channels.len:
      let ch = channels[channelIdx]
      var maxVal = 0
      var idx = 0

      while idx < samplesCount:
        let sample = getSample(buffer, idx, int(info.channels), ch)
        let absSample = abs(int(sample))
        if absSample > maxVal: maxVal = absSample
        idx += int(info.channels)

      var y: float

      if useDbScale:
        let s = float(maxVal) / float(MaxShortValue)
        y = normalize(float2db(s), dbMin, dbMax)
      else:
        y = normalize(float(maxVal), 0.0, float(MaxShortValue))

      if progressCallback != nil and x mod progressDivisor == 0:
        if not progressCallback(100 * x div max(1, numSamples)):
          return

      result[channelIdx].add(y)

  # final progress callback
  if progressCallback != nil:
    discard progressCallback(100)


proc writeJson*(outStream: Stream, peaks: seq[seq[float]],
                channels: ChannelNames, precision: int = 6) =
  # Write collected values to given stream as JSON array
  # with requested float precision
  for channelIdx in 0 ..< channels.len:
    let ch = channels[channelIdx]
    outStream.write(&"  \"{($ch).toLowerAscii}\": [")

    for i in 0 ..< peaks[channelIdx].len:
      let v = peaks[channelIdx][i]
      outStream.write(formatFloat(v, ffDecimal, precision))

      if i != peaks[channelIdx].len - 1:
        outStream.write(",")

    outStream.writeLine("],")
