module SonicPiAkaiApcMini
  module Helpers
    module_function

    def normalize(value, target)
      value /= 127.0
      target = (-1..1) if target == :pan
      case target
      when Range
        target.begin + (value * (target.end - target.begin))
      when Array, SonicPi::Core::RingVector
        index = ((target.size - 1) * value).round
        target[index]
      end
    end

    def key_range((row, col), max_size)
      first = (row * 8) + col
      last = [(row * 8) + 7, first + max_size - 1].min
      (first..last)
    end
  end
end
