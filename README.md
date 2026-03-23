# Tiwee

An IPTV player developed for android/ios devices with flutter

You can watch cahnnel's from all over the world
You can access channel by selecting your desired country or by category type

UI inspired from : <a href="https://dribbble.com/shots/14754204-IPTVify-App-Ui-Design">Mohammad Reza Farahzad</a>

[<img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroid.png"
     alt="Get it on IzzyOnDroid"
     height="80">](https://apt.izzysoft.de/fdroid/index/apk/com.example.Tiwee)

Vidoe demo =>

https://user-images.githubusercontent.com/32876834/186907325-03c3055b-5691-4af2-a8b7-f77dae5c699c.mp4

Want to contribute? I would really appreciate a hand with the development to add more features in this app. Feel free to Fork, edit, then pull!
![Screenshot_2022-02-10-09-40-26-292_com example Tiwee](https://user-images.githubusercontent.com/32876834/153373110-119ef7bd-1bda-4aae-afaf-1f435d6f386b.jpg)
![Screenshot_2022-02-10-09-40-37-499_com example Tiwee](https://user-images.githubusercontent.com/32876834/153373189-b8a72ad2-ed9d-453a-b696-8480122b8f3f.jpg)
![Screenshot_2022-02-10-09-42-13-824_com example Tiwee](https://user-images.githubusercontent.com/32876834/153373193-075057b0-f999-4b5a-bf62-76f863568f6a.jpg)
![Screenshot_2022-02-10-09-42-46-746_com example Tiwee](https://user-images.githubusercontent.com/32876834/153373204-c698775f-346e-4224-9e12-c84a6217eff6.jpg)
![Screenshot_2022-02-10-11-23-14-496_com example Tiwee](https://user-images.githubusercontent.com/32876834/153373209-8b7517c3-15e6-4950-baba-306bace20138.jpg)

## Playlist JSON Format

The app expects a JSON file with a list of channels. You can configure the URL of this JSON using the `PLAYLIST_URL` dart-define (configured in GitHub Secrets for production).

### Example Structure:

```json
[
  {
    "name": "ESPN Argentino",
    "logo": "https://upload.wikimedia.org/wikipedia/commons/b/bc/ESPN_Arg.png",
    "url": "https://example.com/live/espn_ar/index.mpd",
    "categories": [
      {
        "name": "Sports",
        "slug": "sports"
      }
    ],
    "countries": [
      {
        "name": "Argentina",
        "code": "AR"
      }
    ],
    "languages": [
      {
        "name": "Spanish",
        "code": "es"
      }
    ],
    "tvg": {
      "id": "espn.ar",
      "name": "ESPN AR",
      "url": "https://iptv-argentina.org/epg.xml"
    },
    "clearkey": {
      "f3aa10628285498ca760114c047cfa29": "10da95562095034c4f923ab94541249b"
    }
  }
]
```

*   **clearkey (optional)**: For channels with DASH DRM. Map of `Key ID` : `Key`.
*   **tvg**: Guide (EPG) data.
*   **categories/countries/languages**: Used for filtering and categorization within the app.
