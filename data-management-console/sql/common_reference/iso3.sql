DELETE FROM STAGING_ISO3;

INSERT INTO STAGING_ISO3(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES('ESP', 'Spain', 10000);
INSERT INTO STAGING_ISO3(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES('FRA', 'France', 10000);
INSERT INTO STAGING_ISO3(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES('MCO', 'Monaco', 10000);
INSERT INTO STAGING_ISO3(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES('CHE', 'Switzerland', 10000);
INSERT INTO STAGING_ISO3(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES('AND', 'Andorra', 10000);
INSERT INTO STAGING_ISO3(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES('ITA', 'Italy', 10000);
INSERT INTO STAGING_ISO3(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES('ZAF', 'South Africa', 10000);

INSERT INTO STAGING_ISO3(CODE, Description, Originator_id) SELECT DISTINCT ISO3, ISO3, 10000 FROM wdpadata_poly_may2023 a WHERE LENGTH(a.ISO3) < 5 AND a.ISO3 NOT IN (SELECT CODE FROM ISO3 UNION SELECT CODE FROM STAGING_ISO3);
INSERT INTO STAGING_ISO3(CODE, Description, Originator_id) SELECT DISTINCT ISO3, ISO3, 10000 FROM wdpadata_poly_may2021 a WHERE LENGTH(a.ISO3) < 5 AND a.ISO3 NOT IN (SELECT CODE FROM ISO3 UNION SELECT CODE FROM STAGING_ISO3);

