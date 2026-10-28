class VictorialogsAT1480 < Formula
  desc "Fast and easy to use database for logs"
  homepage "https://docs.victoriametrics.com/victorialogs/"
  version "1.48.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-arm64-v#{version}.tar.gz"
      sha256 "bf468d7ff2212f40cd2fdc4c998bd1bea6b479fad43c972cb14e57206a19a42e"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-amd64-v#{version}.tar.gz"
      sha256 "17d7923d86a0a959ad83055e8dfcae1bd135d31292663960cd5dd7fca1cd7fcb"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-arm64-v#{version}.tar.gz"
      sha256 "fce5b29903aa6dc053a2c7156df3a95d113c1acfbc66bd1739b80a3d8f1fba64"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-amd64-v#{version}.tar.gz"
      sha256 "53cd856243a8ed866a6ed81744d22c358da2e6b134111b89f344af8e8d4bad76"
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
      "-storageDataPath=#{var}/victorialogs@1.48.0-data",
    ]
    keep_alive false
    log_path var/"log/victorialogs@1.48.0.log"
    error_log_path var/"log/victorialogs@1.48.0.err.log"
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
