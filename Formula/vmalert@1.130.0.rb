class VmalertAT11300 < Formula
  desc "Executes alerting and recording rules against VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmalert/"
  version "1.130.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "f8fbd2429388076f231d9a58e231f9ccf081c68121f0af2fb9f6ae416fa63dbb"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "c74a5f1d39c3f920bcc41204ca8252f5518b97c3c1570c765010ccbd06728b4f"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "ec728e91a86dcc4502db75a49e9439d4356f242a1fab36002fc17d75df8d0e60"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "1c9d28b933099b19022bda125421a986c3e8ccb79f4b5cb4ca9fc5acad2d840b"
    end
  end

  def install
    bin.install "vmalert-prod" => "vmalert"
    (etc/"vmalert@1.130.0/rules").mkpath
  end

  def caveats
    <<~EOS
      The service loads rules from #{etc}/vmalert@1.130.0/rules/*.yml, queries a local
      VictoriaMetrics at http://127.0.0.1:8428 and sends alerts to a local
      Alertmanager at http://127.0.0.1:9093.

      Only one version of vmalert can run as a service on port 8880 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmalert",
      "-httpListenAddr=127.0.0.1:8880",
      "-rule=#{etc}/vmalert@1.130.0/rules/*.yml",
      "-datasource.url=http://127.0.0.1:8428",
      "-remoteWrite.url=http://127.0.0.1:8428",
      "-remoteRead.url=http://127.0.0.1:8428",
      "-notifier.url=http://127.0.0.1:9093",
    ]
    keep_alive false
    log_path var/"log/vmalert@1.130.0.log"
    error_log_path var/"log/vmalert@1.130.0.err.log"
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
