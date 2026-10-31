#!/usr/bin/env python3
"""Author Facet's original ambient score and feedback; requires numpy + ffmpeg.
Only a development asset tool. No audio synthesis runs on the phone.
"""
from pathlib import Path
import subprocess
import tempfile
import wave
import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'
OUT.mkdir(parents=True, exist_ok=True)

def save(path, samples):
    assert np.max(np.abs(samples)) < 0.95, 'Audio must retain headroom'
    with wave.open(str(path), 'wb') as wav:
        wav.setnchannels(1 if samples.ndim == 1 else samples.shape[1])
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes((samples * 32767).astype('<i2').tobytes())

def felt(frequency, duration=7.0):
    t = np.arange(int(duration*RATE)) / RATE
    attack = 1-np.exp(-t*45)
    return attack*(np.sin(2*np.pi*frequency*t)*np.exp(-t*0.8)
        + 0.15*np.sin(2*np.pi*frequency*2*t)*np.exp(-t*2.2)
        + 0.035*np.sin(2*np.pi*frequency*3*t)*np.exp(-t*3.5))

# Original 48-second D/A suspended phrase. Reverb tails wrap into the start.
length = RATE*48
t = np.arange(length) / RATE
music = np.zeros((length,2))
for frequency, amplitude in [(110,0.005),(146.8333333,0.003),(220,0.002)]:
    f = round(frequency*48)/48
    bed = np.sin(2*np.pi*f*t)*(0.55-0.45*np.cos(2*np.pi*t/48)) * amplitude
    music += bed[:,None]
phrase = [(2,293.665),(7,440),(13,329.628),(19,220),(26,391.995),(32,293.665),(39,440),(44,329.628)]
for i,(start,freq) in enumerate(phrase):
    note = felt(freq)*0.052
    for delay,gain in [(0,1),(0.23,0.24),(0.51,0.13),(0.89,0.07)]:
        indices = (np.arange(note.size)+round((start+delay)*RATE)) % length
        pan = 0.35 if i % 2 else 0.65
        music[indices,0] += note*gain*np.sqrt(1-pan)
        music[indices,1] += note*gain*np.sqrt(pan)
with tempfile.TemporaryDirectory() as folder:
    source = Path(folder)/'ambient.wav'
    save(source,music)
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-c:a','libvorbis','-q:a','4',str(OUT/'moonlit.ogg')],check=True)

for kind,freq,gain in [('tap',659.255,0.035),('remove',880,0.07),('invalid',293.665,0.035),('unlock',1174.66,0.06),('hint',783.991,0.055),('victory',587.33,0.055)]:
    t = np.arange(RATE*2)/RATE
    drop = (1-np.exp(-t*100))*np.exp(-t*5)
    sound = (np.sin(2*np.pi*freq*t+0.35*np.exp(-t*25))
        + np.sin(2*np.pi*freq*2.76*t)*np.exp(-t*8)*0.12)*drop*gain
    if kind in ('unlock','victory'):
        sound += felt(freq*1.5,2)*gain*0.32
    # Soft echoes form an airy tail without a runtime effects bus.
    for delay,amount in [(0.11,0.17),(0.29,0.09)]:
        n = round(delay*RATE)
        sound[n:] += sound[:-n]*amount
    sound[-100:] *= np.linspace(1,0,100)
    save(OUT/(kind+'.wav'),sound)
print('Original soundscape authored: 48s stereo ambient loop, six 2s feedback clips.')
