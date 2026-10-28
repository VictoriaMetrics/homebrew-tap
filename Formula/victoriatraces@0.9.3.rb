class VictoriatracesAT093 < Formula
  desc "Fast and easy to use database for distributed traces"
  homepage "https://docs.victoriametrics.com/victoriatraces/"
  version "0.9.3"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of victoriatraces"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-arm64-v#{version}.tar.gz"
      sha256 "30f8c4f560721220331b99af8a0c29a5a5edc91ece7c7e4f5d5f68d31e6e3d0e"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-amd64-v#{version}.tar.gz"
      sha256 "28a0a9c87e59516365154a478b71d26e460f150fba6a611f35b62a4588cab2a2"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-arm64-v#{version}.tar.gz"
      sha256 "5e271aaebffeb3d3156c13570b092b3c364280e7f498266d0a0828e1e821c860"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-amd64-v#{version}.tar.gz"
      sha256 "7bcc6e487c9bd904cd255ed8ed4b2b3d4b2121fc8f2f657dcb33d48ef6027443"
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
      "-storageDataPath=#{var}/victoriatraces@0.9.3-data",
    ]
    keep_alive false
    log_path var/"log/victoriatraces@0.9.3.log"
    error_log_path var/"log/victoriatraces@0.9.3.err.log"
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
