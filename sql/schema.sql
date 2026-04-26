USE fraud_detection;

CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    account_status ENUM('active', 'frozen') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    location VARCHAR(100) DEFAULT NULL,
    transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fraud_score INT DEFAULT 0,
    status ENUM('clean', 'flagged', 'frozen') DEFAULT 'clean',
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (receiver_id) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS alerts (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

INSERT INTO users (name, email) VALUES
('Arnav Singh',  'arnav@example.com'),
('Rahul Mehta',  'rahul@example.com'),
('Priya Sharma', 'priya@example.com'),
('Vikram Nair',  'vikram@example.com'),
('Sneha Gupta',  'sneha@example.com');
