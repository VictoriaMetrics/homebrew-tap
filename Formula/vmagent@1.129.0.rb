class VmagentAT11290 < Formula
  desc "Agent for collecting metrics and forwarding them to VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmagent/"
  version "1.129.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "a503c8c7d1d851316349f7527166d2f113e39051ff900dd24abc33e80c60fa28"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "7dae2f23801dd21338e7011b91eb8a1ceb569293bf1388e47041df02dc787d45"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "8ce77dd3717dc6cf5565b537d6533210049b9c4cbc56775f9b08a6e364d0e13e"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "9649ac7b96252c10640d61ff9e1042c2fbb2e8f4c9b1154be30036ac5e40665c"
    end
  end

  def install
    bin.install "vmagent-prod" => "vmagent"

    scrape_config = etc/"vmagent@1.129.0/scrape.yml"
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
      The service scrapes targets from #{etc}/vmagent@1.129.0/scrape.yml and forwards
      metrics to a local VictoriaMetrics at http://127.0.0.1:8428/api/v1/write.

      Only one version of vmagent can run as a service on port 8429 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmagent",
      "-httpListenAddr=127.0.0.1:8429",
      "-promscrape.config=#{etc}/vmagent@1.129.0/scrape.yml",
      "-remoteWrite.url=http://127.0.0.1:8428/api/v1/write",
      "-remoteWrite.tmpDataPath=#{var}/vmagent@1.129.0-remotewrite-data",
    ]
    keep_alive false
    log_path var/"log/vmagent@1.129.0.log"
    error_log_path var/"log/vmagent@1.129.0.err.log"
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
