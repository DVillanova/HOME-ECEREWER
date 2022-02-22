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
		   if(pers==1){
			pers=0;
			print persName" "$i  >> $1".txt";
			persName="";
		   }
		   else{
                      $i="";
		   }
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
		   if(place==1){
                        place=0;
			print placeName" "$i >> $1".txt";
                        placeName="";
		   }
		   else{
			$i="";
		   }
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
		   if(date==1){
                        date=0;
                        print dateName" "$i >> $1".txt";
                        dateName="";
		   }
		   else{
			$i="";
		   }	 
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
		   if(org==1){
                        org=0;
                        print orgName" "$i >> $1".txt";
                        orgName="";
		   }
		   else{
			$i="";
		   }
                } 
		if(pers==1) persName=persName" "$i;
		if(place==1) placeName=placeName" "$i;
		if(date==1) dateName=dateName" "$i;
		if(org==1) orgName=orgName" "$i;

	}

        if(pers==1) print persName" </persName>" >> $1".txt";
        if(place==1) print placeName" </placeName>" >> $1".txt";
	if(date==1) print dateName" </date>" >> $1".txt";
	if(org==1) print orgName" </orgName>" >> $1".txt";

	fflush($1".txt")
        close($1".txt")
}' 
