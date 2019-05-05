#
#       Copyright (C) Raiffeisen Bank Polska S.A., 2003, all rights reserved.
#
#       CVS Header Block - Do not modify
#       $Workfile: compare.awk $
#       $Revision: 1.2 $
#       $Date: 2014/09/26 10:40:00 $
#
# ==============================================================================
#
# @author  Michał Wcisło
# @create  T24UPGRADE_298
#
# @desc    AWK files comparator
# @desc    gawk -f compare.awk -v file_r13=ACCOUNT_R13.txt conf_file=ACCOUNT_R13.txt.config log_file=compare_result.txt ACCOUNT_R06.txt
#
# @param   file_r13=ACCOUNT_R13.txt          [input 1]
# @param   conf_file=ACCOUNT_R13.txt.config  [config]
# @param   log_file=compare_result.txt       [log]
# @param   ACCOUNT_R06.txt                   [input 2]
#
# @errors  see log-file
#
# @change       2014.10.01 Initial Release
# @changeDesc   Initial Release


BEGIN {
    FS = "\t";

    r13_line_counter = 0;
    field_diff_counter = 0;
    match_key_counter = 0;
    record_diff_counter = 0;

    split("", field_diff_arr);

    split("", header_r06_arr);
    split("", header_r13_arr);
    
    split("", compfunct_arr);
    

    split("", ext_r06_arr);
    split("", ext_r13_arr);

    split("", config_arr);
    
    debug_level = 0;
}

function read_config(file_name, result_array){
    while ((getline file_line < file_name) > 0){
        split(file_line, conf_line_array, "=");
        result_array[conf_line_array[1]] = conf_line_array[2];
    }
}

function getkey(from_array, ext_line_arr){
    return_value = "";
    if(from_array){
        for(col_no in key_col){
            if(return_value == ""){
                return_value = ext_line_arr[key_col[col_no]];
            }else{
                return_value = return_value "|" ext_line_arr[key_col[col_no]];
            }
        }
    }else{
        for(col_no in key_col){
            if(return_value == ""){
                return_value = $key_col[col_no];
            }else{
                return_value = return_value "|" $key_col[col_no];
            }
        }
    }

    return return_value;
}

function read_file(file_name, out_array){
    while ((getline file_line < file_name) > 0){
        r13_line_counter++;

        split(file_line, file_line_arr);

        file_key_value = getkey(1, file_line_arr);
        print "Dodaję klucz do mapy: '" FS file_key_value "'" > log_file;
        if(file_key_value in out_array){
            print "Duplikat klucza dla R13: '" FS file_key_value"'" > log_file;
        }

        out_array["" file_key_value] = file_line;
    }
}

function find_in_file(key_value, file_name, out_array, max_line){
    i=0;

    while ((i++ < max_line) && ((getline file_line < file_name) > 0)){
        r13_line_counter++;

        split(file_line, file_line_arr);

        file_key_value = getkey(1, file_line_arr);
        if(key_value == file_key_value){
            return file_line;
        }else{
            print "Dodaję klucz do mapy: '" FS file_key_value "'" > log_file;
            out_array["" file_key_value] = file_line;
        }
    }

    return "";
}

function compare_lines(r06_line, r13_line){
    match_key_counter++;

    split(r06_line, r06_line_arr);
    split(r13_line, r13_line_arr);

    local_diff_counter = 0;
    for(i=1; i <= compare_len; i++){
        if(r06_line_arr[r06_col[i]] != r13_line_arr[r13_col[i]]){
            print FS "Niezgodność wartości dla klucza:" getkey(1, r06_line_arr) FS header_r06_arr[r06_col[i]] ".'" r06_line_arr[r06_col[i]]"' <> " header_r13_arr[r13_col[i]] ".'" r13_line_arr[r13_col[i]] "'" > log_file;
            field_diff_arr[header_r06_arr[r06_col[i]]] = field_diff_arr[header_r06_arr[r06_col[i]]] + 1;
            local_diff_counter++; #licznik ilości rozjazdów
        }else{
            #print FS "Zgodność wartości:" FS "'" r06_line_arr[r06_col[i]]"'" FS "'" r13_line_arr[r13_col[i]] "'" > log_file;
        }
    }

    field_diff_counter += local_diff_counter;
    if(local_diff_counter) {
        record_diff_counter++;
    }

    return local_diff_counter;
}

