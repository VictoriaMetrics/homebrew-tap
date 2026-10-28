class VictorialogsAT1460 < Formula
  desc "Fast and easy to use database for logs"
  homepage "https://docs.victoriametrics.com/victorialogs/"
  version "1.46.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-arm64-v#{version}.tar.gz"
      sha256 "9952fd73fb09410a0452a0e0173fa4c1e91e412fb0a2a92286812b38b7654f02"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-amd64-v#{version}.tar.gz"
      sha256 "0d8dad56113f8d66b8ba9f49580ec39fb820f738e8c6a36b6308b2b884713b28"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-arm64-v#{version}.tar.gz"
      sha256 "3ea750e7523c6b68faa2e3ec4e9da9a3b18f3206135869db578396e9cc1bcb8d"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-amd64-v#{version}.tar.gz"
      sha256 "09f75d82d749bf7cc0a69df1828f760aaa966b2800b21e93c461a70be2ac5dd8"
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
      "-storageDataPath=#{var}/victorialogs@1.46.0-data",
    ]
    keep_alive false
    log_path var/"log/victorialogs@1.46.0.log"
    error_log_path var/"log/victorialogs@1.46.0.err.log"
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
