{ config, pkgs, ... }:

{
  services.zenfs.janitor = {

    # [ DUMB JANITOR ]
    dumb = {
      enable = true;
      interval = "5min";
      gracePeriod = 60;
      watchedDirs = [ "/home/cat/Downloads" ];
      rules = {
        "Android" = [
          "android.zip"
          "apk"
        ];
        "Pictures/Downloads" = [
          "jpg"
          "jpeg"
          "png"
          "gif"
          "webp"
          "svg"
          "heic"
          "avif"
          "ico"
        ];
        "Videos/Downloads" = [
          "mp4"
          "mkv"
          "mov"
          "webm"
          "avi"
          "flv"
        ];
        "Music/Downloads" = [
          "mp3"
          "flac"
          "wav"
          "ogg"
          "m4a"
          "opus"
        ];
        "Documents/Downloads" = [
          "pdf"
          "doc"
          "docx"
          "odt"
          "txt"
          "md"
          "epub"
          "ppt"
          "pptx"
          "xls"
          "xlsx"
          "csv"
        ];
        "Fonts/Downloads" = [
          "ttf"
          "otf"
          "woff"
          "woff2"
        ];
        "3D/Downloads" = [
          "blend"
          "obj"
          "fbx"
          "stl"
          "dae"
          "3ds"
        ];
        "AI/Downloads" = [
          "safetensors"
          "ckpt"
          "pt"
          "gguf"
        ];
        "Applications & Scripts/Downloads" = [
          "sh"
          "py"
          "deb"
          "rpm"
          "appimage"
          "run"
          "jar"
          "exe"
          "msi"
        ];
        "Android/Apks" = [ "apk" ];
        "Doom/WADs" = [
          "wad"
          "pk3"
        ];
        "Games/Switch" = [
          "nsp"
          "xci"
        ];
        "Games/3DS" = [
          "3ds"
          "cia"
        ];
        "Games/WiiU" = [
          "wux"
          "wud"
        ];
        "Games/Wii" = [ "wbfs" ];
        "Games/GameCube" = [
          "gcm"
          "iso"
        ];
        "Games/N64" = [
          "n64"
          "z64"
        ];
        "Games/SNES" = [
          "sfc"
          "smc"
        ];
        "Games/NES" = [ "nes" ];
        "Games/DS" = [
          "nds"
          "dsi"
        ];
        "Games/GBA" = [ "gba" ];
        "Games/GBC" = [ "gbc" ];
        "Games/GB" = [ "gb" ];
        "Games/PS3" = [
          "ps3.iso"
          "pkg"
        ];
        "Games/PS2" = [
          "ps2.iso"
          "gz"
        ];
        "Games/PS1" = [
          "cue"
          "bin"
        ];
        "Games/Xbox" = [ "xiso" ];
        "Games/Xbox360" = [ "iso" ];
        "Games/Dreamcast" = [
          "gdi"
          "cdi"
        ];
        "Games/Genesis" = [
          "md"
          "gen"
        ];
        "Games/Saturn" = [ "sat" ];
      };
    };

    # [ MUSIC JANITOR ]
    music = {
      enable = true;
      # tagging.enable = true; # Enable Swisstag
      musicDir = "/home/cat/Music";
      unsortedDir = "/home/cat/Music/.database";
      artistSplitSymbols = [ ";" ];
      interval = "1min";
    };
  };
}
