module SonicPiAkaiApcMini
  module Helpers
    module_function

    # Normalizes a MIDI velocity value (between 0 and 127) to the corresponding
    # value in `target`, which can be a range, a ring/array, or the special
    # value :pan (shortcut for -1..1).
    def normalize(value, target)
      value /= 127.0
      target = -1..1 if target == :pan
      case target
      when Range
        target.begin + (value * (target.end - target.begin))
      when Array, SonicPi::Core::RingVector
        index = ((target.size - 1) * value).round
        target[index]
      end
    end

    class RangeError < StandardError; end

    # Given a starting button (row, col) and a size, return the range of
    # corresponding MIDI notes for those buttons. If `size` is bigger than the
    # amount of remaining buttons before the end of the row, the range finishes
    # at the end of the row. If the currently configured model has fewer
    # rows/columns, it raises a RangeError error.
    def key_range(row, col, size)
      raise RangeError, "out of range" if row >= Controller.model.grid_rows || col >= Controller.model.grid_columns

      first = key(row, col)
      last = first + size - 1
      end_of_row = key(row, Controller.model.grid_columns - 1)

      first..[last, end_of_row].min
    end

    def key(row, col)
      (row * Controller.model.grid_columns) + col + Controller.model.grid_offset
    end
  end
end
