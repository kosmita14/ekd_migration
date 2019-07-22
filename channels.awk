@include "migration_functions.awk"
BEGIN {
    FS = ";";
    RS = "[\r]*\n";
    
    split("", glob_default_arr);
    split("", globus_arr);
    split("", globus_idm_id_arr);
    split("", channel_status_arr);
    split("", channel_name_arr);

    output_file = "./out/!arch/channels_20190721.sql";
    output_file_csv = "./out/channels_20190721.csv";

    total_rec = 0;
    total_doc_map_error = 0;
    total_cust_map_error = 0;
    total_dup_error = 0;
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

    glob_chann_key = globus_id "," source_channel_name;
    text_output_csv = generate_CSV(idm_id, target_channel_status, 0, source_date, target_channel_name);

    if(glob_chann_key in glob_default_arr){
        print "Duplikat kanału z kluczem: '" glob_chann_key "' w wierszu: '" FNR "' z rekordem w wierszu nr '" glob_default_arr[glob_chann_key] "'";
        total_dup_error++;
        next;        
    }else{
        glob_default_arr[glob_chann_key] = text_output_csv;
    }

    #todo kolejne numery linii po przecinku
    globus_arr[globus_id] = FNR;

    print generate_SQL(idm_id, target_channel_status, source_date, target_channel_name) > output_file;
    print text_output_csv > output_file_csv;

    total_channel_ok++;
}

function generate_CSV(idm_id, target_channel_status, audit_cu, source_date, target_channel_name){
    return idm_id ";" \
        "M;" \
        target_channel_status ";" \
        "0;" \
        audit_cu ";" \
        "0;0;OTP;block reason;" \
        convert_date(source_date) ";" \
        target_channel_name;
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
    total_default_vipm_waring = 0;
    total_default_nib_waring = 0;

    for(globus_id in globus_arr){
        nib_chann_key = globus_id ",NIB";
        vipm_chann_key = globus_id ",VIPM";
        if(nib_chann_key in glob_default_arr){
            if(vipm_chann_key in glob_default_arr){
                #jest ok
            }else{
                org_record = glob_default_arr[nib_chann_key];
                split(org_record, org_record_arr, ";");
                new_record = generate_CSV(org_record_arr[1], org_record_arr[3], 999, org_record_arr[10], channel_name_arr["VIPM"]);
                print "Warn: Dodano domyślny status kanału mobilnego dla klenta o globusid: '" globus_id "' dane skopiowane z rekordu '" org_record "', dodany rekodrd '" new_record "'";
                print new_record > output_file_csv;
                total_default_vipm_waring++;
            }
        } else {
            org_record = glob_default_arr[vipm_chann_key];
            split(org_record, org_record_arr, ";");
            new_record = generate_CSV(org_record_arr[1], org_record_arr[3], 999, org_record_arr[10], channel_name_arr["NIB"]);
            print "Warn: Dodano domyślny status kanału online dla klenta o globusid: '" globus_id "' dane skopiowane z rekordu '" org_record "', dodany rekodrd '" new_record "'";
            print new_record > output_file_csv;
            total_default_nib_waring++;
        }
    }



    print "================================"
    print "Total records no: " total_rec;
    print "Total success channel no: " total_channel_ok + total_default_vipm_waring + total_default_nib_waring;
    print "     Total success transf channel no: " total_channel_ok;
    print "     Total success default channel no: " total_default_vipm_waring + total_default_nib_waring;
    print "Total duplicated channel status err no: " total_dup_error;
    print "Total customer mapping err no: " total_cust_map_error;
 #   print "Total document mapping err no: " total_doc_map_error;
    print "Delta: " total_rec - total_channel_ok - total_dup_error - total_cust_map_error;
    print "================================"
    print "Total default mobile warn no: " total_default_vipm_waring;
    print "Total default nib warn no: " total_default_nib_waring;
    print "================================"
}