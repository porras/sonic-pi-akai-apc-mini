# Script to be used in development. Instead of `require '.../init.rb'` from
# sonic pi, `load '.../init_dev.rb'` and code will be reloaded on each Alt+R.

dir = File.join(__dir__, 'lib', 'sonic-pi-akai-apc-mini')

load "#{dir}/core_extensions/range.rb"
load "#{dir}/helpers.rb"
load "#{dir}/api.rb"
load "#{dir}/controller.rb"

include SonicPiAkaiApcMini::API
