# This is a (probably contrived) example of the kind of things you can control.
# This short script sets things up so that:
#
# Rows 0 and 1 of the grid are used for a simple drum loop with a kick and a
# snare. Toggling the buttons in those rows will get you the pattern played, in
# real time (note that this is initialized as an empty pattern, and the volume
# is controlled by faders 0 and 2, so you won't hear anything until you toggle
# some notes and push those faders).
#
# The is a second live_loop with a chord and an arpeggio based on that chord,
# where some of the parameters are controlled by faders:
#
# 0 -> Kick volume
# 1 -> Kick cutoff frequency
# 2 -> Snare volume
# 3 -> Snare cutoff frequency
# 4 -> The chord itself! Atypical UI for this for works fine
# 5 -> Chord volume
# 6 -> Arpeggio volume
# 7 -> Arpeggio reverb amount
#
# Finally a switch is setup on button [2, 0] (leftmost button of third row,
# starting from the bottom) to toggle a background vinyl effect.
#
# Feel free to experiment with changing the music using the controller only,
# then to try to control different things!

initialize_akai(:apc_mini)

use_bpm 110

live_loop :drums do
  loop_rows(4, {
              1 => -> { sample :drum_bass_soft, amp: fader(0), cutoff: fader(1, 60..127) },
              0 => -> { sample :drum_snare_soft, amp: fader(2), cutoff: fader(3, 60..127) }
            })
end

live_loop :bass, sync: :drums do
  sample :vinyl_hiss, sustain: 2, attack: 1, release: 1 if switch?(2, 0)

  crd = fader(4, [
                chord(:c3, :major),
                chord(:g3, :major),
                chord(:a3, :minor),
                chord(:e3, :major)
              ])

  use_synth :blade

  play_chord crd, release: 4, attack: 2, amp: fader(5)

  use_synth :pluck

  with_fx :reverb do |fx|
    use_random_seed crd.first
    attach_fader(7, fx, :room)
    16.times do
      play crd.choose + 12, release: 0.25, pan: rrand(-0.1, 0.1),
                            amp: fader(6),
                            on: spread(11, 16).tick(:note)
      sleep 0.25
    end
  end
end
