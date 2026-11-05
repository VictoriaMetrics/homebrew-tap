class VmauthAT11270 < Formula
  desc "HTTP proxy, auth gateway and load balancer for VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmauth/"
  version "1.127.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmauth"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "ea438d89012fdec7b623ab051661fd12dc4bbfe8ef3e95587422619cc2cf0900"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "595b509f75cdcfd536305c0177700969601188a2019f31c70102483a8dfb58c6"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "db92d7444284ac6c2539056232751c0483a067e374abe621edd6312b9f0844ed"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "7590e0f9a4a2a336f5115abba285645d26a6a2ae481c230407b5f17bdeeabbb4"
    end
  end

  def install
    bin.install "vmauth-prod" => "vmauth"

    auth_config = etc/"vmauth@1.127.0/auth.yml"
    return if auth_config.exist?

    auth_config.write <<~YAML
      unauthorized_user:
        url_prefix: "http://127.0.0.1:8428/"
    YAML
  end

  def caveats
    <<~EOS
      The service reads #{etc}/vmauth@1.127.0/auth.yml, which by default proxies
      unauthenticated requests to a local VictoriaMetrics at http://127.0.0.1:8428.

      Only one version of vmauth can run as a service on port 8427 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmauth",
      "-httpListenAddr=127.0.0.1:8427",
      "-auth.config=#{etc}/vmauth@1.127.0/auth.yml",
    ]
    keep_alive false
    log_path var/"log/vmauth@1.127.0.log"
    error_log_path var/"log/vmauth@1.127.0.err.log"
  end

  test do
    http_port = free_port
    backend_port = free_port

    (testpath/"auth.yml").write <<~YAML
      unauthorized_user:
        url_prefix: "http://127.0.0.1:#{backend_port}/"
    YAML

    pid = spawn bin/"vmauth",
                "-httpListenAddr=127.0.0.1:#{http_port}",
                "-auth.config=#{testpath}/auth.yml"
    30.times do
      break if quiet_system("curl", "-fsS", "-o", File::NULL, "127.0.0.1:#{http_port}/health")

      sleep 1
    end
    assert_match "OK", shell_output("curl -s 127.0.0.1:#{http_port}/health")

    assert_match version.to_s, shell_output("#{bin}/vmauth --version")
  ensure
    begin
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      nil
    end
    Process.wait(pid)
  end
end
