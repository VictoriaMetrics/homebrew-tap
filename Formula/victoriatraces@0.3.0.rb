class VictoriatracesAT030 < Formula
  desc "Fast and easy to use database for distributed traces"
  homepage "https://docs.victoriametrics.com/victoriatraces/"
  version "0.3.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of victoriatraces"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-arm64-v#{version}.tar.gz"
      sha256 "5a06a217c7ad9957acc9030a80946cd8ad62f7fec335ef93eceb3c77280eb3b2"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-amd64-v#{version}.tar.gz"
      sha256 "45172d85eb119797637085feb8d0bf5fb78a3f0f998e831d23bd279382682bfd"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-arm64-v#{version}.tar.gz"
      sha256 "653f0630060f52d684554d58828599d7da5ae5b127fa4df963db75731c0582bc"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-amd64-v#{version}.tar.gz"
      sha256 "606751f3c9489b111d785497e48b6ee9be3a2fcd1778b8b4036a75c2e0cd8d1f"
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
      "-storageDataPath=#{var}/victoriatraces@0.3.0-data",
    ]
    keep_alive false
    log_path var/"log/victoriatraces@0.3.0.log"
    error_log_path var/"log/victoriatraces@0.3.0.err.log"
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
