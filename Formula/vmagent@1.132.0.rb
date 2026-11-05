class VmagentAT11320 < Formula
  desc "Agent for collecting metrics and forwarding them to VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmagent/"
  version "1.132.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmagent"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "ea73fb27741f4f87dfaf9753bd280d187a9dd7be3569ecb0056609cf1ea9d817"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "ad9f7c3158f26dcacb006fc6ee7d9b233a0d0d7ded4ef5de795d7302379ef0f4"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "73e7469d536fd3508d406f804cd5a2a57bef9385d50ca81e20d65b63f39410b1"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "fd3eaa294050fc849931e8947212c736825a7a49e5509ee4555e288750861fc8"
    end
  end

  def install
    bin.install "vmagent-prod" => "vmagent"

    scrape_config = etc/"vmagent@1.132.0/scrape.yml"
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
      The service scrapes targets from #{etc}/vmagent@1.132.0/scrape.yml and forwards
      metrics to a local VictoriaMetrics at http://127.0.0.1:8428/api/v1/write.

      Only one version of vmagent can run as a service on port 8429 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmagent",
      "-httpListenAddr=127.0.0.1:8429",
      "-promscrape.config=#{etc}/vmagent@1.132.0/scrape.yml",
      "-remoteWrite.url=http://127.0.0.1:8428/api/v1/write",
      "-remoteWrite.tmpDataPath=#{var}/vmagent@1.132.0-remotewrite-data",
    ]
    keep_alive false
    log_path var/"log/vmagent@1.132.0.log"
    error_log_path var/"log/vmagent@1.132.0.err.log"
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
