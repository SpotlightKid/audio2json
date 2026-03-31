import WaveSurfer from 'https://cdn.jsdelivr.net/npm/wavesurfer.js@7/dist/wavesurfer.esm.js'

const audioUrl = './sample.opus';
const peaksUrl = "./sample-peaks.json";

async function fetchJson(url) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    return [];
  }
}

window.addEventListener('DOMContentLoaded', async () => {
  const peaks = await fetchJson(peaksUrl);

  const wavesurfer = WaveSurfer.create({
    container: '#waveform',
    waveColor: "#3584e4",
    progressColor: "#1b1c33",
    mediaControls: true,
    dragToSeek: true,
    url: audioUrl,
    peaks: [
      peaks["left"],
      peaks["right"],
    ],
    duration: peaks["duration"],
    splitChannels: true,
  })

  wavesurfer.on('interaction', () => {
    wavesurfer.play()
  })

  wavesurfer.on('finish', () => {
    wavesurfer.setTime(0)
  })
});
