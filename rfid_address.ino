// Arduino code for RFID access system with SQLite and MongoDB communication

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
  "0642BB02",  // Card 1
};
const int numAuthorizedCards = sizeof(authorizedCards) / sizeof(authorizedCards[0]);

void setup() {
  Serial.begin(115200); // Higher baud rate for faster communication
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
    cardUID += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    cardUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();

  Serial.print("UID:");
  Serial.println(cardUID);

  // Send UID to Python (for SQLite and MongoDB storage)
  Serial.print("SYNC:");
  Serial.println(cardUID);

  // Check if card is authorized
  bool accessGranted = checkAuthorization(cardUID);

  // Display result and trigger devices
  lcd.clear();
  if (accessGranted) {
    grantAccess(cardUID);
  } else {
    denyAccess(cardUID);
  }

  delay(1000);
  lcd.clear();
  lcd.print("Scan Your Card");
}

bool checkAuthorization(String cardUID) {
  for (int i = 0; i < numAuthorizedCards; i++) {
    if (cardUID.equals(authorizedCards[i])) {
      return true;
    }
  }
  return false;
}

void grantAccess(String cardUID) {
  Serial.println("Access Granted");
  lcd.setCursor(0, 0);
  lcd.print("Access Granted");
  lcd.setCursor(0, 1);
  lcd.print("Welcome!");

  digitalWrite(BUZZER_PIN, HIGH);
  delay(200);
  digitalWrite(BUZZER_PIN, LOW);

  gateServo.write(90);
  delay(3000);
  gateServo.write(0);
}

void denyAccess(String cardUID) {
  Serial.println("Access Denied");
  lcd.setCursor(0, 0);
  lcd.print("Access Denied");
  lcd.setCursor(0, 1);
  lcd.print("ALARM TRIGGERED!");

  for (int i = 0; i < 5; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(300);
    digitalWrite(BUZZER_PIN, LOW);
    delay(200);
  }
}
