# Godot MIDI Player

Software MIDI player library for Godot Engine 3.2 later

* Changes play speed.
* Set tempo.
* Emit on some events (tempo change, appears lyric ...)
* Can ontrol like AudioStreamPlayer.

## Try it

1. Copy *.mid under "res://"
2. Copy *.sf2 under "res://"
3. Set MIDI path to MidiPlayer "file" parameter.
4. Set SoundFont path to MidiPlayer "soundfont" parameter.
5. Play

## How to use

* See [wiki](https://bitbucket.org/arlez80/godot-midi-player/wiki/)

### Demo

* [download](https://bitbucket.org/arlez80/godot-midi-player/downloads/demo.zip)
    * This demo can get MIDIInput events. You can play using MIDI keyboards!
* BGM "failyland_gm.mid" from [IvyMaze]( http://ivymaze.sakura.ne.jp/ )

## Hint

* Set false to `GodotMIDIPlayer.load_all_voices_from_soundfont` to load voices for program change message in MIDI sequence.
    * of course, `GodotMIDIPlayer.load_all_voices_from_soundfont = true` will be very slow.
* SMF format 0 loading faster than SMF format 1.
    * because format 1 data will be convert to format 0 in the player.

## TODO

* See [issues]( https://bitbucket.org/arlez80/godot-midi-player/issues )

## Not TODO

* Supports play format 2
    * SMF.gd can read it. but I will not implement it to MIDI Player.

## Known Problem

* Player's timebase is 1/60 sec.
    * It probably need 1/240 sec at least.

## License

MIT License

## Author

* @arlez80 あるる / きのもと 結衣 ( Yui Kinomoto )
