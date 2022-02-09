require 'byebug'
require 'sonic-pi-akai-apc-mini'
require 'support/fake_sonic_pi'
require 'support/matchers'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    # bypass the mechanism that avoids hot-changing the model:
    SonicPiAkaiApcMini::Controller.instance_variable_set(:@_model, nil)
  end
end
