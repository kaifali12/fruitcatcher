# Sound assets

The game loads these short clips on startup. Drop matching files in this folder.
If a file is missing the game falls back to silent + a haptic vibration, so the
project still runs without any audio.

| Filename       | Played when                              | Suggested length |
|----------------|------------------------------------------|------------------|
| catch.mp3      | A fruit/vegetable is caught              | 0.2 – 0.5 s      |
| bomb.mp3       | A bomb is caught (explosion)             | 0.5 – 1.0 s      |
| level_up.mp3   | The player advances to the next level    | 0.5 – 1.5 s      |
| bg_music.mp3   | Background music — loops during play     | 30 – 120 s loop  |
| game_over.mp3  | Final life is lost                       | 1.0 – 2.0 s      |

## Where to grab royalty-free clips

- https://freesound.org
- https://mixkit.co/free-sound-effects/game/
- https://pixabay.com/sound-effects/search/game/

After adding files, just `flutter pub get` and run — assets are already wired
up in `pubspec.yaml`.
