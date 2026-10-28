class VictoriametricsAT11490 < Formula
  desc "Cost-effective and scalable monitoring solution and time series database"
  homepage "https://victoriametrics.com/"
  version "1.149.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of victoriametrics"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-arm64-v#{version}.tar.gz"
      sha256 "8bcb60ea1300fa92b4a1e6d520f15dd9ae3afe98d9d62230feb79e0dbcfe8f7b"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-amd64-v#{version}.tar.gz"
      sha256 "7b257b82a8362d8899a19172d5c2f248cfee6143e152e4c75fad18fc481067bc"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-arm64-v#{version}.tar.gz"
      sha256 "4364b2dffe8f532c28bd427307d1609248696f25d837678bf86410059f5b9b85"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-amd64-v#{version}.tar.gz"
      sha256 "6695fbee54bca58b78162ddf785c387b24641e57dfe4f3f743fb241f41dc3697"
    end
  end

  def install
    bin.install "victoria-metrics-prod" => "victoria-metrics"

    scrape_config = etc/"victoriametrics@1.149.0/scrape.yml"
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
      "-promscrape.config=#{etc}/victoriametrics@1.149.0/scrape.yml",
      "-storageDataPath=#{var}/victoriametrics@1.149.0-data",
    ]
    keep_alive false
    log_path var/"log/victoriametrics@1.149.0.log"
    error_log_path var/"log/victoriametrics@1.149.0.err.log"
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
