@include "migration_functions.awk"

BEGIN {
    FS = ",";
    RS = "[\r]*\n";
    

    split("", globus_idmid_arr);
    
    output_file = "aliases_20190709.sql";

    globus_idm_id_file = "./dic/idm_globus_mapping.csv";


    read_dict(globus_idm_id_file, globus_idm_id_arr, 3, 1, ",");
}

{
    if(FNR == 1){
        next;
    }

    source_doc_type = $8;
    globus_id = $1;
    unid = $2;

    if(globus_id in globus_idm_id_arr){
        idm_id = globus_idm_id_arr[globus_id];
    }else{
        print "Brak mapowania dla rachunku o globid: '" globus_id "' dla rekodru nr: '" FNR "'";
        next;        
    }

    print "INSERT INTO ALIASES(id, account, login, is_master, is_removed, audit_cu, audit_cd, audit_mu, audit_md) values (" \
        "SEQ_ALIASES_ID.nextval, " \
        idm_id ", " \
        "'" unid "', " \
        "1, 0, 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP)" > output_file;

}
