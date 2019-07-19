@include "migration_functions.awk"

BEGIN {
    FS = ";";
    RS = "[\r]*\n";
    

    split("", globus_idmid_arr);
    
    output_file = "aliases_20190716.sql";
    output_file_csv = "aliases_20190716.csv";

    globus_idm_id_file = "./dic/id_ai2key_hades.csv";

    total_rec = 0;
    total_cust_map_error = 0;
    total_cust_dup_error = 0;
    total_alias_ok = 0;

    read_dict(globus_idm_id_file, globus_idm_id_arr, 3, 1, ",");
}

{
    if(FNR == 1){
        print "ACCOUNT;LOGIN" > output_file_csv;
        next;
    }

    total_rec++;

    source_doc_type = $8;
    globus_id = $1;
    unid = $2;

    if(globus_id in glob_arr){
        print "Duplikat klienta o globus_id: '" globus_id "' dla rekodru nr: '" FNR "' z rekordem nr '" glob_arr[globus_id] "'";
        total_cust_dup_error++;
        next;        
    }else{
        glob_arr[globus_id] = FNR;
    }


    if(globus_id in globus_idm_id_arr){
        idm_id = globus_idm_id_arr[globus_id];
    }else{
        print "Brak mapowania dla klienta o globid: '" globus_id "' dla rekodru nr: '" FNR "'";
        total_cust_map_error++;
        next;        
    }

    print "INSERT INTO ALIASES(id, account, login, is_master, is_removed, audit_cu, audit_cd, audit_mu, audit_md) values (" \
        "SEQ_ALIASES_ID.nextval, " \
        idm_id ", " \
        "'" unid "', " \
        "1, 0, 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP)" > output_file;

    print idm_id ";" \
        unid > output_file_csv;

    total_alias_ok++;
}

END {
    print "================================"
    print "Total records no: " total_rec;
    print "Total success aliases no: " total_alias_ok;
    print "Total duplicated customer err no: " total_cust_dup_error;
    print "Total customer mapping err no: " total_cust_map_error;
    print "Delta: " total_rec - total_alias_ok - total_cust_dup_error - total_cust_map_error - total_doc_map_error;
}
