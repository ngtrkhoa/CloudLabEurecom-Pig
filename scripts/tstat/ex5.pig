SET default_parallel 5;
set job.name 'TCP_5_GROUP02';

%declare INPUT_PATH '/home/ntkhoa/IdeaProjects/CloudLabEurecom-Pig/local-input/NETWORK_TRAFFIC/100linee.txt';
%declare OUTPUT_PATH '/home/ntkhoa/IdeaProjects/CloudLabEurecom-Pig/local-output/STAT/TCP-5/';

-- Load raw data generated by tcpdump
RAW_DATA = LOAD '$INPUT_PATH'
        AS (ts:long, sport, dport, sip, dip,
                l3proto, l4proto, flags,
                phypkt, netpkt, overhead,
                phybyte, netbyte:long);


-- Prepare the data such that input time stamp can be used accordingly to the queries
DATA = FOREACH RAW_DATA GENERATE sip, netbyte as upload;

DATA_UP = GROUP DATA BY sip;
FLOW_UP = FOREACH DATA_UP GENERATE group as ip, SUM(DATA.upload) as sum_upload;
FLOW_UP_SORTED = ORDER FLOW_UP BY sum_upload DESC;
FLOW_UP_TOP100 = LIMIT FLOW_UP_SORTED 100;

FLOW_JOIN = JOIN FLOW_UP_TOP100 BY ip, DATA BY sip;
FLOW_JOIN_GROUP = GROUP FLOW_JOIN BY ip;
RESULT = FOREACH FLOW_JOIN_GROUP GENERATE group, MAX(FLOW_JOIN.upload), (double)100 * MAX(FLOW_JOIN.upload) / MAX(FLOW_JOIN.sum_upload);

-- Store the output
STORE RESULT INTO '$OUTPUT_PATH';
