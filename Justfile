set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

default:
    @just --list

generate:
    dart run build_runner build
    just plugins/android_music_store/generate

dbg_android:
    flutter run -d RZ8