class VmauthAT11550 < Formula
  desc "HTTP proxy, auth gateway and load balancer for VictoriaMetrics"
  homepage "https://docs.victoriametrics.com/victoriametrics/vmauth/"
  version "1.155.0"
  license "Apache-2.0"
  keg_only :versioned_formula

  on_macos do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-arm64-v#{version}.tar.gz"
      sha256 "30c316c0bfb840962a8b878a451acf6dcdae50294543b3a829d54ca0bb6674e1"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-darwin-amd64-v#{version}.tar.gz"
      sha256 "4adf38ac44c3fb1b7ed4773f5930f7f4a8e5b6553147a4ae87e56f2925e060af"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-arm64-v#{version}.tar.gz"
      sha256 "45fa04b8d616dd644c33c00698f22bbe67f9402bc474a1e6df8025f7e649d78f"
    end
    on_intel do
      url "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v#{version}/vmutils-linux-amd64-v#{version}.tar.gz"
      sha256 "b6181fc16cf19835706ea5d67215eea56c1fe87350fdfd82a5ff803ea2c1a907"
    end
  end

  def install
    bin.install "vmauth-prod" => "vmauth"

    auth_config = etc/"vmauth@1.155.0/auth.yml"
    return if auth_config.exist?

    auth_config.write <<~YAML
      unauthorized_user:
        url_prefix: "http://127.0.0.1:8428/"
    YAML
  end

  def caveats
    <<~EOS
      The service reads #{etc}/vmauth@1.155.0/auth.yml, which by default proxies
      unauthenticated requests to a local VictoriaMetrics at http://127.0.0.1:8428.

      Only one version of vmauth can run as a service on port 8427 at a time.
    EOS
  end

  service do
    run [
      opt_bin/"vmauth",
      "-httpListenAddr=127.0.0.1:8427",
      "-auth.config=#{etc}/vmauth@1.155.0/auth.yml",
    ]
    keep_alive false
    log_path var/"log/vmauth@1.155.0.log"
    error_log_path var/"log/vmauth@1.155.0.err.log"
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
