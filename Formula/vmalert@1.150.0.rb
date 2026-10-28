class VmalertAT11500 < Formula
  desc "Executes alerting and recording rules against VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmalert/"
  version "1.150.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "98ddfd5c417f4370827e3d1e7e141aaa84f74043bb964f8e0ba718e5fa4db12b"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "54f6be1a19f91720a228f7d1004993cc5117e72a779322dd539f46f42793db0b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "4932627812458dc1c89dee7f4aa40d1980d6a546a4ee0eed7561392fd967c084"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "dbfb3a747d40de62142bcd6ec615377b27c346cced03763eba3cf6a8ba946bb7"
    end
  end

  def install
    bin.install "vmalert-prod" => "vmalert"
    (etc/"vmalert@1.150.0/rules").mkpath
  end

  def caveats
    <<~EOS
      The service loads rules from #{etc}/vmalert@1.150.0/rules/*.yml, queries a local
      VictoriaMetrics at http://127.0.0.1:8428 and sends alerts to a local
      Alertmanager at http://127.0.0.1:9093.

      Only one version of vmalert can run as a service on port 8880 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmalert",
      "-httpListenAddr=127.0.0.1:8880",
      "-rule=#{etc}/vmalert@1.150.0/rules/*.yml",
      "-datasource.url=http://127.0.0.1:8428",
      "-remoteWrite.url=http://127.0.0.1:8428",
      "-remoteRead.url=http://127.0.0.1:8428",
      "-notifier.url=http://127.0.0.1:9093",
    ]
    keep_alive false
    log_path var/"log/vmalert@1.150.0.log"
    error_log_path var/"log/vmalert@1.150.0.err.log"
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
