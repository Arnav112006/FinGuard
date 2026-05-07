USE fraud_detection;



DROP PROCEDURE IF EXISTS sp_user_risk_summary;

DELIMITER $$

CREATE PROCEDURE sp_user_risk_summary(IN p_user_id INT)
BEGIN

    DECLARE v_txn_id      INT;
    DECLARE v_score       INT;
    DECLARE v_status      VARCHAR(10);
    DECLARE v_done        INT DEFAULT 0;


    DECLARE v_total       INT DEFAULT 0;
    DECLARE v_clean_count INT DEFAULT 0;
    DECLARE v_flag_count  INT DEFAULT 0;
    DECLARE v_freeze_count INT DEFAULT 0;
    DECLARE v_total_score INT DEFAULT 0;
    DECLARE v_avg_score   DECIMAL(5,2) DEFAULT 0;
    DECLARE v_risk_label  VARCHAR(10) DEFAULT 'clean';


    DECLARE txn_cursor CURSOR FOR
        SELECT transaction_id, fraud_score, status
        FROM transactions
        WHERE sender_id = p_user_id
        ORDER BY transaction_time DESC;


    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;


    OPEN txn_cursor;


    txn_loop: LOOP
        FETCH txn_cursor INTO v_txn_id, v_score, v_status;


        IF v_done = 1 THEN
            LEAVE txn_loop;
        END IF;

    
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

   
    CLOSE txn_cursor;

   
    IF v_total > 0 THEN
        SET v_avg_score = v_total_score / v_total;
    END IF;

   
    SET v_risk_label = fn_get_risk_label(ROUND(v_avg_score));

   
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
