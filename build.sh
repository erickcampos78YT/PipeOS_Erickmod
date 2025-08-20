#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

OUT_IMG="PipeOS.img"
BOOT_BIN="boot.bin"
KERNEL_BIN="kernel.bin"
FLOPPY_SECTORS=2880   # 1.44MB
SECTOR_SIZE=512

assemble() {
  echo "[1/3] Assembling boot and kernel..."
  nasm -f bin boot.asm -o "$BOOT_BIN"
  nasm -f bin kernel.asm -o "$KERNEL_BIN"
}

make_image() {
  echo "[2/3] Creating ${OUT_IMG} (${FLOPPY_SECTORS} sectors)..."
  dd if=/dev/zero of="$OUT_IMG" bs=$SECTOR_SIZE count=$FLOPPY_SECTORS status=none

  echo "[3/3] Writing bootloader to sector 0..."
  dd if="$BOOT_BIN" of="$OUT_IMG" conv=notrunc status=none

  echo "      Writing kernel starting at sector 1..."
  dd if="$KERNEL_BIN" of="$OUT_IMG" bs=$SECTOR_SIZE seek=1 conv=notrunc status=none
}

info() {
  echo ""
  echo "Artifacts:"
  if command -v stat >/dev/null 2>&1; then
    stat -c "  %n: %s bytes" "$BOOT_BIN" "$KERNEL_BIN" "$OUT_IMG" 2>/dev/null || true
  else
    ls -l "$BOOT_BIN" "$KERNEL_BIN" "$OUT_IMG" 2>/dev/null || true
  fi
  echo ""
}

run_qemu_floppy() {
  local qemu_cmd=(qemu-system-i386 -boot a -fda "$OUT_IMG")
  echo "Running (floppy): ${qemu_cmd[*]}"
  "${qemu_cmd[@]}"
}

usage() {
  echo "Usage: $0 [build|run|clean]"
  exit 1
}

cmd=${1:-build}
case "$cmd" in
  build)
    assemble
    make_image
    info
    echo "Done. To run (floppy): qemu-system-i386 -boot a -fda $OUT_IMG"
    ;;
  run)
    assemble
    make_image
    info
    run_qemu_floppy
    ;;
  clean)
    rm -f "$BOOT_BIN" "$KERNEL_BIN" "$OUT_IMG"
    echo "Cleaned artifacts."
    ;;
  *)
    usage
    ;;
esac