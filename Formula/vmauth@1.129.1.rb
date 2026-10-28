class VmauthAT11291 < Formula
  desc "HTTP proxy, auth gateway and load balancer for VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmauth/"
  version "1.129.1"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "15889060895a7a23610c3c9df7bf1a3b6f4b611076bfcedef5df405845fed685"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "4bbc6fa17822e8ec2ae0bbf507e5a156c53c66155d50a107678562039840aac4"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "7cc44a17430026aae1a3120c891bccbdcc2ad9d549f58bb1fc8a98b6a4f85f1f"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "9bc376f47bbb19879755b0490152f3e69fc41d78b3641021d674659287ff136e"
    end
  end

  def install
    bin.install "vmauth-prod" => "vmauth"

    auth_config = etc/"vmauth@1.129.1/auth.yml"
    return if auth_config.exist?

    auth_config.write <<~YAML
      unauthorized_user:
        url_prefix: "http://127.0.0.1:8428/"
    YAML
  end

  def caveats
    <<~EOS
      The service reads #{etc}/vmauth@1.129.1/auth.yml, which by default proxies
      unauthenticated requests to a local VictoriaMetrics at http://127.0.0.1:8428.

      Only one version of vmauth can run as a service on port 8427 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmauth",
      "-httpListenAddr=127.0.0.1:8427",
      "-auth.config=#{etc}/vmauth@1.129.1/auth.yml",
    ]
    keep_alive false
    log_path var/"log/vmauth@1.129.1.log"
    error_log_path var/"log/vmauth@1.129.1.err.log"
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
