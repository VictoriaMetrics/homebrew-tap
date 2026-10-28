class VmctlAT11250 < Formula
  desc "Command-line tool for migrating and verifying VictoriaMetrics data"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmctl/"
  version "1.125.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "b508619a829a6da9a7192f9eb5bd61f8fdcaf61b0b4731d01c9c8aeed3e7b4e1"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "ce6ed21204d94868f434c4a0f31f60f28ae0b5acf0563dfea29e463b0ec7037e"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "241f00b92f8aff90b4c31973c08c5cb18b20734f4e07e56776daceff3c7c4db4"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "7cb144296d936e1d528af2e1b5255976a01da1755f162c920d94b472243b36ac"
    end
  end

  def install
    bin.install "vmctl-prod" => "vmctl"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vmctl --version")
    assert_match "vm-native-src-addr", shell_output("#{bin}/vmctl vm-native --help")
  end
end
