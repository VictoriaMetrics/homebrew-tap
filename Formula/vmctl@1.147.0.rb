class VmctlAT11470 < Formula
  desc "Command-line tool for migrating and verifying VictoriaMetrics data"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmctl/"
  version "1.147.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "32dca771ff1830f98760aab86a92fdfcfb60e8b9588d908eb1ff0f5e90e0bcaf"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "ec9aed148da71c346507138ac1f35fa3f0a9cef6797c02a42e9dc7b5ab14629a"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "0348ec940845fe35197310dd49df0620fca840d43e67d75616ba55eebd7e6edb"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "1e5da38c3d8d7af9c4fc0daa8a2103f2578c40ed81752d21f20a3bd6d0506b3f"
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
