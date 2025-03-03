// Include libraries
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SPI.h>
#include <MFRC522.h>
#include <Servo.h>

// Pin definitions
#define SS_PIN 10
#define RST_PIN 9
#define BUZZER_PIN 8
#define SERVO_PIN 7

// Initialize RFID, LCD, and Servo
MFRC522 mfrc522(SS_PIN, RST_PIN);
LiquidCrystal_I2C lcd(0x27, 16, 2); // Adjust I2C address if needed
Servo gateServo;

// Authorized card UIDs (no spaces, all uppercase)
const char* authorizedCards[] = {
  "0642BB02"   // autorized tag
};
const int numAuthorizedCards = sizeof(authorizedCards) / sizeof(authorizedCards[0]);

void setup() {
  Serial.begin(9600);
  SPI.begin();
  mfrc522.PCD_Init();
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Scan Your Card");

  // Initialize Buzzer and Servo
  pinMode(BUZZER_PIN, OUTPUT);
  gateServo.attach(SERVO_PIN);
  gateServo.write(0); // Gate starts closed

  Serial.println("System ready. Waiting for card...");
}

void loop() {
  // Wait for new RFID card
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  // Get card UID as a string
  String cardUID = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) {
      cardUID += "0";
    }
    cardUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();
  
  Serial.print("Card UID: ");
  Serial.println(cardUID);

  // Check if card is authorized
  bool accessGranted = false;
  for (int i = 0; i < numAuthorizedCards; i++) {
    if (cardUID.equals(authorizedCards[i])) {
      accessGranted = true;
      break;
    }
  }

  // Display result and trigger devices
  lcd.clear();
  if (accessGranted) {
    Serial.println("Access Granted");
    lcd.setCursor(0, 0);
    lcd.print("Access Granted");
    lcd.setCursor(0, 1);
    lcd.print("Welcome!");

    // Short beep for authorized access
    digitalWrite(BUZZER_PIN, HIGH);
    delay(200);
    digitalWrite(BUZZER_PIN, LOW);

    // Open gate
    gateServo.write(90);  // Open gate
    delay(3000);          // Gate open for 3 sec
    gateServo.write(0);   // Close gate

  } else {
    Serial.println("Access Denied");
    lcd.setCursor(0, 0);
    lcd.print("Access Denied");
    lcd.setCursor(0, 1);
    lcd.print("ALARM TRIGGERED!");

    // Long alarm for unauthorized access
    for (int i = 0; i < 5; i++) {
      digitalWrite(BUZZER_PIN, HIGH);
      delay(500);
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
    }
  }

  // Reset LCD to initial message
  delay(2000);
  lcd.clear();
  lcd.print("Scan Your Card");
  delay(1000);
}