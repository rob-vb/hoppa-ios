# app/bootstrap

Everything [ticket 0018 — An empty app on the phone](../../issues/0018-an-empty-app-on-the-phone.md)
needs to put a first build on a real iPhone. It is a starting kit, not part of the app: the wizard
copies its contents into the Xcode project and the app is expected to outgrow all of it.

Run it **on the Mac**, from anywhere:

```sh
bash app/bootstrap/setup-hoppa.sh
```

Eight stages. It reads the Xcode and Swift versions, tells you exactly what to type into the New
Project dialog, then edits `project.pbxproj` itself for the bundle id, the minimum iOS version and
the orientation, installs the smoke test, and records what happened in `ticket-0018-facts.env`.
Stop at any point with Ctrl-C and run it again — it keeps the answers you already gave.

| | |
| --- | --- |
| `setup-hoppa.sh` | The wizard. |
| `Sources/` | The smoke test screen: `72.5 KG` in Anton on the `#0E0F10` floor, plus a block that states whether each font really loaded. Overwrites the Xcode template's two files. |
| `Fonts/` | Anton and IBM Plex Sans (Regular + Medium), with their licences. Both are SIL OFL 1.1, which permits bundling them in an app binary as long as the licence text ships with it — that is why the `.txt` files are here and get copied too. |
