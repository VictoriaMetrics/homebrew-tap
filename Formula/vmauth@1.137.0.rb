class VmauthAT11370 < Formula
  desc "HTTP proxy, auth gateway and load balancer for VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmauth/"
  version "1.137.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "be68a77419a29ce841ac91aa47b05cd18dbd26429b776047bbd928773abd13e4"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "1ead39dbf01bbfb86ec2b3256616898988ac65450d681135d6f9af7058aad93f"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "785f4ca6aa0aeeff3012b0477eb2a158830ed82512e093997f8bd00e1ce519fc"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "192c782169201766c46b8264cc62f0cb154196f17882dd72fcd2910ffefa022e"
    end
  end

  def install
    bin.install "vmauth-prod" => "vmauth"

    auth_config = etc/"vmauth@1.137.0/auth.yml"
    return if auth_config.exist?

    auth_config.write <<~YAML
      unauthorized_user:
        url_prefix: "http://127.0.0.1:8428/"
    YAML
  end

  def caveats
    <<~EOS
      The service reads #{etc}/vmauth@1.137.0/auth.yml, which by default proxies
      unauthenticated requests to a local VictoriaMetrics at http://127.0.0.1:8428.

      Only one version of vmauth can run as a service on port 8427 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmauth",
      "-httpListenAddr=127.0.0.1:8427",
      "-auth.config=#{etc}/vmauth@1.137.0/auth.yml",
    ]
    keep_alive false
    log_path var/"log/vmauth@1.137.0.log"
    error_log_path var/"log/vmauth@1.137.0.err.log"
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
