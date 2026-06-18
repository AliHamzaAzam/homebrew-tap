class Repomon < Formula
  desc "Mission control for parallel AI coding agents across many repos"
  homepage "https://github.com/AliHamzaAzam/repomon"
  version "0.1.0"
  license "Apache-2.0"

  on_arm do
    url "https://github.com/AliHamzaAzam/repomon/releases/download/v#{version}/repomon-#{version}-aarch64-apple-darwin.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000" # aarch64
  end

  on_intel do
    url "https://github.com/AliHamzaAzam/repomon/releases/download/v#{version}/repomon-#{version}-x86_64-apple-darwin.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000" # x86_64
  end

  depends_on :macos
  depends_on "git"
  depends_on "tmux"

  head do
    url "https://github.com/AliHamzaAzam/repomon.git", branch: "main"
    depends_on "rust" => :build
  end

  def install
    if build.head?
      system "cargo", "install", "--locked", "--path", "crates/repomon-tui", "--root", prefix
      system "cargo", "install", "--locked", "--path", "crates/repomon-daemon", "--root", prefix
    else
      bin.install "repomon", "repomond"
    end

    generate_completions_from_executable(bin/"repomon", "completions", shells: [:bash, :zsh, :fish])
    (buildpath/"repomon.1").write Utils.safe_popen_read(bin/"repomon", "man")
    man1.install "repomon.1"
  end

  service do
    run [opt_bin/"repomond"]
    keep_alive true
    log_path "#{var}/log/repomon/repomond.out.log"
    error_log_path "#{var}/log/repomon/repomond.err.log"
  end

  def caveats
    <<~EOS
      Shell integration (cd-on-exit). Add to ~/.zshrc (or ~/.bashrc):
          eval "$(repomon shell-init zsh)"

      Optional: `brew install pngpaste` to paste clipboard images into agents.

      Run the daemon at login (optional — repomon auto-starts it on demand):
          brew services start repomon
      Don't also run `repomon daemon install`; pick one supervisor.

      iOS companion bridge: `repomon remote enable`, then `repomon remote pair`.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/repomon --version")
    assert_match version.to_s, shell_output("#{bin}/repomond --version")
    assert_match "repomon", shell_output("#{bin}/repomon completions zsh")
  end
end
