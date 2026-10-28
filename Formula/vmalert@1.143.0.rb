class VmalertAT11430 < Formula
  desc "Executes alerting and recording rules against VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmalert/"
  version "1.143.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmalert"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "a7b0ebc9b724707bb6dbe5d8dd298347aa501c031be83bd9bbf91a8a0477bf6b"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "bed21b998b5a51b313afe12a79cab272e6f5d6c95821055a58cca1f311a1e88e"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "e636c40dcb2ba39c7d837449e3609772d01162b82d96cb35e7bfba52cc6acdb1"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "a2f6f1cec8233c34b3df7ade591adbadbedfa79b96e8845565d3fd75d1d604f7"
    end
  end

  def install
    bin.install "vmalert-prod" => "vmalert"
    (etc/"vmalert@1.143.0/rules").mkpath
  end

  def caveats
    <<~EOS
      The service loads rules from #{etc}/vmalert@1.143.0/rules/*.yml, queries a local
      VictoriaMetrics at http://127.0.0.1:8428 and sends alerts to a local
      Alertmanager at http://127.0.0.1:9093.

      Only one version of vmalert can run as a service on port 8880 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmalert",
      "-httpListenAddr=127.0.0.1:8880",
      "-rule=#{etc}/vmalert@1.143.0/rules/*.yml",
      "-datasource.url=http://127.0.0.1:8428",
      "-remoteWrite.url=http://127.0.0.1:8428",
      "-remoteRead.url=http://127.0.0.1:8428",
      "-notifier.url=http://127.0.0.1:9093",
    ]
    keep_alive false
    log_path var/"log/vmalert@1.143.0.log"
    error_log_path var/"log/vmalert@1.143.0.err.log"
  end

  test do
    http_port = free_port
    datasource_port = free_port

    (testpath/"rules.yml").write <<~YAML
      groups:
        - name: brewtest
          rules:
            - alert: AlwaysFiring
              expr: vector(1)
    YAML

    pid = spawn bin/"vmalert",
                "-httpListenAddr=127.0.0.1:#{http_port}",
                "-rule=#{testpath}/rules.yml",
                "-datasource.url=http://127.0.0.1:#{datasource_port}",
                "-notifier.blackhole"
    30.times do
      break if quiet_system("curl", "-fsS", "-o", File::NULL, "127.0.0.1:#{http_port}")

      sleep 1
    end
    assert_match "brewtest", shell_output("curl -s 127.0.0.1:#{http_port}/api/v1/rules")

    assert_match version.to_s, shell_output("#{bin}/vmalert --version")
  ensure
    begin
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      nil
    end
    Process.wait(pid)
  end
end
