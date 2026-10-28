class VictoriametricsAT11340 < Formula
  desc "Cost-effective and scalable monitoring solution and time series database"
  homepage "https://victoriametrics.com/"
  version "1.134.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of victoriametrics"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-arm64-v#{version}.tar.gz"
      sha256 "8a6ad456c61b448c431cef4074ea255f2cde1db7b27c8ead01c72844d1ae8f0f"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-amd64-v#{version}.tar.gz"
      sha256 "765a64aaddc9a61cbbefb40b43ca3c4618f53733d876bfc1d0a71d6634ffbf0c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-arm64-v#{version}.tar.gz"
      sha256 "c1d10e05805c7dd789bf1af749bc3f8c5fef195e40a2e928e4708bfb5000dcfd"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-amd64-v#{version}.tar.gz"
      sha256 "cd6e109bae85ff7c138d838b32be9a7fe2a6d7a9b3a387a7cf9234f22991da10"
    end
  end

  def install
    bin.install "victoria-metrics-prod" => "victoria-metrics"

    scrape_config = etc/"victoriametrics@1.134.0/scrape.yml"
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
      "-promscrape.config=#{etc}/victoriametrics@1.134.0/scrape.yml",
      "-storageDataPath=#{var}/victoriametrics@1.134.0-data",
    ]
    keep_alive false
    log_path var/"log/victoriametrics@1.134.0.log"
    error_log_path var/"log/victoriametrics@1.134.0.err.log"
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
