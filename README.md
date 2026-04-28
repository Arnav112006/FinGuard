# FinGuard — Real-time Fraud Detection System

FinGuard is a real-time financial fraud detection system built as a DBMS lab project. It analyses every transaction the moment it is submitted and assigns a fraud confidence score based on predefined rules. Suspicious transactions are flagged automatically, and accounts involved in high-risk activity are frozen instantly — all within the database layer using MySQL stored procedures, triggers, functions, and cursors.

---

## Features

- **Real-time fraud scoring** — every transaction is scored immediately on submission
- **Rule-based detection** — velocity check, amount anomaly, odd-hour detection, and location change detection
- **Automatic account freezing** — accounts are frozen instantly if the fraud score crosses 70
- **User registration** — users can register and receive a unique User ID
- **Live dashboard** — view all transactions, alerts, and charts showing fraud statistics
- **Location tracking** — transactions include a location field; sudden location changes raise the fraud score
- **User risk summary** — a cursor-based procedure loops through all transactions for a user and builds a complete risk profile

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
├── app.py                   ← Flask backend — routes and DB calls
├── .gitignore
├── README.md
├── templates/
│   ├── index.html           ← Transaction submission form
│   ├── results.html         ← Dashboard with charts and history
│   ├── register.html        ← User registration page
│   └── risk.html            ← User risk summary page
├── static/
│   └── style.css            ← Styling for all pages
└── sql/
    ├── schema.sql           ← Creates all tables and sample data
    ├── functions.sql        ← MySQL functions
    ├── procedure.sql        ← Stored procedure with fraud scoring logic
    ├── cursor.sql           ← Cursor-based risk summary procedure
    ├── trigger.sql          ← Trigger that blocks frozen accounts
    └── migrate.sql          ← Adds location column to existing DB
```

---

## Database Objects

### Tables
| Table | Description |
|---|---|
| `users` | Registered users with name, email, and account status |
| `transactions` | All transactions with fraud score, status, and location |
| `alerts` | Alert records for every flagged or frozen transaction |

### Functions
| Function | Description |
|---|---|
| `fn_get_risk_label(score)` | Takes a fraud score and returns clean, flagged, or frozen |
| `fn_get_user_total_transactions(user_id)` | Returns the total number of transactions made by a user |

### Stored Procedures
| Procedure | Description |
|---|---|
| `sp_process_transaction` | Scores a transaction using 4 rules, calls fn_get_risk_label, updates status, creates alerts, and freezes accounts |
| `sp_user_risk_summary` | Uses a cursor to loop through all transactions for a user and returns a complete risk profile |

### Triggers
| Trigger | Description |
|---|---|
| `trg_block_frozen_account` | Fires BEFORE INSERT on transactions — blocks any transaction from a frozen account |

---

## How the Fraud Scoring Works

Every transaction runs through sp_process_transaction which checks four rules and builds a score from 0 to 100. The final status is determined by calling fn_get_risk_label:

| Rule | Condition | Points Added |
|---|---|---|
| Velocity | More than 3 transactions in the last 10 minutes | +40 |
| Amount anomaly | Amount is more than 3x the sender's average | +30 |
| Odd hour | Transaction made between 1 AM and 4 AM | +30 |
| Location change | Transaction location differs from sender's last known location | +25 |

Score below 40 → fn_get_risk_label returns Clean

Score 40-69 → fn_get_risk_label returns Flagged, an alert is created

Score 70 or above → fn_get_risk_label returns Frozen, account is blocked

---

## How the Cursor Works

sp_user_risk_summary uses a MySQL cursor to loop through every transaction made by a user one row at a time:

1. A cursor is declared on all transactions for the given user
2. The procedure loops through each row, incrementing counters for clean, flagged, and frozen transactions
3. After the loop, the average fraud score is calculated
4. fn_get_risk_label is called with the average score to determine the overall risk label
5. The full summary is returned to Flask and displayed on the Risk Summary page

---

## Setup Instructions

### Prerequisites
- Python 3 with Anaconda
- MySQL running locally
- VS Code with the MySQL extension

### Step 1 — Install dependencies
```
pip install flask mysql-connector-python
```

### Step 2 — Set up the database
Open each SQL file in VS Code, select all, and click Run in this exact order:
1. sql/schema.sql
2. sql/functions.sql
3. sql/procedure.sql
4. sql/cursor.sql
5. sql/trigger.sql

### Step 3 — Configure the database password
Open app.py and update the password field in the get_db() function.

### Step 4 — Run the app
```
/opt/anaconda3/bin/python app.py
```

Open http://127.0.0.1:5000 in your browser. Use Safari if Chrome blocks local access.

---

## Pages

| URL | Description |
|---|---|
| / | Submit a transaction |
| /register | Register a new user and get a User ID |
| /results | Dashboard — transaction history, alerts, and charts |
| /user/<id>/risk | Cursor-based risk summary for a specific user |

---

## Demo Flow

1. Go to /register and create a user — note your User ID
2. Go to / and submit a normal transaction — it shows as Clean
3. Submit the same transaction multiple times quickly — velocity rule triggers
4. Submit a very large amount — amount anomaly rule triggers
5. Submit from a different location — location change rule triggers
6. Watch the account get frozen automatically on the dashboard
7. Go to /user/1/risk to see the cursor-based risk summary for that user

---

## Author

**Arnav Singh**
DBMS Lab Project
