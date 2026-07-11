class Zline < Formula
  desc "fast line counter in zig"
  homepage "https://github.com/flyewic/zline"
  url "https://github.com/flyewic/zline/releases/download/v0.4.0/zline-x86_64-linux"
  sha256 "f883140b0360550238ea1543e6230bf5981e7bc9dfd18e676568047f96e640a2"
  version "0.4.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.4.0/zline-aarch64-macos"
      sha256 "634e0f9ed54fc69bed6f2443a245e2d469f8e3a4b722f00fc678f3215e346d7c"
    else
      url "https://github.com/flyewic/zline/releases/download/v0.4.0/zline-x86_64-macos"
      sha256 "4da1e6b4bf1804050ed7f6ed3d519531f4af4858d5574983ea1951ab07349559"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.4.0/zline-aarch64-linux"
      sha256 "1685138f6f8591f75f8f18ed27a6c85e801419489d58abc57fb95b45969b65eb"
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
