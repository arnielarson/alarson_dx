# Mysterious Data Questions


## Mystery Data

A mysterious dataset lands in your folder, maybe it has a message?

```bash
$ head prob1.txt
0,8.53,tintype,0.4609451931214813,260784,countermeasure
1,5.52,For,0.8221115385232872,310733,malleable
2,1.33,You,0.6270877252416602,434806,dinnerware
3,9.97,percept,0.1053007638397988,776341,schema
4,3.44,Allentown,0.2329802441597597,442039,Elisha
5,7.64,blind,0.019308783996426326,810728,crucifixion
6,8.15,extenuate,0.29749479594839734,992624,passim
7,7.2,sombre,0.5174845024469695,743212,thumb
8,2.88,prude,0.08728433625118182,160827,Saskatchewan
9,6.99,casework,0.25001692202279935,438411,acerbic
```

Hmm, very mysterious, maybe there's a message?  Let's load it into SQL and look a little deeper..

The first col is distinct [0,247749999] basically a primary key.  The second is a numeric key with range:  0..10  The third numeric seems to be in the (0,1) range?  The fourth numeric is not distinct?  Range of [0,1000000].  The first text col has 25495 distinct values.  The second text col has 25487 distinct values.

Hypotheses at this point include looking at ordering from numeric values, cardinality of words.
Another quick query and it looks like the non primary key numeric cols have averages in the middle of their ranges, so drawn from a uniform sample.. probably a decoy.
Given other information I'd expect the query to not be overly complicated.
I was thinking about self joining the text, or window functioning to see cardinality.. but a simpler group by query with order to look at cardinality found the answer..

"The Answer You Are Looking For Is WearYourMask!!"

## Address Data 

2 data sets are available with addresses (and other information).
How would I go about looking to match set B against set A?
This likely will require inspecting the data and determing what or if I need to do some text munging to normalize and match.

Mechanism is roughly:

