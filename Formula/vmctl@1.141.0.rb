class VmctlAT11410 < Formula
  desc "Command-line tool for migrating and verifying VictoriaMetrics data"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmctl/"
  version "1.141.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmctl"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "7ab2d91c19a01dcab17f2346d916bd65dbdaef2e9e8f4361993f602b56844737"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "f139ffc7cb6e65fc734293177083f1f0cf732cc8b1b55cb4537624f490bb90f6"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "e7ca4c3f916ad0157ce58eb41b9a9b50b986fab7b540184cb0cb306a4776c4ed"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "e1a4349b48f8095ac2cb2c683fe348cffd576e9fa565298310ca3781ed3ed4c4"
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
