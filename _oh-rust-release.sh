#!/bin/bash
# package-oh-rust.sh

# Build the Rust compiler (stage 2 means that we re-build it with itself, ensuring ABI consistency)
./x.py build --stage 2 

# Set your target triple
TARGET=$(rustc -vV | grep host | cut -d' ' -f2)
BUILD_DIR="build/$TARGET/stage2"  # Use stage2!

# Verify build exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: $BUILD_DIR not found."
    echo "Run: ./x.py build --stage 2"end
    exit 1
fi

# Create distribution directory
DIST_DIR="oh-rust-dist"
rm -rf $DIST_DIR
mkdir -p $DIST_DIR

# Copy all necessary files
cp -r $BUILD_DIR/* $DIST_DIR/

# Include version info
cat > $DIST_DIR/OH-RUST-VERSION << EOF
Oh-Rust - The Rust That Truly Hates You
Built from stage2 (self-hosted)
$(./build/$TARGET/stage2/bin/rustc --version)
Build date: $(date)
EOF

# Create tarball
tar -czf oh-rust-latest-$TARGET.tar.gz -C $DIST_DIR .

# Cleanup
rm -rf $DIST_DIR

echo "Created oh-rust-latest-$TARGET.tar.gz (stage2)"
