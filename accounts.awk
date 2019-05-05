
function read_dict(file_name, result_array, col_from, col_to, sep){
    while ((getline file_line < file_name) > 0){
        split(file_line, conf_line_array, sep);
        result_array[conf_line_array[col_from]] = conf_line_array[col_to];
    }
}

BEGIN {
    FS = ",";
    RS = "\r\n";
    split("", doc_type_arr);
    
    output_file = "accounts.sql";
    doc_type_file = "./dic/doc_type.dic";

    read_dict(doc_type_file, doc_type_arr, 1, 3, ",");
}

{
    if(FNR == 1){
        next;
    }
    print "INSERT INTO accounts(id, AI2KEY, IS_REMOVED, STATUS, SALT, AUDIT_CU, AUDIT_CD, AUDIT_MU, AUDIT_MD, EQN, FIRST_NAME, LAST_NAME, PESEL, PHONE, ANTIPHISHING_IMAGE, CREATION_DATE, CREATED_BY, HADES_ID, DEFAULT_CARD, DEFAULT_ACCOUNT_NUMBER, ACTIVATED_BY, ACTIVATION_DATE, DOCUMENT_TYPE, DOCUMENT_NO, C5, CREATION_SYSTEM, EMAIL) values (" \
        FNR ", " \
        "'" $1 "-AI2Key', " \
        "0, 'A', NULL, 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP, NULL, " \
        "'" $3 "', " \
        "'" $4 "', " \
        "'" $5 "', " \
        "'" $6 "', " \
        "NULL, CURRENT_TIMESTAMP, 'MIGRATION_RONLINE', NULL, NULL, NULL, NULL, NULL, " \
        "'" doc_type_arr[$8] "', " \
        "'" $9 "', " \
        "NULL, 'MIGRATION_RONLINE', " \
        "'" $7 "')" > output_file;

}