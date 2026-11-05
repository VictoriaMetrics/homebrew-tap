class VmauthAT11500 < Formula
  desc "HTTP proxy, auth gateway and load balancer for VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmauth/"
  version "1.150.0"
  license "Apache-2.0"
  # a custom reason: Homebrew auto-links :versioned_formula kegs when the plain formula is absent
  keg_only "it is an older release of vmauth"

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "98ddfd5c417f4370827e3d1e7e141aaa84f74043bb964f8e0ba718e5fa4db12b"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "54f6be1a19f91720a228f7d1004993cc5117e72a779322dd539f46f42793db0b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "4932627812458dc1c89dee7f4aa40d1980d6a546a4ee0eed7561392fd967c084"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "dbfb3a747d40de62142bcd6ec615377b27c346cced03763eba3cf6a8ba946bb7"
    end
  end

  def install
    bin.install "vmauth-prod" => "vmauth"

    auth_config = etc/"vmauth@1.150.0/auth.yml"
    return if auth_config.exist?

    auth_config.write <<~YAML
      unauthorized_user:
        url_prefix: "http://127.0.0.1:8428/"
    YAML
  end

  def caveats
    <<~EOS
      The service reads #{etc}/vmauth@1.150.0/auth.yml, which by default proxies
      unauthenticated requests to a local VictoriaMetrics at http://127.0.0.1:8428.

      Only one version of vmauth can run as a service on port 8427 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmauth",
      "-httpListenAddr=127.0.0.1:8427",
      "-auth.config=#{etc}/vmauth@1.150.0/auth.yml",
    ]
    keep_alive false
    log_path var/"log/vmauth@1.150.0.log"
    error_log_path var/"log/vmauth@1.150.0.err.log"
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
