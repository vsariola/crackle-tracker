# Crackle Tracker

A TIC-80 tracker for tiny intros, targeting especially the 512b size
category.


Introduction
------------

The tracker supports 4 channels. Instrument settings are per channel, so
each channel is has its distinct tone. The sound is controlled by the
values in the "Instrs" table.

Each channel has its orderlist which tells the general structure of the
song: which patterns appear in which order.

The patterns are edited by semitone values, in base 36 (0-9A-Z). "-"
denotes no note.

Each note has linearly decaying envelope (no attack, no sustain) and
this cannot be changed.

Importantly, the note duration of different channels do not have to be
the same, so the pattern row advances at different rates for each
channel, controlled by the NoteDur parameter. For example, even if all
channels are playing the exact same pattern, if one channel is playing
whole notes, one channel is playing half notes and one channel quarter
notes, the whole phrase loops only with the channel that was playing
whole notes.

Nevertheless, the order list advances at the same time for all the
channels.

There is one extra channel, the "key" channel. This channels values are
added to the pitch of all channels, to change the key of the song. If
your notes are from the power chords (0, 7, 12 = C...), you can add
almost any value here. If your patterns have notes only from minor
chords or major chords, 0-5-7 (I-IV-V or i-iv-v, respectively) stay in
key. If you're fine with jazz, anything works.

The song data is kept in the pmem, so you can quit and restart the
tracker and the song should stay in memory.

Instrument settings
-------------------

- Wave: 0 = square, 1 = triangle, 2 = saw, 3 = noise. Triangle and saw
  sound really bad, so square and noise the only really usable one.
- Octave: 12*octave is added to the notevalue
- Semitn: semitn is added to the notevalue
- NoteDur: Controls how fast the pattern row advances or the duration of
  each note. 1 = whole note, 2 = half note, 4 = quarter note, 8 = eight
  note, G (16) = sixteenth note
- Fill: Controls following pattern(s) are played instead of repeating
  the same pattern every time.
- Mute: temporarily mute channel
- Slide: How quickly the pitch of the channel drops. 0 = no drop, 8 =
  typical for a kick


Song settings
-------------

- Ordlen: length of the order list.
- PatReps: how long to keep on repeating the patterns before advancing
  to next pattern.
- PatLen: what is the length of each pattern, in rows.
- Tempo: controls the tempo of the song. Actually, the envelope of each
  note it calculated with `%(16-tempo)`, so increasing the tempo also
  decreases the master volume.
- Semitn: added to all note values of the song, controlling essentially
  the key of the song.
- KeyDur: how quickly the pattern rows of the key channel advance.


Exporting
---------

Since TIC-80 has no way to access file system, the only practical way to
export data from TIC-80 is by abusing the `trace` command. When you
click export, a fully functional TIC-80 lua script that includes the
player and the song data is outputted to the console. You can then
copy-paste this to another file & start hand-optimizing unused player
features away.

The envelopes are saves to the data array: d[0], d[-1], d[-2] and d[-3]
contain the envelopes of the channels 0-3, respectively, so you can make
your visuals flash to the music.


Saving & Loading
----------------

Saving works like exporting: when you save the song, the tracker prints
a code that, when ran, loads the song to the pmem. For example, if you
copy-pasted the code to a file called `saved-song.lua`, in order to load
the song:

  1. `load saved-song.lua`
  2. `run`
  3. `load crackle-tracker.lua`
  4. `run`

The saving mechanism abuses `-- saveid:` script tag to make multiple
.lua files access the same pmem.


Prods using Crackle Tracker
---------------------------

[cracklebass](https://www.pouet.net/prod.php?which=90244) by brainlez Coders! - Song included in the examples folder.

[Pulsating Magic Orb](https://www.pouet.net/prod.php?which=90937) by brainlez Coders! - Song included in the examples folder.

Credits
-------

[Veikko Sariola](https://github.com/vsariola) aka pestis/brainlez Coders!

License: [MIT](LICENSE)

![Screenshot of Crackle Tracker](screenshot.png)