USE fraud_detection;

-- Add location column to transactions table if it doesn't exist
ALTER TABLE transactions
ADD COLUMN location VARCHAR(100) DEFAULT NULL;
