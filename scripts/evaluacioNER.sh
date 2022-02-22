Ref=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $1/${n}.txt 2> error; done | wc -l)  
Hyp=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $2/${n}.txt 2> error; done | wc -l)

echo $Ref $Hyp

Aciertos=$(for f in $(<$3); do
        n=`basename ${f/.png/.txt}`;

	if ! [ -f $1/$n ] ; then continue; fi
        if ! [ -f $2/$n ] ; then continue; fi

	awk -v n=$1/$n 'BEGIN{ 
		while(getline < n){ 
		   ner[$0]=1;
		}
	}
	{
		if(ner[$0]==1) print $0; 	
	}' $2/$n	

done | wc -l)
echo $Aciertos

echo $Ref $Hyp $Aciertos | awk '{precision=$3/$2; recall=$3/$1; print "precision "precision,"recall "recall;}'


Ref_place=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $1/${n}.txt 2> error; done | grep "^<placeName>" | wc -l)
Hyp_place=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $2/${n}.txt 2> error; done | grep "^<placeName>" | wc -l)

Aciertos_place=$(for f in $(<$3); do
        n=`basename ${f/.png/.txt}`;


        if ! [ -f $1/$n ] ; then continue; fi
        if ! [ -f $2/$n ] ; then continue; fi


        awk -v n=$1/$n 'BEGIN{ 
                while(getline < n){ 
                   ner[$0]=1;
                }
        }
        {
                if(ner[$0]==1) print $0;        
        }' $2/$n   

done |grep "^<placeName>" |  wc -l)

echo $Ref_place $Hyp_place $Aciertos_place | awk '{precision=$3/$2; recall=$3/$1; print "place: precision "precision,"recall "recall;}'


Ref_pers=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $1/${n}.txt 2> error; done | grep "^<persName>" | wc -l)
Hyp_pers=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $2/${n}.txt 2> error; done | grep "^<persName>" | wc -l)

Aciertos_pers=$(for f in $(<$3); do
        n=`basename ${f/.png/.txt}`;


        if ! [ -f $1/$n ] ; then continue; fi
        if ! [ -f $2/$n ] ; then continue; fi

        awk -v n=$1/$n 'BEGIN{ 
                while(getline < n){ 
                   ner[$0]=1;
                }
        }
        {
                if(ner[$0]==1) print $0;        
        }' $2/$n   

done |grep "^<persName>" |  wc -l)

echo $Ref_pers $Hyp_pers $Aciertos_pers | awk '{precision=$3/$2; recall=$3/$1; print "pers: precision "precision,"recall "recall;}'



Ref_date=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $1/${n}.txt 2> error; done | grep "^<date>" | wc -l)
Hyp_date=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $2/${n}.txt 2> error; done | grep "^<date>" | wc -l)

Aciertos_date=$(for f in $(<$3); do
        n=`basename ${f/.png/.txt}`;


        if ! [ -f $1/$n ] ; then continue; fi
        if ! [ -f $2/$n ] ; then continue; fi


        awk -v n=$1/$n 'BEGIN{ 
                while(getline < n){ 
                   ner[$0]=1;
                }
        }
        {
                if(ner[$0]==1) print $0;        
        }' $2/$n   

done |grep "^<date>" |  wc -l)

echo $Ref_date $Hyp_date $Aciertos_date | awk '{precision=$3/$2; recall=$3/$1; print "date: precision "precision,"recall "recall;}'

Ref_org=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $1/${n}.txt 2> error; done | grep "^<orgName>" | wc -l)
Hyp_org=$(for f in $(<$3); do n=`basename ${f/.png/}`; cat $2/${n}.txt 2> error; done | grep "^<orgName>" | wc -l)

Aciertos_org=$(for f in $(<$3); do
        n=`basename ${f/.png/.txt}`;


        if ! [ -f $1/$n ] ; then continue; fi
        if ! [ -f $2/$n ] ; then continue; fi


        awk -v n=$1/$n 'BEGIN{ 
                while(getline < n){ 
                   ner[$0]=1;
                }
        }
        {
                if(ner[$0]==1) print $0;        
        }' $2/$n   

done |grep "^<orgName>" |  wc -l)

echo $Ref_org $Hyp_org $Aciertos_org | awk '{precision=$3/$2; recall=$3/$1; print "org: precision "precision,"recall "recall;}'

