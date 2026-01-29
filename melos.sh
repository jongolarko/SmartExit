#!/bin/bash
# Helper script to run Melos commands on Windows

MELOS="C:\Users\arkoc\AppData\Local\Pub\Cache\bin\melos.bat"

case "$1" in
  bootstrap)
    echo "Bootstrapping packages..."
    cd packages/smartexit_core && flutter pub get
    cd ../smartexit_services && flutter pub get
    cd ../smartexit_shared && flutter pub get
    ;;
  analyze)
    echo "Running flutter analyze..."
    cd packages/smartexit_core && flutter analyze
    cd ../smartexit_services && flutter analyze
    cd ../smartexit_shared && flutter analyze
    ;;
  *)
    echo "Usage: ./melos.sh {bootstrap|analyze}"
    exit 1
    ;;
esac
