BEGIN {
    FS = ",";
    RS = "\r\n";

    output_file = "./dic/account_ai2key.ext";
}

{
    if(FNR == 1){
        print "Account,AI2Key" > output_file;
        next;
    }

    print 3000000 + FNR "," 10000000000000000 + $1 > output_file;

}