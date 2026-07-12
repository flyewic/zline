class Zline < Formula
  desc "fast line counter in zig"
  homepage "https://github.com/flyewic/zline"
  url "https://github.com/flyewic/zline/releases/download/v0.4.3/zline-x86_64-linux"
  sha256 "de443e50589340c8cff1464aafe33588460066effa63a979754c82c9f1b6ad9c"
  version "0.4.3"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.4.3/zline-aarch64-macos"
      sha256 "5a6d3d1bed0eb02930d30928afa880c756a9b59cdd9943ee34eed684fe431433"
    else
      url "https://github.com/flyewic/zline/releases/download/v0.4.3/zline-x86_64-macos"
      sha256 "3768b033f1d4d4d5dc25d9d34731d04e9ef98eff7bd5ed1385b273a9ecf4d87d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.4.3/zline-aarch64-linux"
      sha256 "e3dd0d107aab85a3d1bfd0ca43e959b86826d21bc244e72fd25d85ee783a314e"
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
