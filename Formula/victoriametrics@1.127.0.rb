class VictoriametricsAT11270 < Formula
  desc "Cost-effective and scalable monitoring solution and time series database"
  homepage "https://victoriametrics.com/"
  version "1.127.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-arm64-v#{version}.tar.gz"
      sha256 "d89335c385fa38430e9c93301620483c60de8f6f3431f93014cc5b4e20e33bad"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-amd64-v#{version}.tar.gz"
      sha256 "6372d57ab0568a073dad49be56c653de6cfa1a6049614fe4f79f91ee14cf268b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-arm64-v#{version}.tar.gz"
      sha256 "a4a38a108e8f20d2070def7a874d31e3c1a87f35c532e1857fdf64ec73d4e098"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-amd64-v#{version}.tar.gz"
      sha256 "9bc663a86880908646240b3fa6c3997ef8d8ff40933fec0c245149263674d4b1"
    end
  end

  def install
    bin.install "victoria-metrics-prod" => "victoria-metrics"

    scrape_config = etc/"victoriametrics@1.127.0/scrape.yml"
    return if scrape_config.exist?

    scrape_config.write <<~YAML
      global:
        scrape_interval: 10s

      scrape_configs:
        - job_name: "victoriametrics"
          static_configs:
          - targets: ["127.0.0.1:8428"]
    YAML
  end

  def caveats
    <<~EOS
      Only one version of victoriametrics can run as a service on port 8428 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"victoria-metrics",
      "-httpListenAddr=127.0.0.1:8428",
      "-promscrape.config=#{etc}/victoriametrics@1.127.0/scrape.yml",
      "-storageDataPath=#{var}/victoriametrics@1.127.0-data",
    ]
    keep_alive false
    log_path var/"log/victoriametrics@1.127.0.log"
    error_log_path var/"log/victoriametrics@1.127.0.err.log"
  end

  test do
    http_port = free_port

    (testpath/"scrape.yml").write <<~YAML
      global:
        scrape_interval: 10s

      scrape_configs:
        - job_name: "victoriametrics"
          static_configs:
          - targets: ["127.0.0.1:#{http_port}"]
    YAML

    pid = spawn bin/"victoria-metrics",
                "-httpListenAddr=127.0.0.1:#{http_port}",
                "-promscrape.config=#{testpath}/scrape.yml",
                "-storageDataPath=#{testpath}/victoriametrics-data"
    30.times do
      break if quiet_system("curl", "-fsS", "-o", File::NULL, "127.0.0.1:#{http_port}")

      sleep 1
    end
    assert_match "Single-node VictoriaMetrics", shell_output("curl -s 127.0.0.1:#{http_port}")

    assert_match version.to_s, shell_output("#{bin}/victoria-metrics --version")
  ensure
    begin
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      nil
    end
    Process.wait(pid)
  end
end
