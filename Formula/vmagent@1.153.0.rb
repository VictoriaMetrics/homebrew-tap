class VmagentAT11530 < Formula
  desc "Agent for collecting metrics and forwarding them to VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmagent/"
  version "1.153.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmagent"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "f6fb958d30666da21bcd190b908cc6714d1f2cb0e1938a6338ece0d45cb9f049"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "265e866cb20d489d8d9d2eaa914b9a19270c4f0f50a180eeb98f38c5676d8560"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "8153c4feb73564215950a299c803d5c1e974772cd34b8c162d43ea2c5b516df5"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "85aea24a4829cf26033d810aceb7888070bd4eaff321357168ff6db24bf7c00c"
    end
  end

  def install
    bin.install "vmagent-prod" => "vmagent"

    scrape_config = etc/"vmagent@1.153.0/scrape.yml"
    return if scrape_config.exist?

    scrape_config.write <<~YAML
      global:
        scrape_interval: 10s

      scrape_configs:
        - job_name: "vmagent"
          static_configs:
          - targets: ["127.0.0.1:8429"]
    YAML
  end

  def caveats
    <<~EOS
      The service scrapes targets from #{etc}/vmagent@1.153.0/scrape.yml and forwards
      metrics to a local VictoriaMetrics at http://127.0.0.1:8428/api/v1/write.

      Only one version of vmagent can run as a service on port 8429 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmagent",
      "-httpListenAddr=127.0.0.1:8429",
      "-promscrape.config=#{etc}/vmagent@1.153.0/scrape.yml",
      "-remoteWrite.url=http://127.0.0.1:8428/api/v1/write",
      "-remoteWrite.tmpDataPath=#{var}/vmagent@1.153.0-remotewrite-data",
    ]
    keep_alive false
    log_path var/"log/vmagent@1.153.0.log"
    error_log_path var/"log/vmagent@1.153.0.err.log"
  end

  test do
    http_port = free_port
    remote_write_port = free_port

    (testpath/"scrape.yml").write <<~YAML
      global:
        scrape_interval: 10s

      scrape_configs:
        - job_name: "vmagent"
          static_configs:
          - targets: ["127.0.0.1:#{http_port}"]
    YAML

    pid = spawn bin/"vmagent",
                "-httpListenAddr=127.0.0.1:#{http_port}",
                "-promscrape.config=#{testpath}/scrape.yml",
                "-remoteWrite.url=http://127.0.0.1:#{remote_write_port}/api/v1/write",
                "-remoteWrite.tmpDataPath=#{testpath}/vmagent-remotewrite-data"
    30.times do
      break if quiet_system("curl", "-fsS", "-o", File::NULL, "127.0.0.1:#{http_port}")

      sleep 1
    end
    assert_match "vmagent", shell_output("curl -s 127.0.0.1:#{http_port}")

    assert_match version.to_s, shell_output("#{bin}/vmagent --version")
  ensure
    begin
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      nil
    end
    Process.wait(pid)
  end
end
