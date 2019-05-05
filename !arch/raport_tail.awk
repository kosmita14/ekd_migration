BEGIN {
	FS = "\t";
	report_section = 0;
}

/^-+$/{
	report_section = 1;
}

{
	if(report_section){
		print $0;
	}
}