function parse_col_no_string(col_no_string, max_row_field_no, compfunct_array, header_array, output_array){
    output_array_index = 0;
    split("", ignore_array);
    
    array_size = split(col_no_string, col_no_array, "|");

    for(i=1; i <= array_size; i++){
        if(col_no_array[i] ~ /^[0-9]*-[0-9]*$/){ #zawiera zakres numerów pól
            match(col_no_array[i], /^([0-9]*)-([0-9]*)$/, arr);
            if(arr[1] == ""){
                arr[1] = 1;
            }

            if(arr[2] == ""){
                arr[2] = max_row_field_no;
            }

            for(j = 0 + arr[1]; j <= 0 + arr[2]; j++){
                switch (compfunct_array[i]){
                    case "jeden_do_jednego":
                        output_array[++output_array_index] = j; break;
                    case "ignore":
                        ignore_array[j] = j;
                        break;
                    default:
                        print "Nieznana funkcja porównująca: '" compfunct_array[i] "' na pozycji: " i; exit -1;
                }
            }
        }else{ #obsługa pojedynczych kolumn
            #konwersja nazwy na numer kolumny
            if(col_no_array[i] !~ /^[0-9]+$/){
                for(k=1; k <= max_row_field_no; k++){
                    if(header_array[k] == col_no_array[i]){
                        col_no_array[i] = k;
                    }
                }
            }
                        
            switch (compfunct_array[i]){
                case "jeden_do_jednego":
                    output_array[++output_array_index] = col_no_array[i]; break;
                case "ignore":
                    ignore_array[col_no_array[i]] = col_no_array[i]; break;
                default:
                    print "Nieznana funkcja porównująca: '" compfunct_array[i] "' na pozycji: " i; exit -1;
            }
        }
    }
  
 
    #usunięcie ignorowanych kolumn
    temp_index = 0;
    for(i=1; i <= output_array_index; i++){
        if(output_array[i] in ignore_array){
            delete output_array[i];
        }else{
            output_array[++temp_index] = output_array[i];
        }
    }

    return temp_index;
}

{
    if(FNR == 1){
        read_config(conf_file, config_arr);
        if(config_arr["HEADER"] == "YES"){
            is_header = 1;
        }
     
        if(is_header){
            split($0, header_r06_arr);
            if((getline header_line < file_r13) > 0){
                split(header_line, header_r13_arr);
            }
        }else{
            for(i=1; i<=NF; i++){
                header_r06_arr[i] = header_r13_arr[i] = "COL" i;
            }            
        }
        
        split(config_arr["COMPARISONKEY"], key_col, "|");
        split(config_arr["COMPFUNCT"], compfunct_arr, "|");
                
        compare_len = parse_col_no_string(config_arr["R06COLNO"], NF, compfunct_arr, header_r06_arr, r06_col);
        parse_col_no_string(config_arr["R13COLNO"], NF, compfunct_arr, header_r13_arr, r13_col);
        
        if(debug_level == 1){
            for(i=1; i <= compare_len; i++){
                print i FS r06_col[i] FS r13_col[i];
            }
            exit 1;
        }
        next;
    }

    if((FNR % 25000) == 0){
        print strftime("%T") " : " FILENAME " progress: " FNR;
        fflush();
    }

    key_r06 = getkey(0);
    if(key_r06 in ext_r06_arr){
        print "Duplikat klucza dla R06: '" FS key_r06"'" > log_file;
    }

    if(key_r06 in ext_r13_arr){
        print "Znaleziono pasujący klucz w mapie:'" FS  key_r06 "'"  > log_file;
        compare_lines($0, ext_r13_arr[key_r06]);
        delete ext_r13_arr[key_r06];
    }else{
        find_result = find_in_file(key_r06, file_r13, ext_r13_arr, 10);
        if(find_result != ""){
            #print "Znaleziono pasujący klucz w pliku:'" FS  key_r06 "'" > log_file;
            compare_lines($0, find_result);
        }else{
            print "Nie znaleziono pasującego klucza w pliku:'" FS  key_r06 "'" > log_file;
            ext_r06_arr["" key_r06] = $0;
        }
    }
}

END{
    if(debug_level == 0){
        print strftime("%T") " : " FILENAME " doczytywanie pozostałych liniii z drugiego ekstraktu - START.";
        read_file(file_r13, ext_r13_arr);
        print strftime("%T") " : " FILENAME " doczytywanie pozostałych liniii z drugiego ekstraktu - STOP";
    }
    
    print strftime("%T") " : " FILENAME " porównanie pozostałych w mapach rekordów - START.";
    for(key_value in ext_r06_arr){
        if(key_value in ext_r13_arr){
            compare_lines(ext_r06_arr[key_value], ext_r13_arr[key_value]);
            delete ext_r06_arr[key_value];
            delete ext_r13_arr[key_value];
        }
    }
    print strftime("%T") " : " FILENAME " porównanie pozostałych w mapach rekordów - STOP.";
    
    print "---------" > log_file;
    if(is_header){
        r06_line_counter = FNR-1;
    }else{
        r06_line_counter = FNR;
    }

    print "Wczytano rekordów z R06: " r06_line_counter  > log_file;
    print "Wczytano rekordów z R13: " r13_line_counter > log_file;
    print "Dopasowano po kluczu: " match_key_counter > log_file;
    print "Niedopasowano po kluczu w R06: " length(ext_r06_arr) > log_file;
    print "Niedopasowano po kluczu w R13: " length(ext_r13_arr) > log_file;
    print "Różnice w rekordach: " record_diff_counter > log_file;
    print "Różnice w polach: " field_diff_counter > log_file;
    for(key_value in field_diff_arr){
        print FS "W polu: '" key_value "': " field_diff_arr[key_value] > log_file;
    }
    print "" > log_file;

    print "Pozostało w R06:" > log_file;
    for(key_value in ext_r06_arr){
        print FS key_value > log_file;
    }


    print "Pozostało w R13:"  > log_file;
    for(key_value in ext_r13_arr){
        print FS key_value > log_file;
    }
}
