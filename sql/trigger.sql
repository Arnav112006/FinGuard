DROP TRIGGER IF EXISTS trg_block_frozen_account;

DELIMITER $$

CREATE TRIGGER trg_block_frozen_account
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(10);

    SELECT account_status INTO v_status
    FROM users
    WHERE user_id = NEW.sender_id;

    IF v_status = 'frozen' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction blocked: sender account is frozen.';
    END IF;
END$$

DELIMITER ;
