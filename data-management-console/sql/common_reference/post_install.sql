/* Install ISO3 data */
DELETE FROM stg_iso3

DROP SEQUENCE IF EXISTS iso3_seq
CREATE SEQUENCE iso3_seq AS INT START WITH 1

CREATE OR REPLACE FUNCTION stg_iso3_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('iso3_seq'); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_stg_iso3_id ON stg_iso3
CREATE TRIGGER trig_stg_iso3_id BEFORE INSERT ON stg_iso3 FOR EACH ROW EXECUTE procedure stg_iso3_id();

INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ESP', 'Spain', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('FRA', 'France', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MCO', 'Monaco', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CHE', 'Switzerland', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('AND', 'Andorra', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ITA', 'Italy', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ZAF', 'South Africa', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CYM', 'CYM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GUM', 'GUM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('POL', 'POL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('HKG', 'HKG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NLD', 'NLD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NFK', 'NFK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LTU', 'LTU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ALA', 'ALA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('URY', 'URY', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ERI', 'ERI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CAF', 'CAF', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ECU', 'ECU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('OMN', 'OMN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NZL', 'NZL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('AUS', 'AUS', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('JEY', 'JEY', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CXR', 'CXR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NIU', 'NIU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KOR', 'KOR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MHL', 'MHL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KEN', 'KEN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('DMA', 'DMA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('DZA', 'DZA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LBR', 'LBR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MDG', 'MDG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MRT', 'MRT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('VIR', 'VIR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MOZ', 'MOZ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TUV', 'TUV', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('COM', 'COM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('AUT', 'AUT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('UMI', 'UMI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ARM', 'ARM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MNP', 'MNP', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GLP', 'GLP', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MLI', 'MLI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SGS', 'SGS', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LBN', 'LBN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('HND', 'HND', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CCK', 'CCK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BRN', 'BRN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ASM', 'ASM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('IND', 'IND', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ATG', 'ATG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LAO', 'LAO', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BEL', 'BEL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ZWE', 'ZWE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SGP', 'SGP', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BGD', 'BGD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('HUN', 'HUN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GHA', 'GHA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KHM', 'KHM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BLZ', 'BLZ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TCA', 'TCA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('VNM', 'VNM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CIV', 'CIV', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('EGY', 'EGY', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GIN', 'GIN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BFA', 'BFA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('THA', 'THA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ROU', 'ROU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SWE', 'SWE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MNG', 'MNG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SPM', 'SPM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MNE', 'MNE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KGZ', 'KGZ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('VCT', 'VCT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CUB', 'CUB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('VGB', 'VGB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ETH', 'ETH', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MDV', 'MDV', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SLE', 'SLE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ABW', 'ABW', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NCL', 'NCL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NOR', 'NOR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MKD', 'MKD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('FLK', 'FLK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('IDN', 'IDN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ALB', 'ALB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MAR', 'MAR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('COG', 'COG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BRA', 'BRA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ZMB', 'ZMB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SWZ', 'SWZ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('JAM', 'JAM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BOL', 'BOL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BRB', 'BRB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('DNK', 'DNK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('QAT', 'QAT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('RWA', 'RWA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('AGO', 'AGO', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('COK', 'COK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('HMD', 'HMD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PYF', 'PYF', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GAB', 'GAB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KNA', 'KNA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TCD', 'TCD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BTN', 'BTN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LSO', 'LSO', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NER', 'NER', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MAF', 'MAF', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GNB', 'GNB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('IRN', 'IRN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TGO', 'TGO', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PLW', 'PLW', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LUX', 'LUX', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('FJI', 'FJI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('YEM', 'YEM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TZA', 'TZA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CHL', 'CHL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GUF', 'GUF', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('FRO', 'FRO', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BHS', 'BHS', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GTM', 'GTM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('AFG', 'AFG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GRC', 'GRC', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GMB', 'GMB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TLS', 'TLS', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BGR', 'BGR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BIH', 'BIH', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BHR', 'BHR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KWT', 'KWT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BWA', 'BWA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SYC', 'SYC', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PRT', 'PRT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('FIN', 'FIN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MYS', 'MYS', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ATA', 'ATA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GUY', 'GUY', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('IRL', 'IRL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TUN', 'TUN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('COD', 'COD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TKM', 'TKM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('AZE', 'AZE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LCA', 'LCA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PNG', 'PNG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BEN', 'BEN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SJM', 'SJM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PHL', 'PHL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TWN', 'TWN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MTQ', 'MTQ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('EST', 'EST', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BDI', 'BDI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CHN', 'CHN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MMR', 'MMR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SRB', 'SRB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CYP', 'CYP', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('VUT', 'VUT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KIR', 'KIR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CMR', 'CMR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('COL', 'COL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('DEU', 'DEU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GRL', 'GRL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('UZB', 'UZB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BLR', 'BLR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ABNJ', 'ABNJ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BMU', 'BMU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GRD', 'GRD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PSE', 'PSE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LVA', 'LVA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('DOM', 'DOM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SDN', 'SDN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MDA', 'MDA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('FSM', 'FSM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('HTI', 'HTI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PAN', 'PAN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PCN', 'PCN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NGA', 'NGA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TTO', 'TTO', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('USA', 'USA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('IOT', 'IOT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CZE', 'CZE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CPV', 'CPV', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GEO', 'GEO', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SVK', 'SVK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MEX', 'MEX', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GBR', 'GBR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GGY', 'GGY', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('JOR', 'JOR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('HRV', 'HRV', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('REU', 'REU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SSD', 'SSD', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BES', 'BES', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NAM', 'NAM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SVN', 'SVN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NPL', 'NPL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TJK', 'TJK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('UGA', 'UGA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CAN', 'CAN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SUR', 'SUR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TUR', 'TUR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('JPN', 'JPN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SLV', 'SLV', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ISR', 'ISR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('VEN', 'VEN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SXM', 'SXM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ATF', 'ATF', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('RUS', 'RUS', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SHN', 'SHN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SEN', 'SEN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PRI', 'PRI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ISL', 'ISL', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('IMN', 'IMN', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MSR', 'MSR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('UKR', 'UKR', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('IRQ', 'IRQ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('GNQ', 'GNQ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PER', 'PER', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LKA', 'LKA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ARE', 'ARE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PRY', 'PRY', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BVT', 'BVT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('BLM', 'BLM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('AIA', 'AIA', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SAU', 'SAU', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('PAK', 'PAK', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ARG', 'ARG', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CRI', 'CRI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MUS', 'MUS', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('NIC', 'NIC', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('STP', 'STP', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('DJI', 'DJI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MYT', 'MYT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SLB', 'SLB', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MWI', 'MWI', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('WSM', 'WSM', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('LIE', 'LIE', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('KAZ', 'KAZ', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('MLT', 'MLT', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('CUW', 'CUW', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('TON', 'TON', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('ESH', 'ESH', 10000 );
INSERT INTO stg_iso3(code, description, originator_id) VALUES ('SYR', 'SYR', 10000 );

/* Install no_take_cat data */
INSERT INTO stg_no_take_cat(code, description, originator_id) VALUES('Part', 'Part of the ICCA', 10000 );
INSERT INTO stg_no_take_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000 );
INSERT INTO stg_no_take_cat(code, description, originator_id) VALUES('Not Applicable','Not Applicable', 10000 );
INSERT INTO stg_no_take_cat(code, description, originator_id) VALUES('All', 'All of the ICCA', 10000 );

/* Install ownership_type_cat data */
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Communal', 'Communal: (or collective) owned by one or more communities/indigenous peoples', 10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('State', 'Owned by the state/government', 10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Individual landowners', 'Individual landowners',10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('For-profit organisation(s)', 'For-profit organisation(s)',10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Non-profit organisation(s)', 'Non-profit organisation(s)',10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Joint ownership', 'Owned collectively by two or more of the above entities', 10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Multiple ownership', 'Different parts of the land/sea are owned by different entities', 10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Contested', 'More than one entity claims ownership of the ICCA', 10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Other', '', 10000);
INSERT INTO stg_ownership_type_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);

/* Install marine_cat data */
INSERT INTO stg_marine_cat(code, description, originator_id) VALUES('0', 'Terrestrial', 10000);
INSERT INTO stg_marine_cat(code, description, originator_id) VALUES('1', 'Coastal', 10000);
INSERT INTO stg_marine_cat(code, description, originator_id) VALUES('2', 'Marine', 10000);

/* Install international_criteria_cat data */
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('i', 'Description 1', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('ii', 'Description 2', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('iii', 'Description 3', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('iv', 'Description 4', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('v', 'Description 5', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('vi', 'Description 6', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('vii', 'Description 7', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('viii', 'Description 8', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('ix', 'Description 9', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('x', 'Description 10', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000)
INSERT INTO stg_international_criteria_cat(code, description, originator_id) VALUES('Not Applicable', 'Not Applicable', 10000)

/* Install iucn_category_cat data */
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('Ia', 'Strictly protected area. Human use and impacts are strictly controlled', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('Ib', 'Unmodified or slightly-modified area. Managed to control its natural condition without permanent or significant human habitation', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('II', 'Natural or near-natural area, protected to conserve ecosystems, but also allowing cultural, spiritual, scientific, educational, recreational and visitor use', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('III', 'Protection of a specific natural monument.', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('IV', 'Protection of a specific species or habitat', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('V', 'Protection of the integrity of a human-nature interaction that has given the area a distinct character.', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('VI', 'Protected area supporting ecosystems alongside cultural values and sustainable resource management.', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('Not Applicable', 'Not Applicable', 10000 );
INSERT INTO stg_iucn_category_cat(code, description, originator_id) VALUES('Not Assigned', 'Intentionally not Assigned', 10000 );
