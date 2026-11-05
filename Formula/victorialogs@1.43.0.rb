class VictorialogsAT1430 < Formula
  desc "Fast and easy to use database for logs"
  homepage "https://docs.victoriametrics.com/victorialogs/"
  version "1.43.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of victorialogs"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-arm64-v#{version}.tar.gz"
      sha256 "28269396f9821144e075c2cae406e171e8ddef3e3a94ddd1504a02cde7220ba5"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-darwin-amd64-v#{version}.tar.gz"
      sha256 "314e901a8ec5e1accea8eeb291a0adb1c86053d5410dba1da439f608a158eed5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-arm64-v#{version}.tar.gz"
      sha256 "9b0ba9686180ceac846d0585d93e38417031a208d42f8858034ad8d1ca911662"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v#{version}/victoria-logs-linux-amd64-v#{version}.tar.gz"
      sha256 "01ccd5f0921107c22dc9cb7763fd60a50335b50abab47847a9b0d8919ddca653"
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
      "-storageDataPath=#{var}/victorialogs@1.43.0-data",
    ]
    keep_alive false
    log_path var/"log/victorialogs@1.43.0.log"
    error_log_path var/"log/victorialogs@1.43.0.err.log"
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
