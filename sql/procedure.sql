USE fraud_detection;

DROP PROCEDURE IF EXISTS sp_process_transaction;

DELIMITER $$

CREATE PROCEDURE sp_process_transaction(
    IN p_sender_id   INT,
    IN p_receiver_id INT,
    IN p_amount      DECIMAL(10,2),
    IN p_location    VARCHAR(100)
)
BEGIN
    DECLARE v_score         INT DEFAULT 0;
    DECLARE v_status        VARCHAR(10) DEFAULT 'clean';
    DECLARE v_avg_amount    DECIMAL(10,2) DEFAULT 0;
    DECLARE v_recent_count  INT DEFAULT 0;
    DECLARE v_hour          INT;
    DECLARE v_transaction_id INT;
    DECLARE v_alert_reason  VARCHAR(255) DEFAULT '';
    DECLARE v_acc_status    VARCHAR(10);
    DECLARE v_last_location VARCHAR(100) DEFAULT '';

    -- Check if sender account is already frozen
    SELECT account_status INTO v_acc_status
    FROM users WHERE user_id = p_sender_id;

    IF v_acc_status = 'frozen' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account is frozen. Transaction blocked.';
    END IF;

    -- Insert the transaction
    INSERT INTO transactions (sender_id, receiver_id, amount, location, fraud_score, status)
    VALUES (p_sender_id, p_receiver_id, p_amount, p_location, 0, 'clean');

    SET v_transaction_id = LAST_INSERT_ID();

    -- RULE 1: Velocity check
    -- More than 3 transactions in last 10 minutes = +40 points
    SELECT COUNT(*) INTO v_recent_count
    FROM transactions
    WHERE sender_id = p_sender_id
      AND transaction_time >= NOW() - INTERVAL 10 MINUTE;

    IF v_recent_count > 3 THEN
        SET v_score = v_score + 40;
        SET v_alert_reason = CONCAT(v_alert_reason, 'High velocity (', v_recent_count, ' txns in 10 min). ');
    END IF;

    -- RULE 2: Amount anomaly
    -- Amount more than 3x sender average = +30 points
    SELECT COALESCE(AVG(amount), 0) INTO v_avg_amount
    FROM transactions
    WHERE sender_id = p_sender_id
      AND transaction_id != v_transaction_id;

    IF v_avg_amount > 0 AND p_amount > (v_avg_amount * 3) THEN
        SET v_score = v_score + 30;
        SET v_alert_reason = CONCAT(v_alert_reason, 'Amount anomaly (', p_amount, ' vs avg ', ROUND(v_avg_amount,2), '). ');
    END IF;

    -- RULE 3: Odd hour check
    -- Transactions between 1 AM and 4 AM = +30 points
    SET v_hour = HOUR(NOW());
    IF v_hour >= 1 AND v_hour <= 4 THEN
        SET v_score = v_score + 30;
        SET v_alert_reason = CONCAT(v_alert_reason, 'Odd hour (', v_hour, ':00). ');
    END IF;

    -- RULE 4: Location anomaly
    -- If location differs from the sender's last known transaction location = +25 points
    SELECT location INTO v_last_location
    FROM transactions
    WHERE sender_id = p_sender_id
      AND transaction_id != v_transaction_id
      AND location IS NOT NULL
      AND location != ''
    ORDER BY transaction_time DESC
    LIMIT 1;

    IF v_last_location != '' AND LOWER(TRIM(v_last_location)) != LOWER(TRIM(p_location)) THEN
        SET v_score = v_score + 25;
        SET v_alert_reason = CONCAT(v_alert_reason, 'Location change (', v_last_location, ' -> ', p_location, '). ');
    END IF;

    -- Determine final status using fn_get_risk_label function
    SET v_status = fn_get_risk_label(v_score);

    -- Update transaction with score and status
    UPDATE transactions
    SET fraud_score = v_score,
        status      = v_status
    WHERE transaction_id = v_transaction_id;

    -- Insert alert if flagged or frozen
    IF v_status IN ('flagged', 'frozen') THEN
        INSERT INTO alerts (transaction_id, reason)
        VALUES (v_transaction_id, v_alert_reason);
    END IF;

    -- Freeze account if score is 70+
    IF v_status = 'frozen' THEN
        UPDATE users
        SET account_status = 'frozen'
        WHERE user_id = p_sender_id;
    END IF;

    -- Return result to Flask
    SELECT
        v_transaction_id  AS transaction_id,
        v_score           AS fraud_score,
        v_status          AS status,
        v_alert_reason    AS reason;

END$$

DELIMITER ;
