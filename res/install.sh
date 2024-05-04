#!/usr/bin/env bash

echo -e "\n\n"

get_latest_release() {
  curl -Ls --silent "https://github.com/shripadk/figma-linux-font-helper/releases/latest" | perl -ne 'print "$1\n" if /v([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,4})/' | head -1;
}

get_latest_release_link_download() {
  local latest=$(get_latest_release);
  echo "http://github.com/shripadk/figma-linux-font-helper/releases/download/v${latest}/fonthelper.tar.xz"
}

download() {
  local link=$(get_latest_release_link_download);

  cd /tmp;
  rm -rf ./fonthelper.tar*
  wget "$link";
}


install() {
  DATA_DIR=$HOME/.local/share
  CONFIG_DIR=$HOME/.config
  APP_DATA_DIR=$DATA_DIR/figma-fonthelper
  APP_CONFIG_DIR=$CONFIG_DIR/figma-linux

  mkdir -p $APP_DATA_DIR
  mkdir -p $APP_CONFIG_DIR

  if [ ! -f $APP_CONFIG_DIR/settings.json ]; then
  cat > $APP_CONFIG_DIR/settings.json << EOF
{
  "host": "127.0.0.1",
  "port": "44950",
  "app": {
    "fontDirs": [
      "/usr/share/fonts",
      "$DATA_DIR/fonts"
    ]
  }
}
EOF
  fi

  pushd $APP_DATA_DIR
  tar xJf /tmp/fonthelper.tar.xz ./fonthelper
  tar xJf /tmp/fonthelper.tar.xz ./updater.sh
  chmod +x ./fonthelper ./updater.sh
  popd

  mkdir -p $CONFIG_DIR/systemd/user
  pushd $CONFIG_DIR/systemd/user

  tar xJOf /tmp/fonthelper.tar.xz ./figma-fonthelper.service | envsubst > figma-fonthelper.service
  tar xJOf /tmp/fonthelper.tar.xz ./figma-fonthelper-updater.service | envsubst > figma-fonthelper-updater.service

  chmod 644 figma-fonthelper.service
  chmod 644 figma-fonthelper-updater.service
  popd

  systemctl --user daemon-reload

  systemctl --user start figma-fonthelper.service
  systemctl --user start figma-fonthelper-updater.service

  systemctl --user enable figma-fonthelper.service
  systemctl --user enable figma-fonthelper-updater.service

  systemctl --user -q status figma-fonthelper.service
  systemctl --user -q status figma-fonthelper-updater.service

  rm -rf ./fonthelper.tar*
}

main() {
  download
  install
}

main;
