BEGIN {
	FS = "\t";
	report_section = 0;

	while ((getline file_line < report_file) > 0){
		split(file_line, conf_line_array);
		if((file_line ~ /Pozostało w R06:/) || (file_line ~ /Pozostało w R13:/)){
			report_section = 1;
		}else{
			if(report_section == 1){
				result_array[conf_line_array[2]] = file_line;
			}
		}
	}
}


{
	if($1 in result_array){
		print $0;
	}
}

END{
#	i = 0;
#	
#	for(arr_value in result_array){
#		print ++i FS arr_value;
#	}
}

