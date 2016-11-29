# PlusSMTP
Swift SMTP library based on cURL

## Usage

```
import Foundation
import PlusSMTP


let smtp = SMTP(
    server: "smtp.gmail.com",
    username: "youremail@gmail.com",
    password: "yourpassword",
    from: SMTP.Sender(name: "Your Name", email: "youremail@gmail.com"),
    recipients: [SMTP.Recipient(name: "Recipient Name", email: "recipientemail@me.com", type: .to)],
    subject: "Swift Email"
)

smtp.appendBody(text: "Hello world, this is Swift email.")

do {
    try smtp.send()
} catch (let error) {
    print("smtp send failed: \(error)")
}
```
