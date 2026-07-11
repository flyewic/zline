class Zline < Formula
  desc "fast line counter in zig"
  homepage "https://github.com/flyewic/zline"
  url "https://github.com/flyewic/zline/releases/download/v0.3.0/zline-x86_64-linux"
  sha256 "a68eddb18a258b2eeb7344506d2c131a8869158ae1d3ad9bb37e6a3439795592"
  version "0.3.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.3.0/zline-aarch64-macos"
      sha256 "PASTE_SHA256_FOR_zline-aarch64-macos_HERE"
    else
      url "https://github.com/flyewic/zline/releases/download/v0.3.0/zline-x86_64-macos"
      sha256 "PASTE_SHA256_FOR_zline-x86_64-macos_HERE"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.3.0/zline-aarch64-linux"
      sha256 "PASTE_SHA256_FOR_zline-aarch64-linux_HERE"
    end
  end

  def install
    if OS.mac?
      if Hardware::CPU.arm?
        bin.install "zline-aarch64-macos" => "zline"
      else
        bin.install "zline-x86_64-macos" => "zline"
      end
    else
      if Hardware::CPU.arm?
        bin.install "zline-aarch64-linux" => "zline"
      else
        bin.install "zline-x86_64-linux" => "zline"
      end
    end
  end

  test do
    system "#{bin}/zline", "--version"
  end
end
