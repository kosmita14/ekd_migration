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
            print "Duplikat klucza '" conf_line_array[col_from] "' w pliku: '" file_name "' w linii: '" counter "'";
            #exit 1;
        }

        result_array[conf_line_array[col_from]] = conf_line_array[col_to];
        counter++;
    }

    print "Dictionary read end: " file_name ", " counter " records mapped.";
}

function convert_date(str_date){
    if (match(str_date, /^(..)\/(..)\/(..) (..):(..):(..)/, m)) {
        t = mktime("20" m[1] " " m[2] " " m[3] " " m[4] " " m[5] " " m[6]);
        return strftime("%F", t);
    }else{
        print "Date format not match for: '" str_date "'";
        return "";
    }
}
