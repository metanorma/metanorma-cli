module Metanorma
  module Helper
    def stub_system_home_directory
      allow(Dir).to receive(:home).
        and_return(Metanorma::Cli.root_path.join("tmp"))
    end
  end
end
