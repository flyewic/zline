class Zline < Formula
  desc "fast line counter in zig"
  homepage "https://github.com/flyewic/zline"
  url "https://github.com/flyewic/zline/releases/download/v0.3.1/zline-x86_64-linux"
  sha256 "7a53caab2f26c81bad1204b69e0f753260b9983da5420f72d01e4cf36a1a8e95"
  version "0.3.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.3.1/zline-aarch64-macos"
      sha256 "8a65156404420b8dc168ff4c102b9da5b0502fd6f8d9d3469bf3d7248ac49d56"
    else
      url "https://github.com/flyewic/zline/releases/download/v0.3.1/zline-x86_64-macos"
      sha256 "b679760df40610ca828789fe02775f801e5615d0ccbb691607bf9c7a3be7b7af"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/flyewic/zline/releases/download/v0.3.1/zline-aarch64-linux"
      sha256 "248b5c76cfadde86bc5844ca3a1d89b504edfbe574cde5dd183b6c2a96a00b8d"
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
