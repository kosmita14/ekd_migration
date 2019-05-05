
function read_dict(file_name, result_array, col_from, col_to, sep){
    print "Dictionary read start: " file_name ".";
    counter = 0;

    while ((getline file_line < file_name) > 0){
        split(file_line, conf_line_array, sep);

        if(debug == 1){
            print "map: " conf_line_array[col_from] " : " conf_line_array[col_to];
            print "line: " file_line;
        }

        if(conf_line_array[col_from] in result_array){
 #           print "Duplikat klucza '" conf_line_array[col_from] "' w pliku: '" file_name "'";
 #           exit 1;
        }

        result_array[conf_line_array[col_from]] = conf_line_array[col_to];
        counter++;
    }

    print "Dictionary read end: " file_name ", " counter " records mapped.";
}

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