class VmctlAT11550 < Formula
  desc "Command-line tool for migrating and verifying VictoriaMetrics data"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmctl/"
  version "1.155.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmctl"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "30c316c0bfb840962a8b878a451acf6dcdae50294543b3a829d54ca0bb6674e1"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "4adf38ac44c3fb1b7ed4773f5930f7f4a8e5b6553147a4ae87e56f2925e060af"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "45fa04b8d616dd644c33c00698f22bbe67f9402bc474a1e6df8025f7e649d78f"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "b6181fc16cf19835706ea5d67215eea56c1fe87350fdfd82a5ff803ea2c1a907"
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
