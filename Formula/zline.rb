class Zline < Formula
  desc "fast line counter in zig"
  homepage "https://github.com/flyewic/zline"
  url "https://github.com/flyewic/zline/releases/download/v0.4.2/zline-x86_64-linux"
  sha256 "96bafbf4b17ff77d479b973962e55e066f5ea494d7158219e2273ee96f1780ab"
  version "0.4.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.4.2/zline-aarch64-macos"
      sha256 "eb47007a33976f803fe7190caa51f38324f040717e2ab55967970d80a127af04"
    else
      url "https://github.com/flyewic/zline/releases/download/v0.4.2/zline-x86_64-macos"
      sha256 "1b72f973b43adfa681cb0ad4780eee3bb75a47b954417c7ca9d558e6a259ba5b"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.4.2/zline-aarch64-linux"
      sha256 "8b50a727d319b099173bea9cde0aa4b88a45af7dbf4529310e1e581a50d69dd5"
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
