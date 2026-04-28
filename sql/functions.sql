USE fraud_detection;

-- ──────────────────────────────────────────────────────────────
-- FUNCTION 1: fn_get_risk_label
-- Takes a fraud score (0-100) and returns a human-readable label
-- Used by the stored procedure and can be called directly
-- ──────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS fn_get_risk_label;

DELIMITER $$

CREATE FUNCTION fn_get_risk_label(p_score INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE v_label VARCHAR(10);

    IF p_score >= 70 THEN
        SET v_label = 'frozen';
    ELSEIF p_score >= 40 THEN
        SET v_label = 'flagged';
    ELSE
        SET v_label = 'clean';
    END IF;

    RETURN v_label;
END$$

DELIMITER ;


-- ──────────────────────────────────────────────────────────────
-- FUNCTION 2: fn_get_user_total_transactions
-- Returns the total number of transactions made by a user
-- ──────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS fn_get_user_total_transactions;

DELIMITER $$

CREATE FUNCTION fn_get_user_total_transactions(p_user_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT DEFAULT 0;

    SELECT COUNT(*) INTO v_count
    FROM transactions
    WHERE sender_id = p_user_id;

    RETURN v_count;
END$$

DELIMITER ;
