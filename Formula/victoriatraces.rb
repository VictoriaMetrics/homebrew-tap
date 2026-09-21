class Victoriatraces < Formula
  desc "Fast and easy to use database for distributed traces"
  homepage "https://docs.victoriametrics.com/victoriatraces/"
  version "0.11.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-arm64-v#{version}.tar.gz"
      sha256 "06dfee9581fadb5c05cbc214f46a1599d6d1453eb9658df4554d2c44588250e2"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-amd64-v#{version}.tar.gz"
      sha256 "62c9a80b0443aa2d888b60bc9879b30e0a1e7d1547134ca3ba4ec27b54983489"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-arm64-v#{version}.tar.gz"
      sha256 "c258b0b26276b80654635d667ca0aff0d61f546ea591b9de95f0127636e351ad"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-amd64-v#{version}.tar.gz"
      sha256 "ac831f2ed12806caa29b8369bb9e0a0fcd8153029f631e4784f51f83420c7f30"
    end
  end

  def install
    bin.install "victoria-traces-prod" => "victoria-traces"
  end

  service do
    run [
      opt_bin/"victoria-traces",
      "-httpListenAddr=127.0.0.1:10428",
      "-storageDataPath=#{var}/victoriatraces-data",
    ]
    keep_alive false
    log_path var/"log/victoria-traces.log"
    error_log_path var/"log/victoria-traces.err.log"
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
