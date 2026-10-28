class VictorialogsAT1410 < Formula
  desc "Fast and easy to use database for logs"
  homepage "https://docs.victoriametrics.com/victorialogs/"
  version "1.41.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-arm64-v#{version}.tar.gz"
      sha256 "0fc95dd95326ddc9ac53d9c16907b905fd6067bebe4decf5a609b2028d72e9a4"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-amd64-v#{version}.tar.gz"
      sha256 "62a9b2605f000e6c094d6816ed9cf728f1383f9dd43ed2dd3ff9f13b54e3a11b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-arm64-v#{version}.tar.gz"
      sha256 "fe3fecc82476aa81555b622277d1473f51b6c31a0c4fa081f37168ef1ccf8059"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-amd64-v#{version}.tar.gz"
      sha256 "a84447589d6283a420631fd243adabaf7b7d1abf13b1b6a4a7713c2a017bb968"
    end
  end

  def install
    bin.install "victoria-logs-prod" => "victoria-logs"
  end

  def caveats
    <<~EOS
      Only one version of victorialogs can run as a service on port 9428 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"victoria-logs",
      "-httpListenAddr=127.0.0.1:9428",
      "-storageDataPath=#{var}/victorialogs@1.41.0-data",
    ]
    keep_alive false
    log_path var/"log/victorialogs@1.41.0.log"
    error_log_path var/"log/victorialogs@1.41.0.err.log"
  end

  test do
    http_port = free_port

    pid = spawn bin/"victoria-logs",
                "-httpListenAddr=127.0.0.1:#{http_port}",
                "-storageDataPath=#{testpath}/victorialogs-data"
    30.times do
      break if quiet_system("curl", "-fsS", "-o", File::NULL, "127.0.0.1:#{http_port}")

      sleep 1
    end
    assert_match "VictoriaLogs", shell_output("curl -s 127.0.0.1:#{http_port}")

    assert_match version.to_s, shell_output("#{bin}/victoria-logs --version")
  ensure
    begin
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      nil
    end
    Process.wait(pid)
  end
end
