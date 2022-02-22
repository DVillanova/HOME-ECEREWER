sed 's/</ </g' $1 | sed 's/>/> /g' | awk '{
        pers=0;
	place=0;
	date=0;
	org=0;
        persName="";
	placeName="";
	dateName="";
	orgName="";
	for (i=2;i<=NF;i++){
		if($i=="<persName>"){
			if(pers==0){ 
			  pers=1;
			}
			else{
			  print persName" </persName>" >> $1".txt";
			  persName="";
			} 
		}
                if($i=="</persName>"){
			pers=0;
			print persName" "$i  >> $1".txt";
			persName="";
		}
                if($i=="<placeName>") {
			if(place==0){
			  place=1;
			}
			else{
			  print placeName" </placeName>" >> $1".txt";
			  placeName=""; 
			}
		}
                if($i=="</placeName>"){
                        place=0;
			print placeName" "$i >> $1".txt";
                        placeName="";
                } 
               if($i=="<date>") {
                        if(date==0){
			  date=1;
			}	
                        else{
                          print dateName" </date>" >> $1".txt";
                          dateName=""; 
                        }
                }
                if($i=="</date>"){
                        date=0;
                        print dateName" "$i >> $1".txt";
                        dateName="";
                } 
               if($i=="<orgName>") {
                        if(org==0){
			  org=1;
			}
                        else{
                          print orgName" </orgName>" >> $1".txt";
                          orgName=""; 
                        }
                }
                if($i=="</orgName>"){
                        org=0;
                        print orgName" "$i >> $1".txt";
                        orgName="";
                } 
		if(pers==1) persName=persName" "$i;
		if(place==1) placeName=placeName" "$i;
		if(date==1) dateName=dateName" "$i;
		if(org==1) orgName=orgName" "$i;

	}
	fflush($1".txt")
        close($1".txt")
}' 
