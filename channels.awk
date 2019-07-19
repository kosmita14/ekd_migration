@include "migration_functions.awk"
BEGIN {
    FS = ";";
    RS = "[\r]*\n";
    
    split("", globus_idmid_arr);
    split("", account_ai2key_arr);
    split("", channel_status_arr);
    split("", channel_name_arr);

    output_file = "channels_20190716.sql";
    output_file_csv = "channels_20190716.csv";

    total_rec = 0;
    total_doc_map_error = 0;
    total_cust_map_error = 0;
    total_cust_dup_error = 0;
    total_channel_ok = 0;

    globus_idm_id_file = "./dic/id_ai2key_hades.csv";
    channel_status_file = "./dic/channel_status.dic";
    channel_name_file = "./dic/channel_name.dic";
    
    read_dict(globus_idm_id_file, globus_idm_id_arr, 3, 1, ",");
    read_dict(channel_status_file, channel_status_arr, 1, 2, ",");
    read_dict(channel_name_file, channel_name_arr, 1, 2, ",");
}

{
    if(FNR == 1){
        print "account;status;access_status;IS_REMOVED;audit_cu;audit_mu;bad_pass_count;AUTHORIZATION;BLOCK_REASON;BLOCK_DATE;CHANNEL" > output_file_csv;
        next;
    }

    total_rec++;

    globus_id = $1;
    unid = $2;
    source_channel_status = $4;
    source_channel_name = $3;
    source_date = $5;
    
    if(globus_id in globus_idm_id_arr){
        idm_id = globus_idm_id_arr[globus_id];
    }else{
        print "Brak mapowania dla klienta o globus_id: '" globus_id "' dla rekodru nr: '" FNR "'";
        total_cust_map_error++;
        next;        
    }

    # if(ai2key in account_ai2key_arr){
    #     account_id = account_ai2key_arr[ai2key];
    # }else{
    #     print "Brak mapowania dla rachunku o ai2key: '" ai2key "' dla rekodru nr: '" FNR "'";
    #     next;        
    # }

    if(source_channel_status in channel_status_arr){
        target_channel_status = channel_status_arr[source_channel_status];
    }else{
        print "Brak mapowania dla statusu kanału: '" source_channel_status "' dla rekodru nr: '" FNR "'";
        next;        
    }

    if(source_channel_name in channel_name_arr){
        target_channel_name = channel_name_arr[source_channel_name];
    }else{
        print "Brak mapowania dla kanału o nazwie: '" source_channel_name "' dla rekodru nr: '" FNR "'";
        next;        
    }

    print generate_SQL(idm_id, target_channel_status, source_date, target_channel_name) > output_file;
    print idm_id ";" \
        "M;" \
        target_channel_status ";" \
        "0;0;0;0;OTP;block reason;" \
        convert_date(source_date) ";" \
        target_channel_name > output_file_csv;

    total_channel_ok++;
}

function generate_SQL(idm_id, target_channel_status, source_date, target_channel_name){
    return "INSERT INTO ACCOUNT_CHANNELS (id, account, status, access_status, IS_REMOVED, audit_cu, audit_cd, audit_mu, audit_md, bad_pass_count, AUTHORIZATION, BLOCK_REASON, BLOCK_DATE, CHANNEL) values (" \
       "SEQ_ACCOUNT_CHANNELS_ID.nextval, " \
        idm_id ", " \
        "'M', " \
        "'" target_channel_status "', " \
        "0, 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP, 0, 'OTP', 'block reason'," \
        "TO_DATE('" convert_date(source_date) "', 'YYYY-MM-DD'), " \
        "'" target_channel_name "');" 
}

END {
    print "================================"
    print "Total records no: " total_rec;
    print "Total success channel no: " total_channel_ok;
 #   print "Total duplicated customer err no: " total_cust_dup_error;
    print "Total customer mapping err no: " total_cust_map_error;
 #   print "Total document mapping err no: " total_doc_map_error;
    print "Delta: " total_rec - total_channel_ok - total_cust_map_error;
}