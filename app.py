from flask import Flask, render_template, request, jsonify
import mysql.connector

app = Flask(__name__)

def get_db():
    return mysql.connector.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        password="2006",        # add your password here if needed
        database="fraud_detection"
    )

# ── Users API (for dynamic frontend loading) ──────────────────
@app.route("/api/users")
def api_users():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT user_id, name, account_status FROM users ORDER BY user_id")
    users = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(users)

# ── Full users API (for register page table) ───────────────────
@app.route("/api/users/full")
def api_users_full():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT user_id, name, email, account_status, created_at FROM users ORDER BY user_id")
    users = cursor.fetchall()
    cursor.close()
    db.close()
    # Convert datetime to string for JSON
    for u in users:
        if u['created_at']:
            u['created_at'] = str(u['created_at'])
    return jsonify(users)

# ── Register page ──────────────────────────────────────────────
@app.route("/register")
def register():
    return render_template("register.html", result=None, error=None)

@app.route("/register", methods=["POST"])
def register_post():
    name  = request.form["name"].strip()
    email = request.form["email"].strip()
    result = None
    error  = None

    if not name or not email:
        error = "Name and email are required."
    else:
        try:
            db = get_db()
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT user_id FROM users WHERE email = %s", (email,))
            existing = cursor.fetchone()
            if existing:
                error = f"Email already registered. Your User ID is {existing['user_id']}."
            else:
                cursor.execute(
                    "INSERT INTO users (name, email) VALUES (%s, %s)", (name, email)
                )
                db.commit()
                new_id = cursor.lastrowid
                result = {"user_id": new_id, "name": name, "email": email}
            cursor.close()
            db.close()
        except mysql.connector.Error as e:
            error = str(e.msg)

    return render_template("register.html", result=result, error=error)

# ── Home page ──────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html", result=None)

# ── Submit transaction ─────────────────────────────────────────
@app.route("/submit", methods=["POST"])
def submit():
    sender_id   = request.form["sender_id"]
    receiver_id = request.form["receiver_id"]
    amount      = request.form["amount"]
    location    = request.form["location"]
    result      = None
    error       = None

    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.callproc("sp_process_transaction",
                        [sender_id, receiver_id, float(amount), location])
        for res in cursor.stored_results():
            result = res.fetchone()
        db.commit()
        cursor.close()
        db.close()
    except mysql.connector.Error as e:
        error = str(e.msg)

    return render_template("index.html", result=result, error=error)

# ── Results + charts page ──────────────────────────────────────
@app.route("/results")
def results():
    db = get_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            t.transaction_id,
            t.sender_id,
            t.receiver_id,
            s.name  AS sender,
            r.name  AS receiver,
            t.amount,
            t.location,
            t.fraud_score,
            t.status,
            t.transaction_time
        FROM transactions t
        LEFT JOIN users s ON t.sender_id   = s.user_id
        LEFT JOIN users r ON t.receiver_id = r.user_id
        ORDER BY t.transaction_time DESC
    """)
    transactions = cursor.fetchall()

    cursor.execute("""
        SELECT a.alert_id, a.transaction_id, a.reason, a.created_at
        FROM alerts a ORDER BY a.created_at DESC
    """)
    alerts = cursor.fetchall()

    # Stats for charts
    cursor.execute("""
        SELECT status, COUNT(*) as count
        FROM transactions GROUP BY status
    """)
    status_rows = cursor.fetchall()
    status_counts = {'clean': 0, 'flagged': 0, 'frozen': 0}
    for row in status_rows:
        status_counts[row['status']] = row['count']

    # Transactions per day (last 7 days)
    cursor.execute("""
        SELECT DATE(transaction_time) as day, COUNT(*) as count
        FROM transactions
        WHERE transaction_time >= NOW() - INTERVAL 7 DAY
        GROUP BY DATE(transaction_time)
        ORDER BY day ASC
    """)
    daily_rows = cursor.fetchall()
    daily_labels = [str(r['day']) for r in daily_rows]
    daily_counts = [r['count'] for r in daily_rows]

    # Top locations by transaction count
    cursor.execute("""
        SELECT location, COUNT(*) as count
        FROM transactions
        WHERE location IS NOT NULL AND location != ''
        GROUP BY location ORDER BY count DESC LIMIT 6
    """)
    loc_rows = cursor.fetchall()
    loc_labels = [r['location'] for r in loc_rows]
    loc_counts  = [r['count']    for r in loc_rows]

    cursor.close()
    db.close()

    return render_template("results.html",
                           transactions=transactions,
                           alerts=alerts,
                           status_counts=status_counts,
                           daily_labels=daily_labels,
                           daily_counts=daily_counts,
                           loc_labels=loc_labels,
                           loc_counts=loc_counts)

if __name__ == "__main__":
    app.run(debug=True)
