class VictorialogsAT1370 < Formula
  desc "Fast and easy to use database for logs"
  homepage "https://docs.victoriametrics.com/victorialogs/"
  version "1.37.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-arm64-v#{version}.tar.gz"
      sha256 "82f48495e7e511c245e594bbaa37f418372eb9b3a76029ce2ee52236ee4085af"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-amd64-v#{version}.tar.gz"
      sha256 "53cbb96f904942ece5a4ce549be1b49b92c3e1174b4de18ea17bb76a7b2f3635"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-arm64-v#{version}.tar.gz"
      sha256 "82cbadff8c4f146372b135493ec22fed2ac5cc656e38c8b4511f59385001e94d"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-amd64-v#{version}.tar.gz"
      sha256 "74ae0eacc0694ced83b5e11b7484b84eca126bd22e778dfaddc0c8cb39086936"
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
      "-storageDataPath=#{var}/victorialogs@1.37.0-data",
    ]
    keep_alive false
    log_path var/"log/victorialogs@1.37.0.log"
    error_log_path var/"log/victorialogs@1.37.0.err.log"
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
