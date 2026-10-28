class VictoriatracesAT050 < Formula
  desc "Fast and easy to use database for distributed traces"
  homepage "https://docs.victoriametrics.com/victoriatraces/"
  version "0.5.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-arm64-v#{version}.tar.gz"
      sha256 "ac5eb6ec1eb8152b03b43a34f27f9d050c8b6c7d6bac13891df550f1fe8f9cea"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-darwin-amd64-v#{version}.tar.gz"
      sha256 "4ab044a6f40d823bb22eca66d2d46332f165df600536bf722d95992bbc4864e5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-arm64-v#{version}.tar.gz"
      sha256 "a089dbbf8cbc7676373e873b0408e04e629da591b9c44bd148e8effa988892bd"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaTraces/releases/download/v#{version}/victoria-traces-linux-amd64-v#{version}.tar.gz"
      sha256 "bd9d27ff5b0061d8d4f883107fd21f656b9c8c89dd1889072104eaed484df760"
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
      "-storageDataPath=#{var}/victoriatraces@0.5.0-data",
    ]
    keep_alive false
    log_path var/"log/victoriatraces@0.5.0.log"
    error_log_path var/"log/victoriatraces@0.5.0.err.log"
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
