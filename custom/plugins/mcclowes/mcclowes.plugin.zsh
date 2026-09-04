# Add your own custom plugins in the custom/plugins directory. Plugins placed
# here will override ones with the same name in the main plugins directory.

## --------------- Custom Functions ---------------

function editZSH {
  subl ~/.zshrc;
}

## Create react app with custom scripts
function mcclowes-react-scripts {
  dirName="${1:-new-project}"
  create-react-app --scripts-version mcclowes-react-scripts $dirName;
}

# reboot shell, updating shells path
function reboot-shell {
  exec "$SHELL"
}

function cabal-list {
  echo "DUCSGS >>> cabal cabal://2836d9c5a5971490b930b271b35bb86bcfff3937f46e8bd8980586f2015f1111";
}

function mcclowes {
  echo "editZSH - Edit zshrc config";
  echo "mcclowes-react-scripts < project name : new-project > - create new react project using mcclowes-scripts create react app config";
  echo "reboot-shell- reboot shell";
  echo "cabal-list - list cabal servers";
}