#!/bin/bash


trap cleanup EXIT
declare -l input



cleanup(){
    echo ""
    echo "cleanup started."
    shopt -u nocaseglob
    shopt -u globstar
    rm -rf "$processing"
    rm -rf "$pathtemp"
    echo "cleanup over."
}



textureconverter(){
TARGET_DIR="$1"

shopt -s nocaseglob
shopt -s globstar

if [ ! -d "$TARGET_DIR" ]; then
    echo "$TARGET_DIR does not exist!"
    return 1
fi

echo "Starting recursive texture conversion in $TARGET_DIR/"

converted=0
skipped=0

for ext in jpeg jpg bmp tiff tif webp tga; do
    for file in "$TARGET_DIR"/**/*.$ext; do
        # Check if file actually exists (glob might not match anything)
        if [ -f "$file" ]; then
            # Get base filename without extension
            base_name="${file%.*}"
            
            # Check if PNG already exists
            if [ -f "$base_name.png" ]; then
                echo "Skipping: $file - PNG already exists"
                ((skipped++))
                continue
            fi
            
            echo "Converting: $file -> $base_name.png"
            
            # Convert to PNG
            magick "$file" "$base_name.png" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                # Remove original file after successful conversion
                rm "$file"
                ((converted++))
            else
                echo "Error converting $file"
            fi
        fi
    done
done

echo "Converted $converted file(s) to PNG"
echo "Skipped $skipped file(s) (PNG already exists as an alternative)"
echo ""
echo "Running todds compression on the requested directory. go grab a coffee or something, this is gonna take a while."
todds -f BC7 -af BC7 -q 7 -fs -mf LANCZOS -mb 0.55 -o -t -p -vf "$TARGET_DIR/"
    
if [ $? -eq 0 ]; then
    echo "texture conversion successfully completed."
else
    echo "Error: todds command failed"
    return 1
fi
}



location(){
if [ "$1" == "steam" ]
then
    if [ -e "$2" ]
    then
        steamappspath="$2"
    fi
elif [ "$1" == "fix" ]
then
    if [ -e "$2" ]
    then
        return 0
    else
        mkdir -p "$2"
    fi
elif [ "$1" == "check" ]
then
    if [ -e "$2" ]
    then
        locationstatus="0"
        return 0
    else
        locationstatus="1"
        return 1
    fi
fi
}



resetprocessing() {
    rm -rf "$processing"
    mkdir -p "$processing"
}



compress() {
echo "beginning compression of folder: $2"
echo "please do not modify the folder that is currently being compressed."

if [ "$verbosetaroutput" == "1" ]
then
    if [ "$3" == "final" ]
    then
        tar -I 'zstd -T0 -1' -cvf "$1" -C "$(dirname "$2")" "$(basename "$2")"
    else
        tar -I 'zstd -T0 -15' -cvf "$1" -C "$(dirname "$2")" "$(basename "$2")"
    fi
elif [ "$verbosetaroutput" == "0" ]
then
    if [ "$3" == "final" ]
    then
        tar -I 'zstd -T0 -1' -cf "$1" -C "$(dirname "$2")" "$(basename "$2")"
    else
        tar -I 'zstd -T0 -15' -cf "$1" -C "$(dirname "$2")" "$(basename "$2")"
    fi
fi

temp="$?"
if [ "$temp" == "0" ]
then
    echo "compression of $2 has been successful!"
else
    echo "compression of $2 has failed. exiting."
    exit 1
fi

tar -I 'zstd -T0' -df "$1" -C "$(dirname "$2")" "$(basename "$2")"
temp="$?"
if [ "$temp" == "0" ]
then
    echo "confirmation of $2 has been successful!"
    return 0
else
    echo "confirmation of $2 has failed. exiting."
    exit 1
fi
}



locationstatus="UNSET"
steamappspath="UNSET"

location "steam" "$HOME/.local/share/Steam/steamapps"
location "steam" "$HOME/.steam/steam/steamapps"
location "steam" "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps"
location "steam" "$HOME/snap/steam/common/.local/share/Steam/steamapps"

echo "your steamapps location has been autodetected as '$steamappspath', is that path correct?"
echo "y/n:"
read input
if [ "$input" == "y" ]
then
    echo "proceeding."
else
    echo "please type in the correct path of where your steamapps directory is. do not include a '/' at the end of the path."
    echo "path:"
    read temp
    steamappspath="$temp"
fi

rimworldpath="$steamappspath/common/RimWorld"
localmodspath="$rimworldpath/Mods"
steammodspath="$steamappspath/workshop/content/294100"
configpath="$HOME/.config/unity3d/Ludeon Studios/RimWorld by Ludeon Studios"
rimsortconfigpath="$HOME/.local/share/RimSort"
root="$HOME/Documents/RimWorldArchivalTool"
processing="$root/processing"
pathtemp="$root/temp"

location "fix" "$root"
location "fix" "$processing"
location "fix" "$pathtemp"
if [ ! -d "$rimsortconfigpath" ]
then
    echo "RimSort's config folder could not be found. do you have RimSort installed?"
fi

