class VmctlAT11450 < Formula
  desc "Command-line tool for migrating and verifying VictoriaMetrics data"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmctl/"
  version "1.145.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmctl"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "b35b3d0966bab2a6cf59497b121193a88c56d10103731fb79576c025608cefa1"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "ae205e9166d00e77ba0a82bfbd8691b637f50b1e600d1558ad7b3397d0ec0445"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "d7c3ef8d2774103ec47935b20dc1a623a9eaea3f7ee8dad5cd9d3edb489259d3"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "46be66a7de586d7561dfc1800ef541a6f606699f3069a616a454d0abb7081c69"
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
