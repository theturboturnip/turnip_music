set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

default:
    @just --list

generate:
    dart run build_runner build
    just plugins/android_music_store/generate

dbg-mac:
    flutter run -d macos

# dbg-web:
#     dart run sqflite_common_ffi_web:setup
#     flutter run -d Chrome

dbg-windows:
    flutter run -d Windows

dbg-android:
    flutter run -d RZC

rel-android:
    flutter run -d RZC --release

run-build-runner:
    dart run build_runner build

test:
    flutter test