- Look at both datasets.  Are the formats consistent?  
- NCSE has some casing, some odd characters ("-.) in odd places
- Note, I had to use Pandas to try and extract the .xls file into a format I could load into SQL
- Headstart has 2 address fields, address 1 seems slightly more standardized.  Address 2 is not consistently used.. (Suite, Ste, RM, Rooms, proper nouns)
- Are there duplicates?
- Is ZIP valid?  fully populated?
- Ok - now look at the data and determine a normalization prodcedure, iterate a couple times..
- Normalize both addresses in the same way
- Plan to compare (JOIN) on something like DISTINCT CONCAT(TRIM(address1),ZIP)
- Before normalizations I found 40 matches, after normalizations I found 63 matches.

### Questions

- How many distinct addresses does each dataset have?
  - Headstart: approx 310
  - NCSE: approx 2096
- How many addresses overlap?
  - approx 63
- Write a query to return the headstart dataset and a flag indicating if there is a match with NCSE:
  - See SQL.  Required a bit of different logic, a left join and need to be careful of duplicates within the NCSE data

### Improvements

Additionally, I would iterate a few more times to determine if there some more rules.  (I can think of at least a few more likely issues that could be addressed, e.g. whitespace)

- First, I don't know of a better way to do this type of text manipulation in SQL, other than the nested REPLACE functions, which is not ideal for maintainability.
- Address 2 in headstart could be inspected and further rules could be used to incorporate it.
- To modularize, you could break up the REPLACE statements, maybe into multiple stored procedures or functions to make this modular and testable.
- You could also try some sort of fuzzy matching to possibly catch more longtail matches, but then also may need to consider false positives.
- In reality, address standardization is hard and using a 3rd party to standardize is potentially a better alternative


## Python 

I use Python and Pandas to do a simple group by roll up against the mystery data

## Big Data

Wikipedia click stream summarization.  

A quick look at one file:  data is about 1.5GB, 33M records.  What happens to large analytics queries when we go up an order of magnitude?

The data has (referrer, resource, link_type(external|link), count).  The goal is to perform a simple analysis of the top 50 sites.. 

Quick thoughts: 100M+ records will definitely likely tax my system.  My instinct is I don't want to join, and I only want to do one full table scan.  If I **can not** do the full scan in one go, then it may be easier to partition the data by month_date and create summary tables for each month and then group them later.  It will be interesting to see how a query against the full data goes.  This could be an interseting place to finally try out DuckDB, although since it is scanning and using all of the data, I wouldn't anticipate any giant performance improvement.

### More notes with my setup: 

- Note I have a local Postgres setup, newer Mac and 16GB Ram
- Trouble loading with Postgres COPY FROM, there are 'Control-\\' values, which escaped the tab char, so, removed those lines them with awk
- I'm going to explore several ways to do these queries.
- A group by from a single file, shows the top 100 resources
- A window function would enable further granular analysis.  
- From a single file, a group by and SUM(count) shows that filtering with 1000000 there's about 115 pages
- On a single file, full scan analytics queries are taking around 3 or 4 minutes
- On the full dataset, the query took around 20 minutes
- Would be interesting to use Explain to explore aspects of query performance

### Summary

This summary includes the resource/page, total visists, total pages referring, distinct external and internal links, and list the top referring page/type

|resource|total_count|referrer_pages_total|external_count|link_count|top_referrer|
|--------|-----------|--------------------|--------------|----------|------------|
|Main_Page|1790446171|755804|1760791644|226317|other-empty|
|United_States_Senate|333961178|6247|333417303|522476|other-empty|
|Hyphen-minus|259228757|785450|211852005|27570|other-empty|
|2019–20_coronavirus_pandemic|30709138|5876|22548219|8016260|other-search|
|Coronavirus|30398350|3917|28948052|898426|other-search|
|Kobe_Bryant|29570561|6147|27859950|1299889|other-search|
|COVID-19_pandemic|26122549|12246|19196015|6835413|other-empty|
|Deaths_in_2020|22977729|2385|13270033|9631206|other-empty|
|Wikipedia|18869606|1416|18389543|473461|other-empty|
|Bible|18661917|2854|18532135|119438|other-empty|
|Spanish_flu|18383278|3329|17023916|1190844|other-search|
|Michael_Jordan|15822408|4600|13908293|1806744|other-search|
|Coronavirus_disease_2019|15661797|8674|10722381|4688240|other-search|
|Donald_Trump|15638853|12338|12929591|2584890|other-search|
|Parasite_(2019_film)|15515546|2136|14122256|1084530|other-search|
|Tasuku_Honjo|13804559|147|13786830|15964|other-empty|
|Sushant_Singh_Rajput|13282965|790|12545473|685884|other-search|
|Elon_Musk|13106798|2123|11633807|1393410|other-search|
|Media|11507298|69|11504775|495|other-empty|
|Joe_Exotic|11190384|378|9059267|2087146|other-search|
|Elizabeth_II|10678193|9555|6603299|4032948|other-search|
|COVID-19_pandemic_by_country_and_territory|9516688|591|8559168|952442|other-search|
|Aaron_Hernandez|9442926|891|9206871|192532|other-search|
|2020_Democratic_Party_presidential_primaries|9159462|2866|7326146|1631388|other-search|
|Billie_Eilish|9022928|2502|8045621|906318|other-search|
|Kim_Jong-un|8597618|2088|7420581|1105946|other-search|
|United_States|8597405|46591|5319035|3146663|other-search|
|Money_Heist|8504154|970|8025923|422454|other-search|
|2019–20_coronavirus_outbreak|8375129|763|6105194|2251956|other-empty|
|Microsoft_Office|8349682|630|8288348|56988|other-empty|
|COVID-19_pandemic_in_India|8107051|447|7514765|582135|other-search|
|2019–20_coronavirus_pandemic_by_country_and_territory|8088761|277|7051617|1033225|other-search|
|1917_(2019_film)|8052665|1696|7160349|736106|other-search|
|Jeffrey_Epstein|7903449|1202|7394844|470587|other-search|
|Antifa_(United_States)|7876876|579|7522151|338909|other-search|
|Irrfan_Khan|7823677|1266|7275841|505499|other-search|
|F5_Networks|7777373|151|7769290|7922|other-empty|
|XXXX|7736672|178|7709593|7554|other-search|
|Kepler's_Supernova|7649753|147|7628702|20910|other-empty|
|Black_Death|7577946|3256|6211686|1318579|other-search|
|BBC_World_Service|7418363|635|7375533|41879|other-external|
|Ken_Miles|7385989|536|6460069|897366|other-search|
|List_of_Marvel_Cinematic_Universe_films|7259083|803|6545420|697047|other-search|
|2020_coronavirus_pandemic_in_India|7192772|201|6607929|581514|other-search|
|Carole_Baskin|7164347|134|5325626|1824108|other-search|
|Juneteenth|7079393|506|6985175|45235|other-search|
|Andrew_Cuomo|7070731|1549|5760905|1269946|other-search|
|Killing_of_George_Floyd|7069086|519|6455424|482753|other-search|
|Ozark_(TV_series)|7031057|1478|6590453|346842|other-search|
|YouTube|6966144|18882|6037989|871103|other-empty|



