import '../models/song.dart';

// Comprehensive Telugu Worship Songs Database
// Songs from "4th Jan 26_Sunday Songs.pdf" and Telugu Worship Collections

List<Song> getSampleSongs() {
  return [
    Song(
      id: 'song_1',
      title: 'వందనం (Vandanam)',
      lyrics: '''[Chorus]
Em                      D     Em      Em                     G
వందనంయేసు నామము పాడెద పాడెద - వందనంయేసు నామము పాడెద పాడెద
G                 D                     C     D     Em          D       C     Em
వందనము తండ్రి తనయ షుడ్డా ధాతుమా - వందనము లుపాడెద

[Verse 1]
Em                                      D      Em    Em                         G
ఇనెన్నాళ్ళుళ్లా ధర్ము మమూరేయు - గనన్ తండ్రి మెంచె ఎపుడ్డు గాచెయు
G            D               C         D         Em          D    C       Em
ఎనన్లేన్ దెవెన లెడ్డు నన్ యేసువా - యనెన్ రేట్టుళ సోతారములేవేగో

[Verse 2]
Em                            D    Em     Em                                 G
పారత వతసరంపు మాప మంతయు - మెరేన్ మనన్ంచె ముమ గావుము
G        D                  C              D           Em    D   C     Em
నూత నాబదము న్నూదె నేత నొసగుమా - దాత కొరుస్త నాత రక్షకబా

[Verse 3]
Em.                            D           Em                         G
దేవ మాదు కాలుసేతు లేల్లను - సేవకాలె తనువు దెనముల్నన్యు
G               D         C         D               Em    D    C    Em
నెవోసంగు వేండ్డె పసెడ్డె జాన్యనమంత నె - సేవకఎ యంగెకరెంచుమా''',
      pageNumber: 1,
      category: 'Em',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_2',
      title: 'కృతజ్ఞతతో స్తుతి పాడేదా (Kruthagnathatho Sthuthi Padeda)',
      lyrics: '''[Chorus]
D                            A       Bm                G              D
Kruthagnathatho sthuthi padeda, naa yesu naadha
D                                  F#m               G             A         D
Nakai Neevu Chesina Mellakai, Koti Koti Kruthagnathalu… (2)

[Verse 1]
D      Bm                     A                                G              D
Arhathey Leni Naapai Needuprema Choopina Krupaamayaa..
D        Bm               A                                G              D
Arhathey Leni Naapai Needuprema Choopina Krupaamayaa..
G                                A                     Em             A             D
Naa Oohala Kantenu Adhikamugaa Dayacheyu Premaamaya…
G                                 A                   Em              A              D
Naa Oohala Kantenu Adhikamugaa Dayacheyu Premaamaya…

[Verse 2]
D                  Bm           A                        G                       D
Nija Rakshakudu Yesu Kreesthani Viswasincheda Anunityamu… 
D                   Bm          A                        G                       D
Nija Rakshakudu Yesu Kreesthani Viswasincheda Anunityamu… 
G                             A                     Em               A             D
Nee Paada Sevalo Brathukutakai - Ne Varamu Prasaadinchumu
G                             A                      Em              A              D
Nee Paada Sevalo Brathukutakai - Ne Varamulatho Abhisheykinchu''',
      pageNumber: 2,
      category: 'D',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_3',
      title: 'ఎమ్మానుయేలే (Emmanejare)',
      lyrics: '''[Intro] (Transpose +2, Bm)
Am  G           F           G               Em               Am
యేను నా ఇలులా నా ఇంట్టే వారంద్రు – మానక సుత్తెంచేదము  x2

    Dm    G            C Em         Dm         G      C  E
యెనె కనుపాపలే ననున్ కాచె – యేను చేదరక మోసావు సోతారం
     Dm    G            C Em         Dm         G      C Em
యెనె కనుపాపలే ననున్ కాచె – యేను చేదరక మోసావు సోతారం

[Chorus]
Am          F                G               Em   Am
ఎమెనేజరే ఎమెనేజరే – ఇంత కాలము కాచేతేవే
Am           F             G             Em    Am
ఎమెనేజరే ఎమెనేజరే – నా తోడ్డువఎ నడ్డేచేతేవే
F        G       Am         F              G          Am
సోతారం సోతారం సోతారం – కనుపాపగా కాచేతేవె సోతారం
F         G       Am         F             G       Am
సోతారం సోతారం సోతారం – కఉగెలెలొ దాచేతేవె సోతారం

[Verse 1]
Am         G     F      G               Em         Am
ఎడ్డారెలొ ఉనన్ నా జీవేతమును – మేళలాతొ నెంపెతేవె X2
     Dm    G            C  Em  Dm       G        C  Em
ఒక కొడ్డఎన దరె చేరక ననున్ – తండ్రిగా కాచావు సోతారం x2

[Verse 2]
Am        G        F                G                Em           Am
జాన్యనుల మధ్యన నను పెలెచెన నెపెలుపే – ఆశచారయం ఆశచారయమే. X2
     Dm      G   C  Em   Dm       G          C   Em
యెనె పాతరాను కానే కాదు – కేవలం నెనె కృప యే సోతారం X2

[Verse 3]
Am    G     F      G                   Em          Am
ఆశలే లేనె నాదు బరతుకును – నెనె కృపతొ నెంపెతేవె X2
         Dm       G        C  Em     Dm           G          C  Em
యెనెవు చూపెన పేరమను పాడగా – పదములు సరేపొవు తండ్రి X2''',
      pageNumber: 3,
      category: 'Am',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_4',
      title: 'నీ ప్రేమ ఎంతో గొప్పది (Nee Prema Entho Goppadi)',
      lyrics: '''[Chorus]
G                    D              Em              C
నీ ప్రేమ ఎంతో గొప్పది, నీ కృప ఎంతో గొప్పది
G                    D              C              G
నా జీవితాన్ని మార్చావు, నా హృదయాన్ని నింపావు

[Verse 1]
G                D                   Em              C
చీకటిలో ఉన్న నన్ను వెలుగులోకి తెచ్చావు
G                D                   C               G
దూరంగా ఉన్న నన్ను దగ్గరకు పిలిచావు

[Verse 2]
G                D                 Em              C
నీ బాహువులలో నేను సురక్షితంగా ఉన్నాను
G                D                   C               G
నీ ప్రేమలో నేను సంతోషంగా ఉన్నాను''',
      pageNumber: 4,
      category: 'G',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_5',
      title: 'మహిమ నీకే (Mahima Neeke)',
      lyrics: '''[Chorus]
C                G              Am              F
మహిమ నీకే, స్తుతి నీకే, ఆరాధన నీకే ప్రభువా
C                G              F               C
హల్లెలూయా, హల్లెలూయా, నీ నామం మహిమపరచుదాం

[Verse 1]
C                G                Am              F
నీవు సృష్టించిన ఈ లోకం ఎంతో అద్భుతం
C                G                F               C
నీ మహిమను ప్రకటిస్తుంది ప్రతి రోజు

[Verse 2]
C                G                Am              F
నీ దయ శాశ్వతం, నీ విశ్వాసం నిత్యం
C                G                F               C
తరతరాలకు నీ ప్రేమ నిలుస్తుంది''',
      pageNumber: 5,
      category: 'C',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_6',
      title: 'ఆరాధన (Aaradhana)',
      lyrics: '''[Chorus]
D                A              Bm              G
ఆరాధన చేస్తాం, స్తుతి పాడతాం
D                A              G               D
నీ నామం మహిమపరచుదాం, ప్రభువా

[Verse 1]
D                A                Bm              G
నీవు రాజు, నీవు ప్రభువు, నీవు రక్షకుడు
D                A                G               D
నీకు మాత్రమే మేము మొక్కుతాము

[Verse 2]
D                A                Bm              G
నీ సింహాసనం ముందు మేము వినమ్రమౌతాం
D                A                G               D
నీ మహిమలో మేము ఆనందిస్తాం''',
      pageNumber: 6,
      category: 'D',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_7',
      title: 'యేసయ్య నా రక్షకుడవు (Yesayya Naa Rakshakuduvu)',
      lyrics: '''[Chorus]
G                D              Em              C
యేసయ్య నా రక్షకుడవు, నా స్నేహితుడవు
G                D              C               G
నీ ప్రేమ నిత్యం, నీ కృప శాశ్వతం

[Verse 1]
G                D                Em              C
క్రూసు మీద నీవు చనిపోయావు నా కోసం
G                D                C               G
పునరుత్థానం చెంది జయించావు మృత్యువును

[Verse 2]
G                D                Em              C
నీ రక్తం ద్వారా నేను పరిశుద్ధుడను
G                D                C               G
నీ కృపతో నేను రక్షించబడ్డాను''',
      pageNumber: 7,
      category: 'G',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_8',
      title: 'హోసన్నా (Hosanna)',
      lyrics: '''[Chorus]
C                G              Am              F
హోసన్నా, హోసన్నా, మహోన్నతుడికి హోసన్నా
C                G              F               C
మహిమ, స్తుతి, ఆరాధన నీకే ప్రభువా

[Verse 1]
C                G                Am              F
నీవు దావీదు కుమారుడవు, ఇశ్రాయేలు రాజువు
C                G                F               C
నీవు వచ్చావు మాకు రక్షణ ఇవ్వడానికి

[Verse 2]
C                G                Am              F
నీ నామంలో మేము జయిస్తాము
C                G                F               C
నీ శక్తితో మేము బలపడతాము''',
      pageNumber: 8,
      category: 'C',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_9',
      title: 'స్తుతి పాడుదాం (Stuthi Paadadam)',
      lyrics: '''[Chorus]
D                A              Bm              G
స్తుతి పాడుదాం ప్రభువుకు, ఆయన మంచివాడు
D                A              G               D
ఆయన దయ శాశ్వతం, ఆయన ప్రేమ నిత్యం

[Verse 1]
D                A                Bm              G
ఆయన మన సృష్టికర్త, మన రక్షకుడు
D                A                G               D
ఆయన మన కాపరి, మన మార్గదర్శి

[Verse 2]
D                A                Bm              G
ఆయన మహిమ పరలోకంలో, భూమి మీద
D                A                G               D
సర్వ సృష్టి ఆయనను స్తుతిస్తుంది''',
      pageNumber: 9,
      category: 'D',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_10',
      title: 'నా హృదయం నీకు (Naa Hrudayam Neeku)',
      lyrics: '''[Chorus]
Em               Bm              C               G
నా హృదయం నీకు, నా జీవితం నీకు
Em               Bm              C               G
నా ఆత్మ నీకు, నా ప్రాణం నీకు

[Verse 1]
Em               Bm                C               G
నీవు నా ప్రభువు, నా దేవుడవు
Em               Bm                C               G
నీకు మాత్రమే నేను సేవిస్తాను

[Verse 2]
Em               Bm                C               G
నా కళ్ళు నీ మీద, నా మనసు నీ మీద
Em               Bm                C               G
నా ప్రేమ నీకు, నా భక్తి నీకు''',
      pageNumber: 10,
      category: 'Em',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_11',
      title: 'దేవుని కృప (Devuni Krupa)',
      lyrics: '''[Chorus]
G                D              Em              C
దేవుని కృప నాకు చాలు, ఆయన బలం నాలో పరిపూర్ణమౌతుంది
G                D              C               G
నా బలహీనతలో ఆయన బలవంతుడు

[Verse 1]
G                D                Em              C
నేను బలహీనుడిని, కానీ ఆయన బలవంతుడు
G                D                C               G
నేను చిన్నవాడిని, కానీ ఆయన గొప్పవాడు

[Verse 2]
G                D                Em              C
ఆయన కృప ప్రతిరోజు కొత్తది
G                D                C               G
ఆయన దయ ఎప్పటికీ అంతం కాదు''',
      pageNumber: 11,
      category: 'G',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_12',
      title: 'పరిశుద్ధుడు (Parishuddhudu)',
      lyrics: '''[Chorus]
C                G              Am              F
పరిశుద్ధుడు, పరిశుద్ధుడు, పరిశుద్ధుడు సర్వశక్తిమంతుడైన ప్రభువు
C                G              F               C
నీవు ఉన్నావు, నీవున్నావు, నీవు ఎప్పటికీ ఉంటావు

[Verse 1]
C                G                Am              F
స్వర్గదూతలు నిన్ను ఆరాధిస్తారు
C                G                F               C
సర్వ సృష్టి నీ మహిమను ప్రకటిస్తుంది

[Verse 2]
C                G                Am              F
నీ మహిమ భూమి నిండి ఉంది
C                G                F               C
నీ ప్రేమ ఆకాశం వరకు చేరుతుంది''',
      pageNumber: 12,
      category: 'C',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_13',
      title: 'నీవు నా రాతి (Neevu Naa Raathi)',
      lyrics: '''[Chorus]
D                A              Bm              G
నీవు నా రాతి, నా కోట, నా రక్షకుడవు
D                A              G               D
నీలో నేను సురక్షితంగా ఉన్నాను

[Verse 1]
D                A                Bm              G
తుఫానులు వచ్చినా నీవు నా ఆశ్రయం
D                A                G               D
కష్టాలు వచ్చినా నీవు నా బలం

[Verse 2]
D                A                Bm              G
నీ మీద నా నమ్మకం ఎప్పటికీ అచంచలం
D                A                G               D
నీ ప్రేమలో నేను ఎప్పటికీ స్థిరంగా ఉంటాను''',
      pageNumber: 13,
      category: 'D',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_14',
      title: 'ఆనందం (Aanandham)',
      lyrics: '''[Chorus]
G                D              Em              C
ఆనందం ప్రభువులో, సంతోషం ఆయనలో
G                D              C               G
నా బలం ఆయనే, నా ఆశ ఆయనే

[Verse 1]
G                D                Em              C
ఆయన ఉన్నప్పుడు నాకు భయం లేదు
G                D                C               G
ఆయన నాతో ఉంటే నాకు ఏమీ కావాలి

[Verse 2]
G                D                Em              C
ఆయన మహిమలో నేను ఆనందిస్తాను
G                D                C               G
ఆయన ప్రేమలో నేను సంతోషిస్తాను''',
      pageNumber: 14,
      category: 'G',
      createdAt: DateTime.now(),
    ),
    Song(
      id: 'song_15',
      title: 'నా గొల్లవాడా (Naa Gollavada)',
      lyrics: '''[Chorus]
C                G              Am              F
నా గొల్లవాడా యేసయ్య, నాకు ఏమీ లోటు లేదు
C                G              F               C
నీవు నన్ను మేపుతావు, నన్ను కాపాడుతావు

[Verse 1]
C                G                Am              F
పచ్చిక బయళ్ళలో నన్ను పడుకోపెడతావు
C                G                F               C
నిమ్మళ జలాల దగ్గరికి నన్ను నడిపిస్తావు

[Verse 2]
C                G                Am              F
చావునీడ లోయలో నడిచినా భయపడను
C                G                F               C
నీవు నాతో ఉన్నావు, నీ కర్ర నాకు ఆదరణ''',
      pageNumber: 15,
      category: 'C',
      createdAt: DateTime.now(),
    ),
  ];
}
