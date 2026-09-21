class Vmagent < Formula
  desc "Agent for collecting metrics and forwarding them to VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmagent/"
  version "1.152.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "22192226f8f6dd7e4950630c74fa4e32a4f08e1f220913f76b14db899977f2a1"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "8f7f98934c4ca27a48168217e6e28a16e74a69c9d7bbd9aed96ebd275a26051e"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "57c567b262962a4cb8e35c0c34efe64629a3e1ea69ac0611d8d67e168df8b1e8"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "8eee4a98ff1665c60682475e8a8b292b8d718b63a2f023124384dd2f6a220c79"
    end
  end

  def install
    bin.install "vmagent-prod" => "vmagent"

    scrape_config = etc/"vmagent/scrape.yml"
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
      The service scrapes targets from #{etc}/vmagent/scrape.yml and forwards
      metrics to a local VictoriaMetrics at http://127.0.0.1:8428/api/v1/write.
    EOS
  end

  service do
    run [
      opt_bin/"vmagent",
      "-httpListenAddr=127.0.0.1:8429",
      "-promscrape.config=#{etc}/vmagent/scrape.yml",
      "-remoteWrite.url=http://127.0.0.1:8428/api/v1/write",
      "-remoteWrite.tmpDataPath=#{var}/vmagent-remotewrite-data",
    ]
    keep_alive false
    log_path var/"log/vmagent.log"
    error_log_path var/"log/vmagent.err.log"
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
