DELETE FROM INGESTION_STAGES

INSERT INTO INGESTION_STAGES(code, description) VALUES(1, 'Generate new PA')
INSERT INTO INGESTION_STAGES(code, description) VALUES(2, 'Submit data for new PA')
INSERT INTO INGESTION_STAGES(code, description) VALUES(3, 'Data submission')
INSERT INTO INGESTION_STAGES(code, description) VALUES(4, 'Data submission')
INSERT INTO INGESTION_STAGES(code, description) VALUES(5, 'Passed validation')
INSERT INTO INGESTION_STAGES(code, description) VALUES(6, 'Submitted')
INSERT INTO INGESTION_STAGES(code, description) VALUES(7, 'Flagged for manual QA')
INSERT INTO INGESTION_STAGES(code, description) VALUES(8, 'Passed manual QA')
INSERT INTO INGESTION_STAGES(code, description) VALUES(9, 'New data requested')
INSERT INTO INGESTION_STAGES(code, description) VALUES(10, 'Approved')
INSERT INTO INGESTION_STAGES(code, description) VALUES(11, 'Entered into history')

