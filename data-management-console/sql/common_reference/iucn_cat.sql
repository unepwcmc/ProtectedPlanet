DELETE FROM STAGING_IUCN_CAT;

INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(1, 'Ia', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(2, 'II', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(3, 'III', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(4, 'IV', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(5, 'V', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(6, 'VI', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(7, 'Not Reported', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(8, 'Not Applicable', 10000);
INSERT INTO STAGING_IUCN_CAT(CODE, DESCRIPTION, ORIGINATOR_ID) VALUES(9, 'Not Assigned', 10000);

INSERT INTO staging_iucn_cat(CODE, DEscription, Originator_id) SELECT MIN(OBJECTID) + 10, IUCN_CAT, 10000 FROM wdpadata_poly_may2023 a WHERE a.iucn_cat NOT IN (SELECT DESCRIPTION FROM IUCN_CAT UNION SELECT DESCRIPTION FROM STAGING_IUCN_CAT) GROUP BY IUCN_CAT;
INSERT INTO staging_iucn_cat(CODE, DEscription, Originator_id) SELECT MIN(OBJECTID) + 1000, IUCN_CAT, 10000 FROM wdpadata_poly_may2021 a WHERE a.iucn_cat NOT IN (SELECT DESCRIPTION FROM IUCN_CAT UNION SELECT DESCRIPTION FROM STAGING_IUCN_CAT) GROUP BY IUCN_CAT;