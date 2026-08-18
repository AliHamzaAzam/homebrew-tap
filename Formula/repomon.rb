class Repomon < Formula
  desc "Fleet control for parallel AI coding agents across many repos"
  homepage "https://github.com/AliHamzaAzam/repomon"
  version "0.7.2"
  license "Apache-2.0"

  # Per-arch prebuilt binaries: each architecture's archive has its own sha256.
  if Hardware::CPU.arm?
    url "https://github.com/AliHamzaAzam/repomon/releases/download/v#{version}/repomon-#{version}-aarch64-apple-darwin.tar.gz"
    sha256 "61a135baa02313386cde885154b71bef3396734556a2c7fbe4c001480a183e2e" # aarch64
  else
    url "https://github.com/AliHamzaAzam/repomon/releases/download/v#{version}/repomon-#{version}-x86_64-apple-darwin.tar.gz"
    sha256 "50e9265bdf63abcff2a3dd7e37081ec723448158d0a7087bdcc4934fa63bb977" # x86_64
  end

  head do
    url "https://github.com/AliHamzaAzam/repomon.git", branch: "main"
    depends_on "rust" => :build
  end

  depends_on "git"
  depends_on :macos
  depends_on "tmux"

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

      Remote access bridge (open; iOS app coming): `repomon remote enable`, then `repomon remote pair`.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/repomon --version")
    assert_match version.to_s, shell_output("#{bin}/repomond --version")
    assert_match "repomon", shell_output("#{bin}/repomon completions zsh")
  end
end
