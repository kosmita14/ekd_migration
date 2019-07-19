@include "migration_functions.awk"

BEGIN {
    FS = ";";
    RS = "[\r]*\n";

    split("", doc_type_arr);
    split("", glob_ai2key_arr);
    split("", glob_arr);
    
    output_file = "accounts_20190716.sql";
    output_file_csv = "accounts_20190716.csv";
    doc_type_file = "./dic/doc_type.dic";
    #globus_ai2key_file = "./dic/globus_ai2key.ext";
    globus_ai2key_file = "./dic/T_LKP_CUS_EQNUM_26.06.csv";

    total_rec = 0;
    total_doc_map_error = 0;
    total_cust_map_error = 0;
    total_cust_dup_error = 0;
    total_cust_ok = 0;

    read_dict(doc_type_file, doc_type_arr, 1, 3, ",");
    read_dict(globus_ai2key_file, glob_ai2key_arr, 5, 2, ";");
}

{
    if(FNR == 1){
        print "AI2KEY, STATUS, FIRST_NAME, LAST_NAME, PESEL, PHONE, HADES_ID, DOCUMENT_TYPE, DOCUMENT_NO, EMAIL" > output_file_csv;
        next;
    }

    total_rec++;

    source_doc_type = $8;
    globus_id = $1;

    if(globus_id in glob_arr){
        print "Duplikat klienta o globus_id: '" globus_id "' dla rekodru nr: '" FNR "' z rekordem nr '" glob_arr[globus_id] "'";
        total_cust_dup_error++;
        next;        
    }else{
        glob_arr[globus_id] = FNR;
    }

    if(globus_id in glob_ai2key_arr){
        ai2key = glob_ai2key_arr[globus_id];
    }else{
        print "Brak mapowania dla klienta o globus_id: '" globus_id "' dla rekodru nr: '" FNR "'";
        total_cust_map_error++;
        next;        
    }

    if(source_doc_type in doc_type_arr){
        target_doc_type = doc_type_arr[source_doc_type];
    }else{
        print "Brak mapowania dla typu dokumentu: '" source_doc_type "' dla klenta o globusid: '" globus_id "' rekodru nr: '" FNR "'";
        total_doc_map_error++;
        next;        
    }

    print "INSERT INTO accounts(id, AI2KEY, IS_REMOVED, STATUS, AUDIT_CU, AUDIT_CD, AUDIT_MU, AUDIT_MD, FIRST_NAME, LAST_NAME, PESEL, PHONE, CREATION_DATE, CREATED_BY, HADES_ID, DOCUMENT_TYPE, DOCUMENT_NO, CREATION_SYSTEM, EMAIL, BRAND) values (" \
        "SEQ_ACCOUNTS_ID.nextval, " \
        "'" ai2key "', " \
        "0, 'A', 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP, " \
        "'" $3 "', " \
        "'" $4 "', " \
        "'" $5 "', " \
        "'" $6 "', " \
        "CURRENT_TIMESTAMP, 'MIGRATION_RONLINE', " \
        globus_id ", "\
        "'" target_doc_type "', " \
        "'" $9 "', " \
        "'MIGRATION_RONLINE', " \
        "'" $7 "', " \
        "'RETAIL' );" > output_file;

    print ai2key ";" \
        "A;" \
        $3 ";" \
        $4 ";" \
        $5 ";" \
        $6 ";" \
        globus_id ";"\
        target_doc_type ";" \
        $9 ";" \
        $7 > output_file_csv;


    total_cust_ok++;
}

END {
    print "================================"
    print "Total records no: " total_rec;
    print "Total success customer no: " total_cust_ok;
    print "Total duplicated customer err no: " total_cust_dup_error;
    print "Total customer mapping err no: " total_cust_map_error;
    print "Total document mapping err no: " total_doc_map_error;
    print "Delta: " total_rec - total_cust_ok - total_cust_dup_error - total_cust_map_error - total_doc_map_error;
}
