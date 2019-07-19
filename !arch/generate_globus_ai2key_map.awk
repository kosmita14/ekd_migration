
BEGIN {
    FS = ",";
    RS = "\r\n";

    output_file = "./dic/globus_ai2key.ext";
}

{
    if(FNR == 1){
        print "AI2Key,GLOB_ID,UNID_ID" > output_file;
        next;
    }

    print 10000000000000000 + $1 "," \
        $1 "," \
        $2 > output_file;
}