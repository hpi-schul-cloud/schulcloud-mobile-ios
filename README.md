# schulcloud-mobile-ios

Dies ist das Repository der nativen iOS-App für die Schul-Cloud. Zum Entwicklen wird in der
Regel ein Apple Mac benötigt.

## Installation

- Repository lokal clonen
- [Cocoapods](https://cocoapods.org) installieren
- Die Pods des Projektes lokal installieren (`pod repo update` und `pod install`)

### Unlocking the configuration files
Wir nutzen Firebase Messaging für Push-Benachrichtigungen. Die API-Schlüssel in der Datei `GoogleService-Info.plist` sind mit `git-crypt` gesichert.
- Entsperren mit `git-crypt unlock schulcloud-mobile-ios.key`
- Falls kein Zugriff auf den Schlüssel vorhanden ist, können Standardwerte benutzt werden. Dazu einfach `GoogleService-Info.plist` durch `GoogleService-Info-dummy.plist` ersetzen.
```mv schulcloud/GoogleService-Info.plist schulcloud/GoogleService-Info.plist.bak
mv schulcloud/GoogleService-Info-dummy.plist schulcloud/GoogleService-Info.plist```

## APIs

Diese App spricht in der Dev-Version mit der API unseres Test-Systems.
Die Dokumentation liegt hier: https://schul-cloud.org:8080/docs/.
Ein Testaccount wird bei Interesse zur Verfügung gestellt.

## Testing
