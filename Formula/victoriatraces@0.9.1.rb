class VictoriatracesAT091 < Formula
  desc "Fast and easy to use database for distributed traces"
  homepage "https://docs.victoriametrics.com/victoriatraces/"
  version "0.9.1"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-arm64-v#{version}.tar.gz"
      sha256 "0610bc907d97de023c1c9b59f2a1a6f11f96b86859c415e5ddf7234621fa1d4d"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-amd64-v#{version}.tar.gz"
      sha256 "ca8ba77594b8303cc45e0bf440dc013b8ad8bb957de3cd5f8a260865a943e7b9"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-arm64-v#{version}.tar.gz"
      sha256 "aa5afae8241b770cf206d671c82120bd9b981fd4f1bb06c70ba106872672e5d3"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-amd64-v#{version}.tar.gz"
      sha256 "868ca18b70ec232f8faf7937ce49b7db271ac94953888e7d82d63e112aa65c06"
    end
  end

  def install
    bin.install "victoria-traces-prod" => "victoria-traces"
  end

  def caveats
    <<~EOS
      Only one version of victoriatraces can run as a service on port 10428 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"victoria-traces",
      "-httpListenAddr=127.0.0.1:10428",
      "-storageDataPath=#{var}/victoriatraces@0.9.1-data",
    ]
    keep_alive false
    log_path var/"log/victoriatraces@0.9.1.log"
    error_log_path var/"log/victoriatraces@0.9.1.err.log"
  end

  test do
    http_port = free_port

    pid = spawn bin/"victoria-traces",
                "-httpListenAddr=127.0.0.1:#{http_port}",
                "-storageDataPath=#{testpath}/victoriatraces-data"
    30.times do
      break if quiet_system("curl", "-fsS", "-o", File::NULL, "127.0.0.1:#{http_port}")

      sleep 1
    end
    assert_match "VictoriaTraces", shell_output("curl -s 127.0.0.1:#{http_port}")

    assert_match version.to_s, shell_output("#{bin}/victoria-traces --version")
  ensure
    begin
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      nil
    end
    Process.wait(pid)
  end
end
