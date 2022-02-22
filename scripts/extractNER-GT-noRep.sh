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
			persName=$i;
			$i="";
		}
                if($i=="</persName>"){
		   if(pers==1){
			pers=0;
			print persName" "$i  >> $1".txt";
			persName="";
		   }
                   $i="";
		}
                if($i=="<placeName>") {
			if(place==0){
			  place=1;
			}
			placeName=$i;
			$i="";
		}
                if($i=="</placeName>"){
		   if(place==1){
                        place=0;
			print placeName" "$i >> $1".txt";
                        placeName="";
			$i="";	
		   }
		   $i="";
                } 
               if($i=="<date>") {
                        if(date==0){
			  date=1;
			}
			dateName=$i;
			$i="";	
                }
                if($i=="</date>"){
		   if(date==1){
                        date=0;
                        print dateName" "$i >> $1".txt";
                        dateName="";
			$i="";
		   }
	           $i="";
                } 
               if($i=="<orgName>") {
                        if(org==0){
			  org=1;
			}
			orgName=$i;
			$i="";
                }
                if($i=="</orgName>"){
		   if(org==1){
                        org=0;
                        print orgName" "$i >> $1".txt";
                        orgName="";
			$i="";
		   }
		   $i="";
                } 
		if(pers==1) persName=persName" "$i;
		if(place==1) placeName=placeName" "$i;
		if(date==1) dateName=dateName" "$i;
		if(org==1) orgName=orgName" "$i;

	}

	fflush($1".txt")
        close($1".txt")
}'

for f in *txt; do sed -r 's/ +/ /g' -i $f; done  
