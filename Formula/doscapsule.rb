# Homebrew formula for doscapsule.
#
# Two zips are published per release - macos-arm64 (Apple Silicon) and macos-x64 (Intel) -
# and the formula picks by host CPU, so both are native (no Rosetta).
#
# `dosbox-staging` is a HARD dependency: brew installs it automatically when
# absent, matching the host architecture.
#
# Users: brew tap bytecapsule/doscapsule && brew install doscapsule
#
# Maintainers: after publishing a release, run
#   scripts/update-packaging.sh <tag>
# to rewrite the tag and both sha256 values below.

class Doscapsule < Formula
  desc "Pure-local DOS game launcher (SolidJS UI embedded in a Go binary)"
  homepage "https://github.com/bytecapsule/doscapsule"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/bytecapsule/doscapsule/releases/download/20261125-4/doscapsule-macos-arm64-20261125-4.zip"
    sha256 "2b052553d38f712aae2a05e4a0cfed69e11e69ab553c8bdea1db382a1b1a2168"
  else
    url "https://github.com/bytecapsule/doscapsule/releases/download/20261125-4/doscapsule-macos-x64-20261125-4.zip"
    sha256 "09c5333343689ceb8c21763d9aab674575a231da82356b54521dc6d57b65bb93"
  end

  # Hard dependency: brew installs DOSBox Staging automatically if absent.
  depends_on "dosbox-staging"

  def install
    bin.install "doscapsule"
  end

  test do
    assert_match(/DOS Capsule/, shell_output("#{bin}/doscapsule -version"))
    assert_predicate Formula["dosbox-staging"].opt_bin/"dosbox-staging", :exist?
  end
end
