CREATE DATABASE T162_190729 FROM DBC AS PERM = 1000000000  NO BEFORE JOURNAL NO AFTER JOURNAL;  
CREATE DATABASE T162_190729_REPO FROM T162_190729 AS PERM = 200000000  NO BEFORE JOURNAL NO AFTER JOURNAL;  
CREATE database T162_190729_FACT FROM T162_190729 AS PERM = 50000000 NO BEFORE JOURNAL NO AFTER JOURNAL ;  
CREATE database T162_190729_STAGE FROM T162_190729 AS PERM = 50000000 NO BEFORE JOURNAL NO AFTER JOURNAL ;  
CREATE database T162_190729_LOAD FROM T162_190729 AS PERM = 50000000 NO BEFORE JOURNAL NO AFTER JOURNAL ;  
.LOGOFF  
.QUIT 
