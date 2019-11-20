#!/bin/bash

# SPRITE_WIDTH=50
SPRITE_HEIGHT=32
ACTIONS=("Attacking" "Dying" "Idle" "Walking")

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_NAME=$(basename $0)

die() {
    echo "$SCRIPT_NAME: $1"
    exit 1
}

usage() {
    cat <<EOF
Compiles sprite sheet from directory with animation frame images
Usage: $SCRIPT_NAME [--flop] [--normalize] [--width WIDTH] [--height HEIGHT] -o <DST_DIR> SRC_DIR
Where:
    SRC_DIR         - Directory with *.png images or multiple directories with *.png image into each
    DST_DIR         - Directory where to store the output spritesheet png image and json description
    --normalize     - Normalize the image to its bounding box
    --width WIDTH   - The desired sprite width
    --height HEIGHT - The desired sprite height
    --flop          - Flip sprite horizontally
EOF
    die "$1"
}

flop=0
width=0
height=0
normalize=0
while [ "$1" != "" ]; do
    case $1 in
        --normalize)
          normalize=1
        ;;
        --width)
          shift
          width=$1
        ;;
        --height)
          shift
          height=$1
        ;;
        --flop)
          flop=1
        ;;
        -o|--output)
            shift
            DST_DIR="$1"
        ;;
        *)
            [ -z "$SRC_DIR" ] || usage "Unexpected argument $1"
            SRC_DIR="$1"
        ;;
    esac
    shift
done

if [ "$SRC_DIR" == "" ]; then
    usage "Missing expected SRC_DIR"
fi

if [ "$DST_DIR" == "" ]; then
    usage "Missing expected DST_DIR"
fi

if [ $width -eq 0 -a  $height -eq 0 ]; then
    usage "Either width or height must be non zero"
fi

SRC_DIR=${SRC_DIR%/}
DST_DIR=${DST_DIR%/}

SPRITE_NAME=$(basename "$SRC_DIR")

TMP_DIR="$DST_DIR/tmp"
mkdir -p "$TMP_DIR"

# Check if actions are present
has_action=0
missing_action=0
for action in "${ACTIONS[@]}"; do
    [ -d "$SRC_DIR/$action" ] && has_action=1
    [ -d "$SRC_DIR/$action" ] || missing_action=1
done

if [ $has_action -eq 1 -a $missing_action -eq 1 ]; then
  die "Some actions are missing from directory $SRC_DIR"
fi

# Copy desired actions from source sprite images to temp dir
if [ $has_action -eq 1 ]; then
  for action in "${ACTIONS[@]}"; do
      [ -d "$TMP_DIR/$action" ] && rm -f "$TMP_DIR/$action"/*
      cp -rf "$SRC_DIR/$action" "$TMP_DIR"/
  done
else
  # Copy all png files from src directory
  cp -f "$SRC_DIR"/*.png "$TMP_DIR"/
fi

# Normalize images to a common bounding box
if [ $normalize -eq 1 ]; then
  lua $SCRIPT_DIR/bounding_box.lua "$TMP_DIR"
fi

# Resize sprite images
find "$TMP_DIR" -type f -name "*.png" -print0 | while IFS= read -r -d '' file; do
  if [ $flop -eq 1 ]; then
    mogrify -flop "$file"
  fi
  RESIZE=""
  if [ $width -gt 0 ]; then
    RESIZE="$RESIZE"
  fi
  if [ $height -gt 0 ]; then
    RESIZE="${RESIZE}x$height"
  fi
  (set -x; mogrify -resize "$RESIZE" "$file")
done

FREETEXPACKER_PROJECT="$TMP_DIR/$SPRITE_NAME.ftpp"
# Create free-tex-packer project file
cat << EOF > "$FREETEXPACKER_PROJECT"
{
  "meta": {
    "version": "0.6.0"
  },
  "savePath": "$DST_DIR",
  "images": [],
  "folders": [
    "$TMP_DIR"
  ],
  "packOptions": {
    "textureName": "$SPRITE_NAME",
    "textureFormat": "png",
    "removeFileExtension": true,
    "prependFolderName": true,
    "base64Export": false,
    "tinify": false,
    "tinifyKey": "",
    "scale": 1,
    "filter": "none",
    "exporter": "JSON (hash)",
    "fileName": "pack-result",
    "savePath": "$TMP_DIR",
    "width": 2048,
    "height": 2048,
    "fixedSize": false,
    "powerOfTwo": false,
    "padding": 0,
    "extrude": 0,
    "allowRotation": false,
    "allowTrim": false,
    "trimMode": "trim",
    "alphaThreshold": "0",
    "detectIdentical": true,
    "packer": "MaxRectsPacker",
    "packerMethod": "SmartSquare"
  }
}
EOF

free-tex-packer-cli --project $FREETEXPACKER_PROJECT

# delete temp action files
for action in "${ACTIONS[@]}"; do
    rm -rf "$TMP_DIR/$action"
done

rm -f "$TMP_DIR"/*.png

# delete free-tex-packer project file
rm -f "$FREETEXPACKER_PROJECT"

# delete the target temp dir if not empty
if [ ! "$(ls -A $TMP_DIR)" ]; then
  rmdir "$TMP_DIR"
fi
