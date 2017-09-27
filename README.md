# schulcloud-mobile-ios
Dies ist das Repository der nativen iOS-App für die Schul-Cloud. Zum Entwicklen wird in der Regel ein Apple Mac benötigt.

### Development toolchain
- Xcode 9.0
- [CocoaPods](https://cocoapods.org/) 1.3.1

### Installation
- Repository lokal clonen
- Pods installieren (`pod repo update` und `pod install`)
- `schulcloud.xcworkspace` mit Xcode öffnen

### Konfigurationsdateien entschlüsseln
Wir nutzen Firebase Messaging für Push-Benachrichtigungen. Die API-Schlüssel in der Datei `GoogleService-Info.plist` sind mit `git-crypt` gesichert.
- Entsperren mit `git-crypt unlock schulcloud-mobile-ios.key`
- Falls kein Zugriff auf den Schlüssel vorhanden ist, können Standardwerte benutzt werden. Dazu einfach `GoogleService-Info.plist` durch `GoogleService-Info-dummy.plist` ersetzen.
```
mv schulcloud/GoogleService-Info.plist schulcloud/GoogleService-Info.plist.bak
mv schulcloud/GoogleService-Info-dummy.plist schulcloud/GoogleService-Info.plist
```

### UI Tests konfigurieren
Um alle UI Tests ausführen zu können, müssen die Werte `username` und `password` konfiguriert werden. Dazu wird die `Secrets.plist` kopiert
```bash
cp schulcloudUITests/Secrets.plist.dummy schulcloudUITests/Secrets.plist
```
und anschließend mit den ensprechenden Werten in dieser Datei gesetzt.

## APIs
Diese App spricht in der Dev-Version mit der API unseres Test-Systems.
Die Dokumentation liegt hier: https://schul-cloud.org:8080/docs/.
Ein Testaccount wird bei Interesse zur Verfügung gestellt.
