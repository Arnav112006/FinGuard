USE fraud_detection;

-- ──────────────────────────────────────────────────────────────
-- PROCEDURE: sp_user_risk_summary
-- Uses a CURSOR to loop through all transactions for a given user
-- and builds a risk summary: total transactions, flagged count,
-- frozen count, and an overall risk label
-- ──────────────────────────────────────────────────────────────

DROP PROCEDURE IF EXISTS sp_user_risk_summary;

DELIMITER $$

CREATE PROCEDURE sp_user_risk_summary(IN p_user_id INT)
BEGIN
    -- Variables to hold each row fetched by the cursor
    DECLARE v_txn_id      INT;
    DECLARE v_score       INT;
    DECLARE v_status      VARCHAR(10);
    DECLARE v_done        INT DEFAULT 0;

    -- Summary counters
    DECLARE v_total       INT DEFAULT 0;
    DECLARE v_clean_count INT DEFAULT 0;
    DECLARE v_flag_count  INT DEFAULT 0;
    DECLARE v_freeze_count INT DEFAULT 0;
    DECLARE v_total_score INT DEFAULT 0;
    DECLARE v_avg_score   DECIMAL(5,2) DEFAULT 0;
    DECLARE v_risk_label  VARCHAR(10) DEFAULT 'clean';

    -- Declare the cursor — fetches all transactions for this user
    DECLARE txn_cursor CURSOR FOR
        SELECT transaction_id, fraud_score, status
        FROM transactions
        WHERE sender_id = p_user_id
        ORDER BY transaction_time DESC;

    -- Handler to stop the loop when no more rows
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- Open the cursor
    OPEN txn_cursor;

    -- Loop through each transaction row
    txn_loop: LOOP
        FETCH txn_cursor INTO v_txn_id, v_score, v_status;

        -- Exit loop if no more rows
        IF v_done = 1 THEN
            LEAVE txn_loop;
        END IF;

        -- Increment counters based on status
        SET v_total       = v_total + 1;
        SET v_total_score = v_total_score + v_score;

        IF v_status = 'clean' THEN
            SET v_clean_count = v_clean_count + 1;
        ELSEIF v_status = 'flagged' THEN
            SET v_flag_count = v_flag_count + 1;
        ELSEIF v_status = 'frozen' THEN
            SET v_freeze_count = v_freeze_count + 1;
        END IF;

    END LOOP;

    -- Close the cursor
    CLOSE txn_cursor;

    -- Calculate average fraud score
    IF v_total > 0 THEN
        SET v_avg_score = v_total_score / v_total;
    END IF;

    -- Use the function to get overall risk label from average score
    SET v_risk_label = fn_get_risk_label(ROUND(v_avg_score));

    -- Return the summary
    SELECT
        p_user_id           AS user_id,
        v_total             AS total_transactions,
        v_clean_count       AS clean_count,
        v_flag_count        AS flagged_count,
        v_freeze_count      AS frozen_count,
        ROUND(v_avg_score, 2) AS avg_fraud_score,
        v_risk_label        AS overall_risk;

END$$

DELIMITER ;
