# Using the Akai APC mini to control Sonic Pi

A collection of utility functions to use the [Akai APC mini](https://www.akaipro.com/apc-mini) MIDI controller with [Sonic Pi](https://sonic-pi.net/).

![Photo of an Akai APC mini](akai-apc-mini.jpg)

_Photo credit: <a href="https://commons.wikimedia.org/wiki/File:APC_Mini_and_other_Music_Tools_(15387729761).jpg">I G</a>, <a href="https://creativecommons.org/licenses/by/2.0">CC BY 2.0</a>, via Wikimedia Commons_.

### Important note

This is work in progress and, while it mostly works as described, its performance is not great and it is not completely stable. It can make the controller crash* sometimes when there is _too much_ going on, and even Sonic Pi itself (this is more rare and I have only seen it once, but it's fair to mention).

You should _probably_ not use this yet for live performances, at least without having reproduced similar loads to what you plan to do.

\*I don't know if this crashes happen in the controller itself, or in the software in the computer (be it drivers or Sonic Pi itself), but the way it manifests is: you can still control the sounds using the board, but its lights stop updating. I haven't found a solution to this crashes that is not restarting Sonic PI + plugging and unplugging the controller.

## Installation

Download, clone the code or install the gem, then add this to the top of your Sonic Pi buffer (or your `~/.sonic-pi/config/init.rb`):

```ruby
require '<path-to-sonic-pi-akai-apc-mini>/init.rb'
# for example: require '~/sonic-pi-akai-apc-mini/init.rb'
```

### Finding out where the code is, when installed as a gem

Sonic Pi ships with its own Ruby, meaning that in principle it has no access to the gems installed in your system. To find out where is the file you need to require, run `sonic-pi-akai-apc-mini` in a terminal and the path will be printed.

## Usage

First of all, call `initialize_akai` at the top of your buffer. That will make all the features available.

A small set of functions get added to the Sonic Pi API, in order to use the controls in the APC mini in different ways.

### Faders

#### `fader(n, [target-values])`

This function lets you use any of the faders to control the value of _anything_ in Sonic Pi. `n` is the fader number (they are 0-8, left to right). `target-values` is the range of values the fader will map to (and defaults to `(0..1)`). Some examples:

```ruby
play :c4, amp: fader(0)
sample :bd_haus, cutoff: fader(1, (60..127))
```

`target-values` is typically a range, but it can also be an array or a ring. In that case, the range of the fader is divided into discrete regions, each of them mapped to a value:

```ruby
with_fx :slicer, phase: fader(0, [0.125, 0.25, 0.5]) do
  play fader(1, chord(:c4, :major))
end
```

`fader` also accepts the special value `:pan`, which maps to `(-1..1)`, for that very obvious usecase:

```ruby
play :c4, pan: fader(0, :pan)
```

Finally, it is possible to use the same fader for two different things, with two different target values, if that makes sense for your music:

```ruby
play :c4, amp: fader(0, (0.8..1.5)), pan: fader(0, :pan)
```
#### `attach_fader(n, node, property, [target-values])`

All this is fine and good and works great with short synth notes or samples, but sometimes you want to control a sound with a fader _while it is playing_. That's what `attach_fader` is for. Apart from the already known `n` and `target-values`, which work the same, it expects a `node` (a synth node, a sample node, or a fx node) and a `property`, which will be attached to the fader and updated in real-time:

```ruby
with_fx :slicer do |fx|
  attach_fader(0, fx, :mix)
  ... # while these sounds play, you can control how much the slicer can be heard using fader 0
end
```

Or:

```ruby
live_loop :drums do
  drums = sample :loop_amen, beat_stretch: 4
  attach_fader(0, drums, :cutoff, (60..120))
  sleep 4
end
```

In this case, at the moment it is not possible to attach the same fader to two different controls. But you can combine **one** `attach_fader` with as many `fader` as you want.

`attach_fader` uses `control` under the hood, which means:

* The property needs to be one that can be changed while the sound is playing. Refer to the documentation of each synth and fx.
* It will be affected by the corresponding `_slide` options. It could be said that _it doesn't play very well with any non-zero value in the corresponding `_slide` option_, but in reality pretty cool effects can be created by mixing them.

#### Important note about faders

Because MIDI works with events, it is not possible for Sonic Pi to know the initial position of a fader until it is moved and its new value is sent. Until then, it is assumed it is set to zero. So, two little advices:

* Start your performances with the faders physically set to zero, to match that assumption. Move them to the desired position _before_ evaluating the code that will read them.
* The lights above the faders are used as a hint to avoid this problem: they will be off when Sonic Pi _thinks_ they're set at zero, and on when it _thinks_ they're set at non-zero. If you see a fader physically not at zero but with the light off, move it slightly, so that Sonic Pi learns where it is :)

### Switches

Each button in the grid can be used as a boolean switch, for any purpose (typically, triggering a sound or not). You could use a fader to map `amp` (and set it to zero when you don't want to hear it), but faders are scarce and there are 64 buttons in the grid :)

#### `switch?(row, col)`

Returns the current value (`true` or `false`) of the specified switch. Columns and rows start from 0, 0 at the lower left corner.

```ruby
live_loop :music do
  sample "some_noisy_sample" if switch?(0, 0)
  ... # some nice music
end
```

The buttons will light green when they're on.

### Selectors

_NOTE: This feature is experimental. It mostly works, but its performance is quite bad and is one of the things that incresases the chance of crashes._

Selectors are a special kind of switches. You can map a series of consecutive buttons in the grid, to different values. Only one of them will be active at the time (lighting green, while the others light red).

#### `selector(row, col, target-values)`

`row` and `col` points to the first button you want to assign, and `values` is an array/ring with the possible values. As many buttons as possible values will be mapped, but the end of the row is a hard limit.

```ruby
live_loop :notes do
  use_synth selector(7, 0, [:fm, :beep, :tb303])
  play scale(:c3, :minor_pentatonic).choose
  sleep 0.5
end
```

Or:

```ruby
play_chord selector(6, 0, [chord(:e3, :minor), chord(:g3, :major), chord(:d3, :major)])
```

As you can see, the use case is very similar to using `fader` with an array, but it is a better UI for many cases. Sadly, it doesn't work perfectly at the moment, so you might prefer to stick with `fader`.

### Looping with the grid

One of the most useful uses of the grid is _looping_. You can set it up so that you can punch notes in the grid, that will be played in loop. This is great (but not only) for drum loops.

#### `loop_rows(duration, rows)`

`duration` is the number of beats the loop lasts. It will always divided by the 8 columns of the grid. `rows` is a hash which maps the row number to a block with the sound to play. For example:

```ruby
live_loop :drums do
  loop_rows(4, {
    7 => -> { sample :drum_heavy_kick },
    6 => -> { sample :drum_snare_hard },
    5 => -> { synth :noise, release: 0.1 } # sketchy hi-hat
  })
end
```

This will assign the top 3 rows of the grid to punch a drum pattern. Notes will be shown as green, and there will be a hinting yellow light showing which column is being played as the loop progresses.

#### `loop_rows_synth(duration, rows, notes, [options])`

A typical use case of looping is calling a synth (always the same) with different notes (e.g. for basslines). This function makes it a bit less verbose:

```ruby
live_loop :bassline do
  loop_rows_synth(8, (0..2), chord(:c2, :minor))
end
```

This will assign each of the three notes of the chord to each row, and now you can punch your baseline.

You can pass options, that will be applied to each note:

```ruby
live_loop :bassline do
  loop_rows_synth(8, (0..2), chord(:c2, :minor), amp: 0.8)
end
```

And, if you need those options to be evaluated separately for each note (because you call random values, or maybe `fader`), you can wrap it in a lambda:

```ruby
live_loop :bassline do
  loop_rows_synth(8, (0..2), chord(:c2, :minor), -> {{ pan: rrand(-1..1), cutoff: fader(5, (60..120)) }}
end
```

Something to note, is that there is no problem to run more than one loop, with different durations, as long as they don't use the same rows.

### Free play

The APC mini is a MIDI device, so you can... play! Be aware that this is of limited usefulness for several reasons (1. there is some latency that is ok for faders and such but makes playing quite difficult, and 2. it is not a keyboard, which makes it _even_ more difficult), but it can be ok for very simple things.

#### `free_play(row, col, notes, [options])`

Assigns a series of consecutive buttons starting at `row`, `col`, to play `notes` with the current synth (and the given `options`, if any). The mapped buttons with light yellow. This call should live in its own `live_loop`.

```ruby
live_loop :bass do
  use_synth :fm
  free_play 0, 0, scale(:c3, :major), amp: 0.8
end
```

#### `reset_free_play(row, col, notes, [options])`

If you want to remove a free play mapping (so that the buttons are again available as switches), you need to call `reset_free_play`. It has the same signature so you can just prepend `reset_` to the previous call.

### Roadmap of planned features

* A `selector` that actually works
* Free play with samples
* Improvements to `attach_fader` so that a couple of things that are currently not possible, are:
  * Using it to control the mixer (`set_mixer_control!`, etc.)
  * Attaching the same fader to different nodes, or different properties of the same node
* Better performance and stability in general

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/porras/sonic-pi-akai-apc-mini. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/porras/sonic-pi-akai-apc-mini/blob/master/CODE_OF_CONDUCT.md).

## License

This code is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the sonic-pi-akai-apc-mini project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/porras/sonic-pi-akai-apc-mini/blob/master/CODE_OF_CONDUCT.md).

## Acknowledgments

Apart from the excellent documentation of the Sonic Pi project, [this wonderful summary](https://github.com/TomasHubelbauer/akai-apc-mini) by Tomáš Hübelbauer took me from barely knowing what MIDI is to a functional prototype in a couple of hours. Cheers!
