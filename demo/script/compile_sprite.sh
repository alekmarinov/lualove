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

# Check if actions are present
has_action=0
missing_action=0
for action in "${ACTIONS[@]}"; do
    [ -d "$SRC_DIR/$action" ] && has_action=1
    [ -d "$SRC_DIR/$action" ] || missing_action=1
done

if [ $has_action -eq 1 -a $missing_action -eq 1 ]; then
  die "Missing some actions are missing from directory $SRC_DIR"
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

rm -f "$TMP_DIR"/*.png

# delete free-tex-packer project file
rm -f "$FREETEXPACKER_PROJECT"

# delete the target temp dir if not empty
if [ ! $(ls -A "$TMP_DIR") ]; then
  echo "rmdir $TMP_DIR"
  rmdir "$TMP_DIR"
fi
