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
    url "https://github.com/bytecapsule/doscapsule/releases/download/20261125-3/doscapsule-macos-arm64-20261125-3.zip"
    sha256 "d57ba134e377fa858c00ced9b9749dc26275491cfc470d888f53b0f0d147d993"
  else
    url "https://github.com/bytecapsule/doscapsule/releases/download/20261125-3/doscapsule-macos-x64-20261125-3.zip"
    sha256 "4310d604ce0cef0fb89ebc9d2f9418416e09c012b08854cde68af5dcb8b71324"
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
