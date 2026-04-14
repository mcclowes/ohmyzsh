## image manipulation
function imgRemoveWhiteBackground {
  fileType="${1:-png}"
  blurRad="${2:-20}"
  find . -type f -name *.$fileType -print0 | while IFS= read -r -d $'\0' file; do 
    convert -verbose $file -fuzz $blurRad% -transparent white "$file"; 
  done
}

function imgMaxSize {
  maxSize="${1:-1500}"
  fileType="${2:-png}"
  for file in *.$fileType ; do 
    convert -verbose $file -thumbnail "$maxSizex$maxSize" ./$file ; 
  done
}

function imgConvertFormat {
  fromFileType="${1:-png}"
  toFileType="${2:-jpg}"
  for file in *.$fromFileType ; do 
    convert -verbose $file "$( echo "./$file.$toFileType" | sed -e "s/\.$fromFileType//" )" ; 
  done
}

function imgMaxSizeConvertTiny {
  maxSize="${1:-1500}"
  fromFileType="${2:-png}"
  toFileType="${3:-jpg}"
  imgMaxSize $maxSize $fromFileType;
  imgConvertFormat $fromFileType $toFileType;
  tinypng;
}

# Make folder x
# Move all files that match y -> x
function mvImgToFolder {
  mkdir ${2} && mv ${1}* ./${2}   
}

# rename all files by creation date
function renameImgByDate {
  for f in *.*; do
    fn=$(basename "$f")
    mv "$fn" "$(date -r "$f" +"%Y-%m-%d_%H-%M-%S")_$fn"
  done
}


function imagetools {
  echo "imgRemoveWhiteBackground < file type : png > < blur radius (tolerance) : 20 > - Bulk remove white background from all images in dir of specified format";
  echo "imgMaxSize < largest h or w in pixels : 1500 > - Bulk contain image sizes by each largest dimension";
  echo "imgConvertFormat < target format : png > <destination format : jpeg > - Bulk convert images from target format to destination format";
  echo "imgMaxSizeConvertTiny < largest h or w in pixels : 1500 > < target format : png > <destination format : jpeg > - All of the above combined";
}