# Script to be used in development. Instead of `require '.../init'` from
# SonicPi, `load '.../init_dev.rb'` and code will be reloaded on each Alt+R.

dir = File.join(__dir__, 'lib', 'sonic-pi-akai-apc-mini')

load "#{dir}/core_extensions/range.rb"
load "#{dir}/helpers.rb"
load "#{dir}/api.rb"
load "#{dir}/controller.rb"
load "#{dir}/lights_panel.rb"

# bypass the mechanism that avoids hot-changing the model, forcing a reload of
# the config on each call:
SonicPiAkaiApcMini::Controller.instance_variable_set(:@_model, nil)

include SonicPiAkaiApcMini::API
