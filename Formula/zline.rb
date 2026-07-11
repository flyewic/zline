class Zline < Formula
  desc "fast line counter in zig"
  homepage "https://github.com/flyewic/zline"
  url "https://github.com/flyewic/zline/releases/download/v0.3.4/zline-x86_64-linux"
  sha256 "4f59af0cbb2cd356de5e6af7bccc1073c0bc0f692f7e3eb14f6d806affc40f3c"
  version "0.3.4"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.3.4/zline-aarch64-macos"
      sha256 "f7e7f4b502e627105c2bce817ddce9898b5e7d2e51863bd50bde5134ad888c83"
    else
      url "https://github.com/flyewic/zline/releases/download/v0.3.4/zline-x86_64-macos"
      sha256 "2d1a41faedf7b471821de5719ca90c1fa8acd8585f375e44ec38e230289f454f"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.3.4/zline-aarch64-linux"
      sha256 "ce1b5ef4fa24e7e588cb71147a7969c3ca8f06d1f4e956928bb93172d9405675"
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
