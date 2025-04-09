import serial.tools.list_ports
import sqlite3
from pymongo import MongoClient
from datetime import datetime
import threading
import time

# MongoDB setup
try:
    client = MongoClient('mongodb+srv://gondekarrutvik:hQyisHFDaAAnb41j@cluster0.b4u84.mongodb.net/?retryWrites=true&w=majority&appName=cluster0')
    db = client['gateguard']
    cardScansCollection = db['cardscans']   # Renamed because of mongoose namespace renaming
    authorizedCardsCollection = db['authorizedcards']
    authorized_cards_doc = authorizedCardsCollection.find({}, {'_id': 0, 'card_uid': 1})
except Exception as e:
    print(f"MongoDB connection error: {e}")
    exit()

# Sample authorized card UIDs (replace this with real DB logic)
authorized_cards = [card['card_uid'] for card in authorized_cards_doc]

# SQLite setup
sqlite_lock = threading.Lock()
conn = sqlite3.connect('card_data.db', check_same_thread=False)
cursor = conn.cursor()
cursor.execute('''
    CREATE TABLE IF NOT EXISTS scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_uid TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
''')
conn.commit()


# Serial setup
try:
    ports = serial.tools.list_ports.comports()
    for port in ports:
        print(f"Found port: {port.device}")
    ser = serial.Serial('COM5', 115200, timeout=1)  # Ensure baud rate matches Arduino code
except serial.SerialException as e:
    print(f"Serial port error: {e}")
    exit()
except AttributeError:
    print("Ensure 'pyserial' is installed using: pip install pyserial")
    exit()

print("Listening for RFID scans...")

# Check if a card UID is authorized
def is_access_granted(card_uid):
    try:
        authorized_cards_doc = authorizedCardsCollection.find({}, {'_id': 0, 'card_uid': 1})
        authorized_cards = [card['card_uid'] for card in authorized_cards_doc]
    except Exception as e:
        print(f"MongoDB error: {e}")
        return False
    return card_uid in authorized_cards

# Store data in SQLite with access status
def store_to_sqlite(card_uid):
    try:
        access_granted = is_access_granted(card_uid)
        with sqlite_lock:
            cursor.execute('INSERT INTO scans (card_uid, accessgranted) VALUES (?, ?)', (card_uid, access_granted))
            conn.commit()
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")

# Sync data to MongoDB with access status
def sync_to_mongo(card_uid):
    try:
        access_granted = is_access_granted(card_uid)
        data = {
            "card_uid": card_uid,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "accessgranted": access_granted
        }
        cardScansCollection.insert_one(data)
    except Exception as e:
        print(f"MongoDB error: {e}")

# Read and process serial data
def process_serial_data():
    try:
        while True:
            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8').strip()
                if line.startswith("SYNC:"):
                    card_uid = line.split(":")[1]
                    print(f"Card UID: {card_uid}")
                    threading.Thread(target=store_to_sqlite, args=(card_uid,)).start()
                    threading.Thread(target=sync_to_mongo, args=(card_uid,)).start()
    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except KeyboardInterrupt:
        print("Exiting...")
    finally:
        conn.close()
        client.close()
        ser.close()

# View stored SQLite data
def view_sqlite_data():
    try:
        cursor.execute('PRAGMA table_info(scans)')
        columns = cursor.fetchall()
        column_count = len(columns)

        cursor.execute('SELECT * FROM scans')
        rows = cursor.fetchall()
        print("\nStored Data in SQLite:")
        print("ID | Card UID | Timestamp | Access Granted")
        print("-" * 40)
        for row in rows:
            if column_count == 4:  # Ensure all columns exist
                print(f"{row[0]} | {row[1]} | {row[2]} | {row[3]}")
            else:  # Fallback if accessgranted column is missing
                print(f"{row[0]} | {row[1]} | {row[2]} | N/A")
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")

# Run the serial processing loop
threading.Thread(target=process_serial_data).start()

# Display SQLite data every 10 seconds
while True:
    view_sqlite_data()
    time.sleep(10)
