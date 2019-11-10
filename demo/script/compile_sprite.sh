SPRITE_WIDTH=50
ACTIONS=("Attacking" "Dying" "Hurt" "Idle" "Idle Blink" "Taunt" "Walking")

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

die() {
    echo "$1"
    exit 1
}

SRC_DIR="$1"
DST_DIR="$2"

if [ "$SRC_DIR" == "" ]; then
    die "Source directory argument 1 is mendatory"
fi

if [ "$DST_DIR" == "" ]; then
    die "Destination directory argument 2 is mendatory"
fi

SRC_DIR=${SRC_DIR%/}
DST_DIR=${DST_DIR%/}

SPRITE_NAME=$(basename "$SRC_DIR")

TMP_DIR="$DST_DIR/tmp"
mkdir -p "$TMP_DIR"

# Copy desired actions from source sprite images to temp dir
for action in "${ACTIONS[@]}"; do
    [ -d "$TMP_DIR/$action" ] && rm -f "$TMP_DIR/$action"/*
    cp -rf "$SRC_DIR/$action" "$TMP_DIR"/
done

# Resize sprite images
find "$TMP_DIR" -type f -name "*.png" -print0 | while IFS= read -r -d '' file; do
    mogrify -resize $SPRITE_WIDTH "$file"
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

# delete free-tex-packer project file
rm -f "$FREETEXPACKER_PROJECT"

# delete the target temp dir if not empty
if [ ! $(ls -A "$TMP_DIR") ]; then
    rmdir "$TMP_DIR"
fi
