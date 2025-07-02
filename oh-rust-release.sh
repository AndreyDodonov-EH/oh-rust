#!/bin/bash
# _oh-rust-release.sh

# Detect OS
detect_os() {
    if [[ -n "$MSYSTEM" ]] || [[ "$OS" == "Windows_NT" ]]; then
        echo "windows"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

OS_TYPE=$(detect_os)

# Build the Rust compiler
if [[ "$OS_TYPE" == "windows" ]]; then
    python x.py build --stage 2 library
else
    # Ensure x.py is executable
    [[ -x "x.py" ]] || chmod +x x.py
    
    # Try python3 first, fall back to python
    if command -v python3 &> /dev/null; then
        python3 x.py build --stage 2 library
    else
        ./x.py build --stage 2 library
    fi
fi 

# Set your target triple
TARGET=$(rustc -vV | grep host | cut -d' ' -f2)
BUILD_DIR="build/$TARGET/stage2"

# Verify build exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: $BUILD_DIR not found."
    case "$OS_TYPE" in
        windows)
            echo "Run: python x.py build --stage 2 library"
            ;;
        *)
            echo "Run: ./x.py build --stage 2 library"
            ;;
    esac
    exit 1
fi

# Create distribution directory
DIST_DIR="oh-rust-dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy all necessary files
cp -r "$BUILD_DIR"/* "$DIST_DIR/"

# After copying to $DIST_DIR, clean up based on OS
echo "Cleaning up build artifacts..."

if [[ "$OS_TYPE" == "windows" ]]; then
    # Remove PDB files (huge on Windows)
    find "$DIST_DIR" -name "*.pdb" -delete
    
    # Remove static libraries (not needed for running)
    find "$DIST_DIR" -name "*.lib" -delete
fi

# Remove LLVM static libs (all platforms, these are HUGE)
rm -rf "$DIST_DIR/lib/rustlib/$TARGET/lib/*.rlib" 2>/dev/null || true

# Remove test files
find "$DIST_DIR" -name "*test*" -type f -delete 2>/dev/null || true

# Optional: Strip binaries (reduces size further)
if [[ "$OS_TYPE" != "windows" ]]; then
    find "$DIST_DIR/bin" -type f -executable -exec strip {} \; 2>/dev/null || true
fi

# Include version info
RUSTC_BIN="./build/$TARGET/stage2/bin/rustc"
if [[ "$OS_TYPE" == "windows" ]]; then
    RUSTC_BIN="${RUSTC_BIN}.exe"
fi

# Create version file
cat > "$DIST_DIR/OH-RUST-VERSION" << EOF
Oh-Rust - The Rust That Truly Hates You
Built from stage2
$("$RUSTC_BIN" --version)
Build date: $(date)
Target: $TARGET
Platform: $OS_TYPE
EOF

# Create tarball
tar -czf "oh-rust-latest-$TARGET.tar.gz" -C "$DIST_DIR" .

# Cleanup
rm -rf "$DIST_DIR"

echo "Created oh-rust-latest-$TARGET.tar.gz (stage2)"
