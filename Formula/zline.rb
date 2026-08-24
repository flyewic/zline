class Zline < Formula
  desc "fast line counter in zig"
  homepage "https://github.com/flyewic/zline"
  url "https://github.com/flyewic/zline/releases/download/v0.5.0/zline-x86_64-linux"
  sha256 "1316ca8413299fca09ea2d2cdc357c37e4cb441670067252f9232d392d6c13b0"
  version "0.5.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.5.0/zline-aarch64-macos"
      sha256 "e54549531d8139e2d18f9c7ea6f5640fa52f84d51e3f41e2dca662be6c6ab765"
    else
      url "https://github.com/flyewic/zline/releases/download/v0.5.0/zline-x86_64-macos"
      sha256 "a1d1a21c2de578ce3e5274381285ec16adfceb48f0a56323f75e7d2fb90f6fc9"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.5.0/zline-aarch64-linux"
      sha256 "69ef6956f7384b1f8eb61551cb9ac7d7656f7424a4de7527de38212918b50921"
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
