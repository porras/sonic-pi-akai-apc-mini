module SonicPiAkaiApcMini
  module Controller
    class Error < StandardError; end

    module_function

    def model=(model_name)
      if @_model
        if @_model.name == model_name
          return
        else
          raise Error, 'Changing the model is not supported. Please restart Sonic Pi and initialize with new model name'
        end
      end

      config = Configs.fetch(model_name.to_sym) { raise Error, "model #{model_name} not supported" }

      @_model = Model.new(config.merge(name: model_name))
    end

    def model
      @_model || raise(Error, 'model not initialized')
    end

    Model = Struct.new(
      :name, :midi_port,
      :grid_rows, :grid_columns, :grid_offset,
      :fader_count, :fader_offset, :fader_light_offset,
      :light_off, :light_green, :light_red, :light_yellow,
      keyword_init: true
    ) do
      def midi_event(event_name)
        "/midi:#{midi_port}/#{event_name}"
      end
    end

    Configs = {
      apc_mini: {
        midi_port: 'apc_mini*',
        grid_rows: 8,
        grid_columns: 8,
        grid_offset: 0,
        fader_count: 9,
        fader_offset: 48,
        fader_light_offset: 16,
        light_off: 0,
        light_green: 1,
        light_red: 3,
        light_yellow: 5
      },
      # TODO: Some assumptions here, check!
      apc_key_25: {
        midi_port: 'apc_key_25*', # TODO: this is just a guess
        grid_rows: 5,
        grid_columns: 8,
        grid_offset: 0,
        fader_count: 8,
        fader_offset: 48,
        fader_light_offset: nil, # no fader lights
        light_off: 0,
        light_green: 1,
        light_red: 3,
        light_yellow: 5
        # TODO: handle keyboard
      }
    }.freeze
  end
end