if [ ! -d "$configpath" ]
then
    echo "RimWorld's config folder could not be found. do you have RimWorld installed? have you ever ran RimWorld?"
fi

if [ ! -d "$rimworldpath" ]
then
    echo "RimWorld could not be found. exiting."
    exit 1
fi

if [ ! -d "$localmodspath" ]
then
    echo "RimWorld's local mods folder could not be found. exiting."
    exit 1
fi



echo "Checking for required packages..."
missing_packages=()
if ! command -v todds &> /dev/null; then missing_packages+=("todds"); fi
if ! command -v rsync &> /dev/null; then missing_packages+=("rsync"); fi
if ! command -v tar &> /dev/null; then missing_packages+=("tar"); fi
if ! command -v zstd &> /dev/null; then missing_packages+=("zstd"); fi
if ! command -v magick &> /dev/null; then missing_packages+=("ImageMagick 7.0+"); fi
shopt -s globstar 2>/dev/null || missing_packages+=("globstar or bash 4.0")
if [ "${#missing_packages[@]}" -gt "0" ]
then
    echo "you are missing these packages:"
    echo "${missing_packages[@]}"
    echo "exiting."
    exit 1
else
    echo "all required packages are installed. proceeding."
fi



echo "would you like to use the archive tool, or just the standalone texture optimizer / compresser?"
echo "type in 'texture' for the texture tool, and do not type anything for the archival tool."
read input

if [ "$input" == "texture" ]
then
    echo "Initiating standalone texture tool. which one of these would you like to optimize: your steam mods, your local mods, or a custom directory? type in 'steam', 'local', or 'custom'."
    read input
    if [ "$input" == "steam" ]
    then
        textureconverter "$steammodspath"
    elif [ "$input" == "local" ]
    then
        textureconverter "$localmodspath"
    elif [ "$input" == "custom" ]
    then
        echo "please give the FULL PATH of the directory where the textures / mods you want to optimize are."
        read dir
        if [ -d "$dir" ]
        then
            textureconverter "$dir"
        else
            echo "that filepath does not exist."
            exit 1
        fi
    fi
    exit 0
fi



echo "this script is a very CPU-heavy script. you will not be able to do other CPU / computationally heavy tasks (including gaming!) while this is running."
echo "please type y or n for yes or no."
echo "please have all mods that you want to have archived, ready in the rimworld local mods folder. using rimsort's 'Convert Steam mod to local' feature is recommended for this."
echo "do not modify ANY of the folders that are being used, and do not use any apps that modify those folders (example, dont use rimsort, rimworld, dont install new mods from steam, etc...)"
echo "start the script?"
echo "y/n:"
read input
if [ "$input" == "n" ]
then
    echo "please have the dependencies and mods ready before running this script."
    exit 0
fi
echo "do you want to have the tar compression output be verbose?"
echo "y/n:"
read input
if [ "$input" == "y" ]
then
    echo "understood. tar's output WILL be verbose.."
    verbosetaroutput="1"
elif [ "$input" == "n" ]
then
    echo "understood. tar's output will NOT be verbose.."
    verbosetaroutput="0"
else
    echo "invalid input. verbose output will remain disabled (default)."
    verbosetaroutput="0"
fi

resetprocessing

echo "starting script."
echo "processing the game."
rsync -a --exclude='Mods' "$rimworldpath/" "$processing/RimWorld"
compress "$processing/RimworldGame.tar.zstd" "$processing/RimWorld"
mv "$processing/RimworldGame.tar.zstd" "$pathtemp/"

resetprocessing

echo "processing mods."
cp -r "$localmodspath" "$processing/Mods"
echo "would you like to turn all textures into .dds textures? this is recommended to reduce your VRAM usage. results may vary. WARNING: this will take a lot of time and processing power."
echo "y/n:"
read input
if [ "$input" == "y" ]
then
    textureconverter "$processing/Mods"
else
    echo "skipping .dds conversion."
fi
compress "$processing/RimworldLocalMods.tar.zstd" "$processing/Mods"
mv "$processing/RimworldLocalMods.tar.zstd" "$pathtemp/"
echo ""
echo "would you like your local mods folder to be erased? this is an irreversible operation."
echo "y/n:"
read input
if [ "$input" == "y" ]
then
    rm -rf "$localmodspath"/*
else
    echo "Proceeding without deleting your local mods file. this may cause issues while trying to run rimworld."
fi

resetprocessing

echo "processing config."
cp -r "$configpath" "$processing"
compress "$processing/RimworldConfig.tar.zstd" "$processing/RimWorld by Ludeon Studios"
mv "$processing/RimworldConfig.tar.zstd" "$pathtemp/"

resetprocessing

echo "processing RimSort config."
cp -r "$rimsortconfigpath" "$processing"
compress "$processing/RimSortConfig.tar.zstd" "$processing/RimSort"
mv "$processing/RimSortConfig.tar.zstd" "$pathtemp/"

resetprocessing

compress "$root/RimworldArchived.tar.zstd" "$pathtemp/" "final"

echo "Rimworld archived and packaged. have a nice day!"
