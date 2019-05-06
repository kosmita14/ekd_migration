@include "migration_functions.awk"

BEGIN {
    FS = ",";
    RS = "[\r]*\n";
    split("", doc_type_arr);
    split("", glob_ai2key_arr);
    
    output_file = "accounts.sql";
    doc_type_file = "./dic/doc_type.dic";
    globus_ai2key_file = "./dic/globus_ai2key.ext";

    read_dict(doc_type_file, doc_type_arr, 1, 3, ",");
    read_dict(globus_ai2key_file, glob_ai2key_arr, 2, 1, ",");
}

{
    if(FNR == 1){
        next;
    }

    source_doc_type = $8;
    globus_id = $1;

    if(source_doc_type in doc_type_arr){
        target_doc_type = doc_type_arr[source_doc_type];
    }else{
        print "Brak mapowania dla typu dokumentu: '" source_doc_type "' dla rekodru nr: '" FNR "'";
        next;        
    }

    if(globus_id in glob_ai2key_arr){
        ai2key = glob_ai2key_arr[globus_id];
    }else{
        print "Brak mapowania dla klienta o globus_id: '" globus_id "' dla rekodru nr: '" FNR "'";
        next;        
    }

    print "INSERT INTO accounts(id, AI2KEY, IS_REMOVED, STATUS, SALT, AUDIT_CU, AUDIT_CD, AUDIT_MU, AUDIT_MD, EQN, FIRST_NAME, LAST_NAME, PESEL, PHONE, ANTIPHISHING_IMAGE, CREATION_DATE, CREATED_BY, HADES_ID, DEFAULT_CARD, DEFAULT_ACCOUNT_NUMBER, ACTIVATED_BY, ACTIVATION_DATE, DOCUMENT_TYPE, DOCUMENT_NO, C5, CREATION_SYSTEM, EMAIL) values (" \
        3000000 + FNR ", " \
        "'" ai2key "', " \
        "0, 'A', NULL, 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP, NULL, " \
        "'" $3 "', " \
        "'" $4 "', " \
        "'" $5 "', " \
        "'" $6 "', " \
        "NULL, CURRENT_TIMESTAMP, 'MIGRATION_RONLINE', " \
        "'" globus_id "', "\
        "NULL, NULL, NULL, NULL, " \
        "'" target_doc_type "', " \
        "'" $9 "', " \
        "NULL, 'MIGRATION_RONLINE', " \
        "'" $7 "')" > output_file;
}