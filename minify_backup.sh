#!/bin/bash -e

########################################################################
#   Set environment variables
FILETYPES_AUDIO=( mp3 )
FILETYPES_IMAGE=( bmp gif jpeg jpg png tif tiff )
FILETYPES_OTHER=( zip )
FILETYPES_PDF=( pdf )
FILETYPES_VIDEO=( avi flv mp4 mpeg )

RESOURCES_DIRECTORY="`dirname $(readlink -f $0)`/Resources"
DUMMY_EMPTY="${RESOURCES_DIRECTORY}/empty.txt"
DUMMY_PDF="${RESOURCES_DIRECTORY}/dummy.pdf"

RSYNC_EXCLUDE=( )
RSYNC_OPTIONS="--archive --partial --delete-after --delete-excluded --quiet"

CONVERT_OPTIONS="-colors 256 -quality 10"

########################################################################
#   Assign command line arguments to local variables
ARGUMENTS=:s:t:aiopv

if ( ! getopts ${ARGUMENTS} OPTION); then
    echo "Usage: `basename $0` -s SYSTEMSTORAGE -t MINFIEDSYSTEMSTORAGE [-a] [-i] [-o] [-p] [-v]" >&2
    exit 1
fi

while getopts ${ARGUMENTS} OPTION; do
    case ${OPTION} in
        s)
            SOURCE_PATH="`readlink -f ${OPTARG}`/"
            ;;
        t)
            TARGET_PATH="`readlink -f ${OPTARG}`/"
            ;;
        a)
            MINIFY_AUDIO=1
            RSYNC_EXCLUDE=( ${RSYNC_EXCLUDE[@]} ${FILETYPES_AUDIO[@]} )
            ;;
        i)
            MINIFY_IMAGE=1
            RSYNC_EXCLUDE=( ${RSYNC_EXCLUDE[@]} ${FILETYPES_IMAGE[@]} )
            ;;
        o)
            MINIFY_OTHER=1
            RSYNC_EXCLUDE=( ${RSYNC_EXCLUDE[@]} ${FILETYPES_OTHER[@]} )
            ;;
        p)
            MINIFY_PDF=1
            RSYNC_EXCLUDE=( ${RSYNC_EXCLUDE[@]} ${FILETYPES_PDF[@]} )
            ;;
        v)
            MINIFY_VIDEO=1
            RSYNC_EXCLUDE=( ${RSYNC_EXCLUDE[@]} ${FILETYPES_VIDEO[@]} )
            ;;
        \?)
            echo "Illegal option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option requires an argument: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

########################################################################
#   Check preconditions
if [ ! -d ${SOURCE_PATH} ]; then
    echo "ERROR: Source directory ${SOURCE_PATH} does not exist."
    exit 1
fi

########################################################################
#   Function definitions
function convertToUppercase() {
    echo $1 | tr [:lower:] [:upper:]
}

function getRsyncExcludes() {
    for EXTENSION in "${RSYNC_EXCLUDE[@]}"; do
        echo "--exclude *.${EXTENSION} "
        echo "--exclude *.$(convertToUppercase ${EXTENSION}) "
    done
}

function replaceFiletypeWithDummyFile() {
    find ${SOURCE_PATH} \( -name "*.$1" -o -name "*.$(convertToUppercase $1)" \) | while read FILENAME; do
       cp $2 "${TARGET_PATH}${FILENAME#${SOURCE_PATH}}"
    done
}

function compressImages() {
    find ${SOURCE_PATH} \( -name "*.$1" -o -name "*.$(convertToUppercase $1)" \) | while read FILENAME; do
        convert ${CONVERT_OPTIONS} "${FILENAME}" "${TARGET_PATH}${FILENAME#${SOURCE_PATH}}" || true
    done
}

########################################################################
#   Sync and minify systemstorage
echo -n "Syncing unprocessed files: "
rsync ${RSYNC_OPTIONS} $(getRsyncExcludes) ${SOURCE_PATH} ${TARGET_PATH}
echo "done."

if [ ${MINIFY_AUDIO} ]; then
    echo -n "Minifying audio files: "
    for EXTENSION in "${FILETYPES_AUDIO[@]}"; do
        echo -n "${EXTENSION} "
        replaceFiletypeWithDummyFile ${EXTENSION} ${DUMMY_EMPTY}
    done
    echo "done."
fi

if [ ${MINIFY_IMAGE} ]; then
    echo -n "Minifying image files... "
    for EXTENSION in "${FILETYPES_IMAGE[@]}"; do
        echo -n "${EXTENSION} "
        compressImages ${EXTENSION}
    done
    echo "done."
fi

if [ ${MINIFY_PDF} ]; then
    echo -n "Minifying pdf files... "
    for EXTENSION in "${FILETYPES_PDF[@]}"; do
        echo -n "${EXTENSION} "
        replaceFiletypeWithDummyFile ${EXTENSION} ${DUMMY_PDF}
    done
    echo "done."
fi

if [ ${MINIFY_VIDEO} ]; then
    echo -n "Minifying video files... "
    for EXTENSION in "${FILETYPES_VIDEO[@]}"; do
        echo -n "${EXTENSION} "
        replaceFiletypeWithDummyFile ${EXTENSION} ${DUMMY_EMPTY}
    done
    echo "done."
fi

if [ ${MINIFY_OTHER} ]; then
    echo -n "Minifying other files... "
    for EXTENSION in "${FILETYPES_OTHER[@]}"; do
        echo -n "${EXTENSION} "
        replaceFiletypeWithDummyFile ${EXTENSION} ${DUMMY_EMPTY}
    done
    echo "done."
fi
