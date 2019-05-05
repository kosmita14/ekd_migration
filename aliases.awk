@include "migration_functions.awk"

BEGIN {
    FS = ",";
    RS = "[\r]*\n";
    
    split("", glob_ai2key_arr);
    split("", account_ai2key_arr);
    
    output_file = "aliases.sql";
    globus_ai2key_file = "./dic/globus_ai2key.ext";
    account_ai2key_file = "./dic/account_ai2key.ext";

    read_dict(globus_ai2key_file, glob_ai2key_arr, 2, 1, ",");
    read_dict(account_ai2key_file, account_ai2key_arr, 2, 1, ",");
}

{
    if(FNR == 1){
        next;
    }

    source_doc_type = $8;
    globus_id = $1;
    unid = $2;

    if(globus_id in glob_ai2key_arr){
        ai2key = glob_ai2key_arr[globus_id];
    }else{
        print "Brak mapowania dla klienta o globus_id: '" globus_id "' dla rekodru nr: '" FNR "'";
        next;        
    }

    if(ai2key in account_ai2key_arr){
        account_id = account_ai2key_arr[ai2key];
    }else{
        print "Brak mapowania dla rachunku o ai2key: '" ai2key "' dla rekodru nr: '" FNR "'";
        next;        
    }

    print "INSERT INTO ALIASES(id, account, login, is_master, is_removed, audit_cu, audit_cd, audit_mu, audit_md) values (" \
        8000000 + FNR ", " \
        "'" account_id "', " \
        "'" unid "', " \
        "1, 0, 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP)" > output_file;

}