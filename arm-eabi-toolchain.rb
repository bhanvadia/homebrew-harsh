require 'formula'

# This installs James Snyder's Makefile for building and installing the
# arm-none-eabi GCC toolchain from Code Sourcery

class CodeSourcerySource < Formula
  url 'http://sourcery.mentor.com/sgpp/lite/arm/portal/package9739/public/arm-none-eabi/arm-2011.09-69-arm-none-eabi.src.tar.bz2', :using => NoUnzipCurlDownloadStrategy
  md5 'ebe25afa276211d0e88b7ff0d03c5345'
end

class CodeSourceryBinaries < Formula
  url 'http://sourcery.mentor.com/sgpp/lite/arm/portal/package9740/public/arm-none-eabi/arm-2011.09-69-arm-none-eabi.i686-pc-linux-gnu.tar.bz2', :using => NoUnzipCurlDownloadStrategy
  md5 '2f2d73429ce70dfb848d7b44b3d24d3f'
end

class ArmEabiToolchain < Formula
  head 'git://github.com/jsnyder/arm-eabi-toolchain.git'
  url 'https://github.com/jsnyder/arm-eabi-toolchain/tarball/v2011.09-69'
  homepage 'https://github.com/jsnyder/arm-eabi-toolchain'
  md5 'e268a363ff01c531c7bc6da32393f003'

  depends_on 'mpfr'
  depends_on 'gmp'
  depends_on 'libmpc'
  depends_on 'libelf'

  def options
    [
      ['--with-cs-extras', "Install additional Codesourcery tools"],
      ['--match-cs', "Match the original Codesourcery options more closely."],
      ['--opt-newlib-size', "Optimize newlib for size"]
    ]
  end

  # Don't strip compilers
  skip_clean :all

  fails_with :clang do
    cause "GCC requires a version of GCC to build (even LLVM-GCC)"
  end

  def install
    # For the same reasons as the GCC formula, we unset LD.
    ENV.delete 'LD'
    # We can't use _any_ fancy compiler options as they interfere with gcc.
    ENV.cc_flag_vars.each do |var|
      ENV.delete var
    end
    ENV.delete 'CPPFLAGS'
    ENV.delete 'LDFLAGS'
    unless HOMEBREW_PREFIX.to_s == '/usr/local'
      ENV['CPPFLAGS'] = "-I#{HOMEBREW_PREFIX}/include"
      ENV['LDFLAGS'] = "-L#{HOMEBREW_PREFIX}/lib"
    end
    ENV.set_cflags "-Os -w -pipe"

    # GCC doesn't set up an alias for cc
    mkdir_p "#{prefix}/toolchain/bin"
    ln_s "arm-none-eabi-gcc", "#{prefix}/toolchain/bin/arm-none-eabi-cc"
    # The Makefile tries, but fails to do this properly
    ENV.prepend 'PATH', "#{prefix}/toolchain/bin", ':'

    # This Makefile handles parallelization itself
    ENV.j1

    args = [ "PREFIX=#{prefix}/toolchain" ]
    tarballs = [ CodeSourcerySource ]
    if ARGV.include? '--match-cs'
      args << 'MATCH_CS=1'
    end
    if ARGV.include? '--opt-newlib-size'
      args << 'OPT_NEWLIB_SIZE=1'
    end
    if ARGV.include? '--with-cs-extras'
      args << 'install-bin-extras'
      tarballs << CodeSourceryBinaries
    end

    # Use the stubby formulas above for Homebrew's caching
    source_dir = Pathname.new Dir.pwd
    tarballs.each do |tarball|
      tarball.new.brew do |brewed|
        cp brewed.cached_download, source_dir
      end
    end

    system 'make', 'install-cross', *args

    ln_s prefix+'toolchain/bin', prefix+'bin'
    ln_s prefix+'toolchain/share', prefix+'share'
  end
end
