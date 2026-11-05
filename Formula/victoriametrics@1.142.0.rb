class VictoriametricsAT11420 < Formula
  desc "Cost-effective and scalable monitoring solution and time series database"
  homepage "https://victoriametrics.com/"
  version "1.142.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of victoriametrics"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-arm64-v#{version}.tar.gz"
      sha256 "149dc46583d19b373618714ed5eb0a8bfa0f2f23eda6357fbf02bb61b0733ef2"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-darwin-amd64-v#{version}.tar.gz"
      sha256 "da5849450d0efdcef72539df2b359c8c36617f3f6ca7677b32d97cdd42b5c1ee"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-arm64-v#{version}.tar.gz"
      sha256 "6051937d5cab34eb3f02171e0f68e2ad8119ce368c8e7d4e766739e5afc002a2"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/victoria-metrics-linux-amd64-v#{version}.tar.gz"
      sha256 "878e09069184d4cc86297e1f0574f2a78f5ebfce87dd1d32b286abf13aad4f85"
    end
  end

  def install
    bin.install "victoria-metrics-prod" => "victoria-metrics"

    scrape_config = etc/"victoriametrics@1.142.0/scrape.yml"
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
      "-promscrape.config=#{etc}/victoriametrics@1.142.0/scrape.yml",
      "-storageDataPath=#{var}/victoriametrics@1.142.0-data",
    ]
    keep_alive false
    log_path var/"log/victoriametrics@1.142.0.log"
    error_log_path var/"log/victoriametrics@1.142.0.err.log"
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
