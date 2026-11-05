class VictoriametricsAT11250 < Formula
  desc "Cost-effective and scalable monitoring solution and time series database"
  homepage "https://victoriametrics.com/"
  version "1.125.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of victoriametrics"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-arm64-v#{version}.tar.gz"
      sha256 "951acc953abbda30b1eae2329be2d85fd93c840bcadb9b41ebd9762ce4062059"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-amd64-v#{version}.tar.gz"
      sha256 "d4568dcb0f405d6e24a88052721adf914e87cd54b8359be1fb302fa9929db7a4"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-arm64-v#{version}.tar.gz"
      sha256 "d7dbb234b55d276290f91162b2e3f558e609a35f80a0b4c860e876cc141b04d6"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-amd64-v#{version}.tar.gz"
      sha256 "a7ecef608235094c1ae220168cb4fcce2ed5b3395a9275abd433846b9c10d2e7"
    end
  end

  def install
    bin.install "victoria-metrics-prod" => "victoria-metrics"

    scrape_config = etc/"victoriametrics@1.125.0/scrape.yml"
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
      "-promscrape.config=#{etc}/victoriametrics@1.125.0/scrape.yml",
      "-storageDataPath=#{var}/victoriametrics@1.125.0-data",
    ]
    keep_alive false
    log_path var/"log/victoriametrics@1.125.0.log"
    error_log_path var/"log/victoriametrics@1.125.0.err.log"
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
