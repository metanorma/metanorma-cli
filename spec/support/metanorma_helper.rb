module Metanorma
  module Helper
    def stub_system_home_directory
      allow(Dir).to receive(:home).
        and_return(Dir.tmpdir)
    end
  end
end
