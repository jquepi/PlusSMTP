# PlusSMTP
Swift SMTP library based on cURL library. Suitable for server side Swift development.

## Dependency
Add to Package.swift
```
.Package(url: "https://github.com/matejukmar/PlusSMTP.git", majorVersion: 1, minor: 0)
```

## Usage

```swift
import Foundation
import PlusSMTP


let smtp = SMTP(
    address: "smtp.gmail.com",
    username: "youremail@gmail.com",
    password: "yourpassword"
)

let body = SMTP.MailBody()

body.append(text: "Hello world from swift Mail")

do {
    try smtp.send(
        subject: "Hello world Swift",
        body: body,
        from: SMTP.Sender(name: "Sender Name", email: "sender@gmail.com"),
        recipients: [SMTP.Recipient(name: "Recipient Name", email: "recipient@me.com", type: .to)]
    )
} catch (let error) {
    print("smtp send failed: \(error)")
}
```
