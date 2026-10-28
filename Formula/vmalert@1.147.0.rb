class VmalertAT11470 < Formula
  desc "Executes alerting and recording rules against VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmalert/"
  version "1.147.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "32dca771ff1830f98760aab86a92fdfcfb60e8b9588d908eb1ff0f5e90e0bcaf"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "ec9aed148da71c346507138ac1f35fa3f0a9cef6797c02a42e9dc7b5ab14629a"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "0348ec940845fe35197310dd49df0620fca840d43e67d75616ba55eebd7e6edb"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "1e5da38c3d8d7af9c4fc0daa8a2103f2578c40ed81752d21f20a3bd6d0506b3f"
    end
  end

  def install
    bin.install "vmalert-prod" => "vmalert"
    (etc/"vmalert@1.147.0/rules").mkpath
  end

  def caveats
    <<~EOS
      The service loads rules from #{etc}/vmalert@1.147.0/rules/*.yml, queries a local
      VictoriaMetrics at http://127.0.0.1:8428 and sends alerts to a local
      Alertmanager at http://127.0.0.1:9093.

      Only one version of vmalert can run as a service on port 8880 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmalert",
      "-httpListenAddr=127.0.0.1:8880",
      "-rule=#{etc}/vmalert@1.147.0/rules/*.yml",
      "-datasource.url=http://127.0.0.1:8428",
      "-remoteWrite.url=http://127.0.0.1:8428",
      "-remoteRead.url=http://127.0.0.1:8428",
      "-notifier.url=http://127.0.0.1:9093",
    ]
    keep_alive false
    log_path var/"log/vmalert@1.147.0.log"
    error_log_path var/"log/vmalert@1.147.0.err.log"
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
