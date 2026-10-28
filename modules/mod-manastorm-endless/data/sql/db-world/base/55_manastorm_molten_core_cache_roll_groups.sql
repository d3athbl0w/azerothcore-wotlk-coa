-- Follow-up to SQL 26 for caches 1278056, 1278058 and 1278060 only.
-- Reuses the installed SQL 26 item pools and preserves installed roll chances.
-- SQL 26 defaults: 10% optional families, 50% optional second Heroic MC item.
-- One explicit-chance group per family roll prevents global reference chance
-- rates changing its odds. The scoped C++ guard fixes one item per success.
-- Mythic 1-10 Dungeon gear remains intentional for 1278060's description.
-- No item templates, reference pools, conditions or progression are written.
-- Rebuild the module, apply SQL 26 first if absent, apply SQL 55, then restart.

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_roll`;
CREATE TEMPORARY TABLE `tmp_ms_mc_roll` (
    `Cache` INT UNSIGNED NOT NULL,
    `Item` INT UNSIGNED NOT NULL,
    `Reference` INT UNSIGNED NOT NULL,
    `Guaranteed` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`Cache`, `Item`)
) ENGINE=InnoDB;
DELETE FROM `tmp_ms_mc_roll`;
INSERT INTO `tmp_ms_mc_roll` (`Cache`, `Item`, `Reference`, `Guaranteed`) VALUES
(1278056, 1, 9002022, 1),
(1278056, 2, 9002001, 1),
(1278056, 3, 9002030, 0),
(1278058, 1, 9002001, 1),
(1278058, 2, 9002002, 0),
(1278058, 3, 9002030, 0),
(1278060, 1, 9002002, 1),
(1278060, 2, 9002002, 0),
(1278060, 3, 9002003, 0),
(1278060, 4, 9002010, 0),
(1278060, 5, 9002031, 0);

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_review_pool`;
CREATE TEMPORARY TABLE `tmp_ms_mc_review_pool` (
    `Entry` INT UNSIGNED NOT NULL PRIMARY KEY,
    `Expected` INT UNSIGNED NOT NULL
) ENGINE=InnoDB;
DELETE FROM `tmp_ms_mc_review_pool`;
INSERT INTO `tmp_ms_mc_review_pool` (`Entry`, `Expected`) VALUES
(9002001, 106), (9002002, 86), (9002003, 106), (9002010, 14),
(9002022, 122), (9002030, 611), (9002031, 6109);

DROP PROCEDURE IF EXISTS `ms_mc_roll_groups_20261007`;
DELIMITER $$
CREATE PROCEDURE `ms_mc_roll_groups_20261007`()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF (SELECT COUNT(*) FROM `information_schema`.`TABLES`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'item_loot_template' AND `ENGINE` = 'InnoDB') <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: InnoDB item loot required';
    END IF;
    START TRANSACTION;

    UPDATE `item_loot_template` SET `GroupId` = `Item` WHERE `Entry` IN (1278056,1278058,1278060);
    IF EXISTS (SELECT 1 FROM `item_loot_template`
        WHERE `Entry` IN (1278056,1278058,1278060) AND `GroupId` <> `Item`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: post-write group mismatch';
    END IF;
    COMMIT;
END$$
DELIMITER ;
CALL `ms_mc_roll_groups_20261007`();
DROP PROCEDURE `ms_mc_roll_groups_20261007`;

-- Expected 11 roots, GroupId equals Item; installed Chance values are preserved.
SELECT `Entry`, `Item`, `Reference`, `Chance`, `GroupId`, `MinCount`, `MaxCount`
FROM `item_loot_template` WHERE `Entry` IN (1278056,1278058,1278060) ORDER BY `Entry`, `Item`;
DROP TEMPORARY TABLE `tmp_ms_mc_review_pool`;
DROP TEMPORARY TABLE `tmp_ms_mc_roll`;
