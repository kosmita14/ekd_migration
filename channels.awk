@include "migration_functions.awk"

BEGIN {
    FS = ",";
    RS = "[\r]*\n";
    
    split("", glob_ai2key_arr);
    split("", account_ai2key_arr);
    split("", channel_status_arr);
    split("", channel_name_arr);

    output_file = "channels.sql";
    globus_ai2key_file = "./dic/globus_ai2key.ext";
    account_ai2key_file = "./dic/account_ai2key.ext";
    channel_status_file = "./dic/channel_status.dic";
    channel_name_file = "./dic/channel_name.dic";

    read_dict(globus_ai2key_file, glob_ai2key_arr, 2, 1, ",");
    read_dict(account_ai2key_file, account_ai2key_arr, 2, 1, ",");
    read_dict(channel_status_file, channel_status_arr, 1, 2, ",");
    read_dict(channel_name_file, channel_name_arr, 1, 2, ",");

}

{
    if(FNR == 1){
        next;
    }

    globus_id = $1;
    unid = $2;
    source_channel_status = $4;
    source_channel_name = $3;
    source_date = $5;

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

    print "INSERT INTO ACCOUNT_CHANNELS (id, account, status, access_status, IS_REMOVED, audit_cu, audit_cd, audit_mu, audit_md, bad_pass_count, AUTHENTICATION, AUTHORIZATION, successful_login, FAILED_LOGIN, LAST_LOGOUT, ACTIVATION_DATE, REACTIVATION_DATE, BLOCK_REASON, BLOCK_DATE, RESET_BY, RESET_DATE, CHANNEL) values (" \
        21000000 + FNR ", " \
        "'" account_id "', " \
        "'M', " \
        "'" target_channel_status "', " \
        "0, 0, CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP, 0, NULL, 'OTP', NULL, NULL, NULL, NULL, NULL, 'block reason'," \
        "TO_DATE('" convert_date(source_date) "', 'YYYY-MM-DD'), " \
        "NULL, NULL, " \
        "'" target_channel_name "')" > output_file;

}