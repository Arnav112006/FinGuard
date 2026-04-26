# FinGuard — Real-time Fraud Detection System

FinGuard is a real-time financial fraud detection system built as a DBMS lab project. It analyses every transaction the moment it is submitted and assigns a fraud confidence score based on predefined rules. Suspicious transactions are flagged automatically, and accounts involved in high-risk activity are frozen instantly — all within the database layer using MySQL stored procedures and triggers.

---

## Features

- **Real-time fraud scoring** — every transaction is scored immediately on submission
- **Rule-based detection** — velocity check, amount anomaly, odd-hour detection, and location change detection
- **Automatic account freezing** — accounts are frozen instantly if the fraud score crosses 70
- **User registration** — users can register and receive a unique User ID
- **Live dashboard** — view all transactions, alerts, and charts showing fraud statistics
- **Location tracking** — transactions include a location field; sudden location changes raise the fraud score

---

## Tech Stack

| Layer | Technology |
|---|---|
| Database | MySQL 8 |
| Backend | Python 3 + Flask |
| Frontend | HTML, CSS |
| DB Driver | mysql-connector-python |

---

## Project Structure

```
Fraud Detection System/
├── app.py                  ← Flask backend — routes and DB calls
├── .gitignore
├── templates/
│   ├── index.html          ← Transaction submission form
│   ├── results.html        ← Dashboard with charts and history
│   └── register.html       ← User registration page
├── static/
│   └── style.css           ← Styling for all pages
└── sql/
    ├── schema.sql          ← Creates all tables and sample data
    ├── procedure.sql       ← Stored procedure with fraud scoring logic
    ├── trigger.sql         ← Trigger that blocks frozen accounts
    └── migrate.sql         ← Adds location column to existing DB
```

---

## How the Fraud Scoring Works

Every transaction runs through a stored procedure (`sp_process_transaction`) that checks four rules and builds a score from 0 to 100:

| Rule | Condition | Points Added |
|---|---|---|
| Velocity | More than 3 transactions in the last 10 minutes | +40 |
| Amount anomaly | Amount is more than 3× the sender's 30-day average | +30 |
| Odd hour | Transaction made between 1 AM and 4 AM | +30 |
| Location change | Transaction location differs from sender's last known location | +25 |

**Score below 40** → Transaction is marked **Clean**

**Score 40–69** → Transaction is **Flagged**, an alert is created

**Score 70 or above** → Transaction is **Frozen**, sender's account is blocked

---

## Database Schema

**users** — stores registered users with their account status (active / frozen)

**transactions** — stores every transaction with its fraud score, status, and location

**alerts** — stores alert records for every flagged or frozen transaction

---

## Setup Instructions

### Prerequisites
- Python 3 with Anaconda
- MySQL running locally
- VS Code with the MySQL extension

### Step 1 — Install dependencies
```bash
pip install flask mysql-connector-python
```

### Step 2 — Set up the database
Open each SQL file in VS Code, select all, and click Run — in this exact order:
1. `sql/schema.sql`
2. `sql/procedure.sql`
3. `sql/trigger.sql`

### Step 3 — Configure the database password
Open `app.py` and update the password field in the `get_db()` function:
```python
def get_db():
    return mysql.connector.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        password="your_password_here",
        database="fraud_detection"
    )
```

### Step 4 — Run the app
```bash
cd "Fraud Detection System"
/opt/anaconda3/bin/python app.py
```

Open `http://127.0.0.1:5000` in your browser.

---

## Pages

| URL | Description |
|---|---|
| `/` | Submit a transaction |
| `/register` | Register a new user and get a User ID |
| `/results` | Dashboard — transaction history, alerts, and charts |

---

## Demo Flow

1. Go to `/register` and create a user — note your User ID
2. Go to `/` and submit a normal transaction — it will show as Clean
3. Submit the same transaction multiple times quickly — velocity rule triggers
4. Submit a very large amount — amount anomaly rule triggers
5. Submit from a different location — location change rule triggers
6. Watch the account get frozen automatically on the dashboard

---

## Author

**Arnav Singh**
DBMS Lab Project
