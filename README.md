# What
Create a stand-alone interpretation engine (using NASIS data) in R.

# Why
I think we all know why.

# How
The [data.tree](https://cran.r-project.org/web/packages/data.tree/vignettes/data.tree.html) package defines objects and methods that are well suited to the task of describing the hierachy of rules and evaluations. The mapping between domain vaules and fuzzy membership can be accomplished with `approxfun`.

## Outline
1. load rules and evaluations in R via ODBC as `data.frames`
2. select an interpretation (single top-level rule)
3. load rule and sub-rules into a `data.tree` object
4. load evaluation functions into each terminal node of `data.tree` object
5. create wrapper function to send properties to evaluation functions
6. generate fuzzy rating


## Things to Figure Out
1. attach evaluation functions to `data.tree` object terminal nodes
2. convert property NASIS-report language into actual values

## Ideas
1. http://stackoverflow.com/questions/32522068/order-of-siblings-and-their-kids-in-string/32725097
2. https://cran.r-project.org/web/packages/frbs/index.html
3. https://en.wikipedia.org/wiki/Fuzzy_control_system

## Examples
### Dust PM10 and PM2.5 Generation
<pre style="font-size: 70%; font-family: monospace">
1  Dust PM10 and PM2.5 Generation                                                                                   NA           
2   °--RuleHedge_de473ab5                                                              multiply   0.5               NA           
3       °--RuleOperator_0a397761                                                        product                     NA           
4           ¦--Dryness Index 0.5 to 3                                                                 18448         NA      18448
5           °--RuleOperator_7025ab26                                                        sum                     NA           
6               ¦--Dust Due to Gypsum                                                                               NA           
7               ¦   °--RuleHedge_5c18cb73                                          not_null_and     0               NA           
8               ¦       °--Dust from Gypsum Content 2 to 15 Percent                                   18446         NA      18446
9               °--Dust Due to Silt and Clay                                                                        NA           
10                  °--RuleHedge_caf7e2e0                                        null_not_rated     0               NA           
11                      °--Dust from Silt and Clay Content 20 to 70 Percent Sand                      18447         NA      18447
</pre>

### CA Storie Index
<pre style="font-size: 65%; font-family: monospace">
                                                                                levelName           Type Value RefId rule_refid eval_refid
1   AGR - California Revised Storie Index (CA)                                                                                             NA           
2    °--RuleOperator_31a1eb65                                                                                  product                     NA           
3        ¦--*Storie Factor A Not Rated Soil Orders rev                                                                                     NA           
4        ¦   °--RuleHedge_1193d3c1                                                                             null_or     0               NA           
5        ¦       °--*Storie Factor A Pedon Group not rated taxonomy rev                                                      50481         NA      50481
6        ¦--*Storie Factor A                                                                                                               NA           
7        ¦   °--RuleOperator_01948bb8                                                                               or                     NA           
8        ¦       ¦--*Storie Factor A Profile Group 1 rev                                                                                   NA           
9        ¦       ¦   °--RuleOperator_a72ba798                                                                      and                     NA           
10       ¦       ¦       ¦--RuleOperator_b267bf8e                                                                times                     NA           
11       ¦       ¦       ¦   ¦--*Storie Factor A Profile Group 1 and 2 fuzzy depth                                                         NA           
12       ¦       ¦       ¦   ¦   °--RuleHedge_7fad1a79                                                    not_null_and     0               NA           
13       ¦       ¦       ¦   ¦       °--*Storie Factor A Pedon Group 1 and 2 soil depth                                      12916         NA      12916
14       ¦       ¦       ¦   °--*Storie Factor A Profile Group 1 taxonomy rev                                                              NA           
15       ¦       ¦       ¦       °--RuleOperator_4d1fdd8f                                                           or                     NA           
16       ¦       ¦       ¦           ¦--RuleHedge_44b2d8f3                                                not_null_and     0               NA           
17       ¦       ¦       ¦           ¦   °--*Storie Factor A Pedon Group 1 suborders                                         12914         NA      12914
18       ¦       ¦       ¦           ¦--RuleHedge_f2a5b4ba                                                not_null_and     0               NA           
19       ¦       ¦       ¦           ¦   °--*Storie Factor A Pedon Group 1 great groups                                      12915         NA      12915
20       ¦       ¦       ¦           °--RuleHedge_25e606a5                                                not_null_and     0               NA           
21       ¦       ¦       ¦               °--*Storie Factor A Pedon Group 1 subgroups                                         13092         NA      13092
22       ¦       ¦       °--RuleHedge_ea4b1839                                                                     not     0               NA           
23       ¦       ¦           °--*Storie Factor A Profile Group 7,8,9 landform                                                              NA           
24       ¦       ¦               °--RuleHedge_608f03c8                                                    not_null_and     0               NA           
25       ¦       ¦                   °--*Storie Factor A Pedon Group 7, 8, 9 landform                                        12917         NA      12917
26       ¦       ¦--*Storie Factor A Profile Group 2 rev                                                                                   NA           
27       ¦       ¦   °--RuleOperator_8a20de79                                                                      and                     NA           
28       ¦       ¦       ¦--RuleOperator_71911310                                                                times                     NA           
29       ¦       ¦       ¦   ¦--*Storie Factor A Profile Group 1 and 2 fuzzy depth                                                         NA           
30       ¦       ¦       ¦   ¦   °--RuleHedge_7fad1a79                                                    not_null_and     0               NA           
31       ¦       ¦       ¦   ¦       °--*Storie Factor A Pedon Group 1 and 2 soil depth                                      12916         NA      12916
32       ¦       ¦       ¦   °--*Storie Factor A Profile Group 2 taxonomy                                                                  NA           
33       ¦       ¦       ¦       °--RuleOperator_0ad34d47                                                           or                     NA           
34       ¦       ¦       ¦           ¦--RuleHedge_698c3a67                                                not_null_and     0               NA           
35       ¦       ¦       ¦           ¦   °--*Storie Factor A Pedon Group 2 suborders Arents and Cambids                      12929         NA      12929
36       ¦       ¦       ¦           °--RuleHedge_8fbcb397                                                not_null_and     0               NA           
37       ¦       ¦       ¦               °--*Storie Factor A Pedon Group 2 great groups                                      12927         NA      12927
38       ¦       ¦       °--RuleHedge_ea4b1839                                                                     not     0               NA           
39       ¦       ¦           °--*Storie Factor A Profile Group 7,8,9 landform                                                              NA           
40       ¦       ¦               °--RuleHedge_608f03c8                                                    not_null_and     0               NA           
41       ¦       ¦                   °--*Storie Factor A Pedon Group 7, 8, 9 landform                                        12917         NA      12917
42       ¦       ¦--*Storie Factor A Profile Group 3                                                                                       NA           
43       ¦       ¦   °--RuleOperator_a84c18cd                                                                      and                     NA           
44       ¦       ¦       ¦--*Storie Factor A Profile Group 3 taxonomy                                                                      NA           
45       ¦       ¦       ¦   °--RuleOperator_c859411b                                                               or                     NA           
46       ¦       ¦       ¦       ¦--RuleHedge_a14e5a0e                                                    not_null_and     0               NA           
47       ¦       ¦       ¦       ¦   °--*Storie Factor A Pedon Group 3 great groups                                          12931         NA      12931
48       ¦       ¦       ¦       °--RuleOperator_15a86db4                                                          and                     NA           
49       ¦       ¦       ¦           ¦--RuleHedge_da245a09                                                not_null_and     0               NA           
50       ¦       ¦       ¦           ¦   °--*Storie Factor A Pedon Group 4/6 great groups                                    12934         NA      12934
51       ¦       ¦       ¦           ¦--RuleHedge_61008193                                                         not     0               NA           
52       ¦       ¦       ¦           ¦   °--RuleHedge_1a2fddac                                            not_null_and     0               NA           
53       ¦       ¦       ¦           ¦       °--*Storie featkind = abrupt textural change                                    13106         NA      13106
54       ¦       ¦       ¦           °--RuleHedge_214d73a9                                                         not     0               NA           
55       ¦       ¦       ¦               °--RuleHedge_137ed382                                            not_null_and     0               NA           
56       ¦       ¦       ¦                   °--Component restriction = "abrupt textural change"                             11459         NA      11459
57       ¦       ¦       °--*Storie Factor A Profile Group 3 fuzzy depth                                                                   NA           
58       ¦       ¦           °--RuleHedge_725c57d0                                                        not_null_and     0               NA           
59       ¦       ¦               °--*Storie Factor A Pedon Group 3 soil depth                                                12938         NA      12938
60       ¦       ¦--*Storie Factor A Profile Group 5                                                                                       NA           
61       ¦       ¦   °--RuleOperator_38a12238                                                                      and                     NA           
62       ¦       ¦       ¦--RuleOperator_1ffc51b2                                                                times                     NA           
63       ¦       ¦       ¦   ¦--*Storie Factor A Profile Group 5 fuzzy depth                                                               NA           
64       ¦       ¦       ¦   ¦   °--RuleHedge_a4df1747                                                    not_null_and     0               NA           
65       ¦       ¦       ¦   ¦       °--*Storie Factor A Pedon Group 5 soil depth                                            12939         NA      12939
66       ¦       ¦       ¦   °--*Storie Factor A Profile Group 5 taxonomy                                                                  NA           
67       ¦       ¦       ¦       °--RuleOperator_d8ea2331                                                           or                     NA           
68       ¦       ¦       ¦           ¦--RuleHedge_aba67333                                                not_null_and     0               NA           
69       ¦       ¦       ¦           ¦   °--*Storie Factor A Pedon Group 5 durids                                            12932         NA      12932
70       ¦       ¦       ¦           ¦--RuleHedge_a831076b                                                not_null_and     0               NA           
71       ¦       ¦       ¦           ¦   °--*Storie Factor A Pedon Group 5 great groups                                      12933         NA      12933
72       ¦       ¦       ¦           °--RuleHedge_7954eb2b                                                not_null_and     0               NA           
73       ¦       ¦       ¦               °--*Storie Factor A Pedon Group 5 subgroups                                         13093         NA      13093
74       ¦       ¦       °--RuleHedge_ea4b1839                                                                     not     0               NA           
75       ¦       ¦           °--*Storie Factor A Profile Group 7,8,9 landform                                                              NA           
76       ¦       ¦               °--RuleHedge_608f03c8                                                    not_null_and     0               NA           
77       ¦       ¦                   °--*Storie Factor A Pedon Group 7, 8, 9 landform                                        12917         NA      12917
78       ¦       ¦--*Storie Factor A Profile Group 4/6                                                                                     NA           
79       ¦       ¦   °--RuleOperator_867650f1                                                                    times                     NA           
80       ¦       ¦       ¦--*Storie Factor A Profile Group 4/6 fuzzy depth                                                                 NA           
81       ¦       ¦       ¦   °--RuleOperator_804837c6                                                              and                     NA           
82       ¦       ¦       ¦       ¦--RuleHedge_74ec3ef6                                                    not_null_and     0               NA           
83       ¦       ¦       ¦       ¦   °--*Storie Factor A Pedon Group 4/6 depth abrupt text featkind                          13207         NA      13207
84       ¦       ¦       ¦       °--RuleHedge_5d562f5b                                                    not_null_and     0               NA           
85       ¦       ¦       ¦           °--*Storie Factor A Pedon Group 4/6 depth abrupt tex reskind                            13208         NA      13208
86       ¦       ¦       °--*Storie Factor A Profile Group 4/6 taxonomy w/ abrupt text                                                     NA           
87       ¦       ¦           °--RuleOperator_d7eb1bf2                                                              and                     NA           
88       ¦       ¦               ¦--*Storie Factor A Pedon Group 4/6 great groups                                            12934         NA      12934
89       ¦       ¦               °--RuleOperator_55f9f74b                                                           or                     NA           
90       ¦       ¦                   ¦--*Storie featkind = abrupt textural change                                            13106         NA      13106
91       ¦       ¦                   °--Component restriction = "abrupt textural change"                                     11459         NA      11459
92       ¦       °--*Storie Factor A Profile Groups 7, 8 or 9                                                                              NA           
93       ¦           °--RuleOperator_e9966d4d                                                                      and                     NA           
94       ¦               ¦--RuleOperator_48460ff8                                                                times                     NA           
95       ¦               ¦   ¦--*Storie Factor A Profile Group 7,8,9 landform                                                              NA           
96       ¦               ¦   ¦   °--RuleHedge_608f03c8                                                    not_null_and     0               NA           
97       ¦               ¦   ¦       °--*Storie Factor A Pedon Group 7, 8, 9 landform                                        12917         NA      12917
98       ¦               ¦   °--*Storie Factor A Profile Groups 7, 8, 9 fuzzy depth (hard)                                                 NA           
99       ¦               ¦       °--RuleHedge_62ac73b3                                                    not_null_and     0               NA           
100      ¦               ¦           °--*Storie Factor A Pedon Group 7 and 8 soil depth                                      12919         NA      12919
101      ¦               °--RuleOperator_9ffcd0a2                                                                times                     NA           
102      ¦                   ¦--*Storie Factor A Profile Group 7,8,9 landform                                                              NA           
103      ¦                   ¦   °--RuleHedge_608f03c8                                                    not_null_and     0               NA           
104      ¦                   ¦       °--*Storie Factor A Pedon Group 7, 8, 9 landform                                        12917         NA      12917
105      ¦                   °--*Storie Factor A Profile Group 7, 8 and 9 fuzzy depth (soft)                                               NA           
106      ¦                       °--RuleHedge_c0fd8926                                                    not_null_and     0               NA           
107      ¦                           °--*Storie Factor A Pedon Group 9 soil depth                                            12947         NA      12947
108      ¦--*Storie Factor B rev                                                                                                           NA           
109      ¦   °--RuleOperator_21467f0e                                                                            times                     NA           
110      ¦       ¦--*Storie Factor B surface texture rev                                                                                   NA           
111      ¦       ¦   °--RuleHedge_14c104e8                                                              null_not_rated     0               NA           
112      ¦       ¦       °--*Storie Factor B Surface Texture                                                                 50479         NA      50479
113      ¦       °--*Storie Factor B surface rock fragments rev                                                                            NA           
114      ¦           °--*Storie Factor B rock frag volume 0-25 cm                                                            50480         NA      50480
115      ¦--*Storie Factor C Slope fuzzy                                                                                                   NA           
116      ¦   °--RuleHedge_d4054451                                                                      null_not_rated     0               NA           
117      ¦       °--*Storie Factor C Slope 0 to 100%                                                                         12800         NA      12800
118      ¦--*Storie Factor X (all chemistry) rev                                                                                           NA           
119      ¦   °--RuleOperator_12d91bc8                                                                              and                     NA           
120      ¦       ¦--*Storie Factor X (toxicity EC) rev                                                                                     NA           
121      ¦       ¦   °--RuleHedge_7334ea83                                                                     null_or     0               NA           
122      ¦       ¦       °--*Storie Factor X Toxicity EC maximum 0-25 cm                                                     50477         NA      50477
123      ¦       ¦--*Storie Factor X (toxicity SAR) rev                                                                                    NA           
124      ¦       ¦   °--RuleHedge_70d0ed1f                                                                     null_or     0               NA           
125      ¦       ¦       °--*Storie Factor X Toxicity SAR maximum 0-25 cm                                                    50478         NA      50478
126      ¦       °--*Storie Factor X (toxicity pH) rev                                                                                     NA           
127      ¦           °--RuleHedge_dea55415                                                                     null_or     0               NA           
128      ¦               °--RuleOperator_37d7e82f                                                                  and                     NA           
129      ¦                   ¦--*Storie Factor X Toxicity pH minimum 0-25 cm                                                 50475         NA      50475
130      ¦                   °--*Storie Factor X Toxicity pH maximum 0-25 cm                                                 50476         NA      50476
131      ¦--*Storie Factor X (all hydrologic and erosion features)                                                                         NA           
132      ¦   °--RuleOperator_e5feb45e                                                                              and                     NA           
133      ¦       ¦--*Storie Factor X (drainage class)                                                                                      NA           
134      ¦       ¦   °--RuleOperator_3be6bd57                                                                       or                     NA           
135      ¦       ¦       ¦--RuleOperator_fb03758e                                                                  sum                     NA           
136      ¦       ¦       ¦   ¦--RuleHedge_773dd408                                                               limit   0.9               NA           
137      ¦       ¦       ¦   ¦   °--*Storie Factor X drainage = moderately well                                                            NA           
138      ¦       ¦       ¦   ¦       °--RuleHedge_cacbefaa                                              null_not_rated     0               NA           
139      ¦       ¦       ¦   ¦           °--*Storie Factor X drainage class = moderately                                     13114         NA      13114
140      ¦       ¦       ¦   °--RuleOperator_bff68afb                                                               or                     NA           
141      ¦       ¦       ¦       ¦--RuleHedge_60689286                                                           limit   0.1               NA           
142      ¦       ¦       ¦       ¦   °--*Storie Factor X local phase is "drained"                                                          NA           
143      ¦       ¦       ¦       ¦       °--RuleHedge_be509db7                                            not_null_and     0               NA           
144      ¦       ¦       ¦       ¦           °--*Storie component local phase is *drained*                                   13117         NA      13117
145      ¦       ¦       ¦       °--RuleHedge_9acf6418                                                           limit  0.05               NA           
146      ¦       ¦       ¦           °--*Storie Factor X local phase is "partially drained"                                                NA           
147      ¦       ¦       ¦               °--RuleHedge_a792a01a                                            not_null_and     0               NA           
148      ¦       ¦       ¦                   °--*Storie component local phase is *partially drained*                         13121         NA      13121
149      ¦       ¦       ¦--RuleOperator_b07fd13d                                                                  sum                     NA           
150      ¦       ¦       ¦   ¦--RuleHedge_4f74ec66                                                               limit   0.7               NA           
151      ¦       ¦       ¦   ¦   °--*Storie Factor X drainage = somewhat poorly                                                            NA           
152      ¦       ¦       ¦   ¦       °--RuleHedge_72e64559                                              null_not_rated     0               NA           
153      ¦       ¦       ¦   ¦           °--*Storie Factor X drainage class = somewhat poorly                                13113         NA      13113
154      ¦       ¦       ¦   °--RuleOperator_fac62418                                                               or                     NA           
155      ¦       ¦       ¦       ¦--RuleHedge_7c3c6ede                                                           limit   0.2               NA           
156      ¦       ¦       ¦       ¦   °--*Storie Factor X local phase is "drained"                                                          NA           
157      ¦       ¦       ¦       ¦       °--RuleHedge_be509db7                                            not_null_and     0               NA           
158      ¦       ¦       ¦       ¦           °--*Storie component local phase is *drained*                                   13117         NA      13117
159      ¦       ¦       ¦       °--RuleHedge_b1c9b07e                                                           limit   0.1               NA           
160      ¦       ¦       ¦           °--*Storie Factor X local phase is "partially drained"                                                NA           
161      ¦       ¦       ¦               °--RuleHedge_a792a01a                                            not_null_and     0               NA           
162      ¦       ¦       ¦                   °--*Storie component local phase is *partially drained*                         13121         NA      13121
163      ¦       ¦       ¦--RuleOperator_f2cb68fb                                                                  sum                     NA           
164      ¦       ¦       ¦   ¦--RuleHedge_80a214a1                                                               limit   0.5               NA           
165      ¦       ¦       ¦   ¦   °--RuleHedge_f60f0b26                                                  null_not_rated     0               NA           
166      ¦       ¦       ¦   ¦       °--*Storie Factor X drainage = poorly or very poorly                                                  NA           
167      ¦       ¦       ¦   ¦           °--RuleHedge_9edb6995                                          null_not_rated     0               NA           
168      ¦       ¦       ¦   ¦               °--*Storie Factor X drainage class = poor or very poorly                        13112         NA      13112
169      ¦       ¦       ¦   °--RuleOperator_799a4c22                                                               or                     NA           
170      ¦       ¦       ¦       ¦--RuleHedge_711817c6                                                           limit   0.4               NA           
171      ¦       ¦       ¦       ¦   °--*Storie Factor X local phase is "drained"                                                          NA           
172      ¦       ¦       ¦       ¦       °--RuleHedge_be509db7                                            not_null_and     0               NA           
173      ¦       ¦       ¦       ¦           °--*Storie component local phase is *drained*                                   13117         NA      13117
174      ¦       ¦       ¦       °--RuleHedge_b1c9b07e                                                           limit   0.1               NA           
175      ¦       ¦       ¦           °--*Storie Factor X local phase is "partially drained"                                                NA           
176      ¦       ¦       ¦               °--RuleHedge_a792a01a                                            not_null_and     0               NA           
177      ¦       ¦       ¦                   °--*Storie component local phase is *partially drained*                         13121         NA      13121
178      ¦       ¦       ¦--*Storie Factor X drainage = well drained                                                                       NA           
179      ¦       ¦       ¦   °--RuleHedge_80e2e2c3                                                      null_not_rated     0               NA           
180      ¦       ¦       ¦       °--*Storie Factor X drainage class = well                                                   13107         NA      13107
181      ¦       ¦       °--RuleHedge_c0debf92                                                                   limit  0.85               NA           
182      ¦       ¦           °--*Storie Factor X drainage = all excessively                                                                NA           
183      ¦       ¦               °--RuleHedge_2347996a                                                  null_not_rated     0               NA           
184      ¦       ¦                   °--*Storie Factor X drainage class = all excessively                                    13111         NA      13111
185      ¦       ¦--*Storie Factor X (flooding and ponding)                                                                                NA           
186      ¦       ¦   °--RuleOperator_dae2aeb4                                                                      and                     NA           
187      ¦       ¦       ¦--*Storie Factor X (ponding interaction)                                                                         NA           
188      ¦       ¦       ¦   °--*Storie Factor X landscape ponding in growing season                                         13115         NA      13115
189      ¦       ¦       °--*Storie Factor X (flooding interaction)                                                                        NA           
190      ¦       ¦           °--RuleOperator_fe6380a3                                                               or                     NA           
191      ¦       ¦               ¦--Landscape Flooding "NONE"                                                                10265         NA      10265
192      ¦       ¦               °--*Storie Factor X landscape flooding in growing season                                    12952         NA      12952
193      ¦       ¦--*Storie Factor X (erosion)                                                                                             NA           
194      ¦       ¦   °--RuleOperator_435f004a                                                                       or                     NA           
195      ¦       ¦       ¦--*Storie Factor X (erosion in uplands)                                                                          NA           
196      ¦       ¦       ¦   °--RuleOperator_2be43cb6                                                              and                     NA           
197      ¦       ¦       ¦       ¦--*Storie Factor A Profile Group 7,8,9 landform                                                          NA           
198      ¦       ¦       ¦       ¦   °--RuleHedge_608f03c8                                                not_null_and     0               NA           
199      ¦       ¦       ¦       ¦       °--*Storie Factor A Pedon Group 7, 8, 9 landform                                    12917         NA      12917
200      ¦       ¦       ¦       °--*Storie Factor X (erosion class)                                                                       NA           
201      ¦       ¦       ¦           °--RuleOperator_3ecc937e                                                       or                     NA           
202      ¦       ¦       ¦               ¦--RuleHedge_d47e12df                                                   limit  0.95               NA           
203      ¦       ¦       ¦               ¦   °--*Storie Factor X erosion class = 1                                                         NA           
204      ¦       ¦       ¦               ¦       °--RuleHedge_be73ca0c                                         null_or     0               NA           
205      ¦       ¦       ¦               ¦           °--*Storie Factor X erosion class = 1                                   13213         NA      13213
206      ¦       ¦       ¦               ¦--RuleHedge_62c7497e                                                   limit  0.85               NA           
207      ¦       ¦       ¦               ¦   °--*Storie Factor X erosion class = 2                                                         NA           
208      ¦       ¦       ¦               ¦       °--RuleHedge_5c67fdf4                                         null_or     0               NA           
209      ¦       ¦       ¦               ¦           °--*Storie Factor X erosion class = 2                                   13214         NA      13214
210      ¦       ¦       ¦               ¦--RuleHedge_16378273                                                   limit  0.75               NA           
211      ¦       ¦       ¦               ¦   °--*Storie Factor X erosion class = 3                                                         NA           
212      ¦       ¦       ¦               ¦       °--RuleHedge_c65bf0da                                         null_or     0               NA           
213      ¦       ¦       ¦               ¦           °--*Storie Factor X erosion class = 3                                   13217         NA      13217
214      ¦       ¦       ¦               ¦--RuleHedge_68a3b3e6                                                   limit  0.65               NA           
215      ¦       ¦       ¦               ¦   °--*Storie Factor X erosion class = 4                                                         NA           
216      ¦       ¦       ¦               ¦       °--RuleHedge_772054de                                         null_or     0               NA           
217      ¦       ¦       ¦               ¦           °--*Storie Factor X erosion class = 4                                   13216         NA      13216
218      ¦       ¦       ¦               °--*Storie Factor X erosion class = 0                                                             NA           
219      ¦       ¦       ¦                   °--RuleHedge_b3c4b963                                             null_or     0               NA           
220      ¦       ¦       ¦                       °--*Storie Factor X erosion class = 0                                       13212         NA      13212
221      ¦       ¦       °--*Storie Factor X (erosion in valley)                                                                           NA           
222      ¦       ¦           °--RuleOperator_9fee9122                                                              and                     NA           
223      ¦       ¦               ¦--*Storie Factor X (erosion class)                                                                       NA           
224      ¦       ¦               ¦   °--RuleOperator_3ecc937e                                                       or                     NA           
225      ¦       ¦               ¦       ¦--RuleHedge_d47e12df                                                   limit  0.95               NA           
226      ¦       ¦               ¦       ¦   °--*Storie Factor X erosion class = 1                                                         NA           
227      ¦       ¦               ¦       ¦       °--RuleHedge_be73ca0c                                         null_or     0               NA           
228      ¦       ¦               ¦       ¦           °--*Storie Factor X erosion class = 1                                   13213         NA      13213
229      ¦       ¦               ¦       ¦--RuleHedge_62c7497e                                                   limit  0.85               NA           
230      ¦       ¦               ¦       ¦   °--*Storie Factor X erosion class = 2                                                         NA           
231      ¦       ¦               ¦       ¦       °--RuleHedge_5c67fdf4                                         null_or     0               NA           
232      ¦       ¦               ¦       ¦           °--*Storie Factor X erosion class = 2                                   13214         NA      13214
233      ¦       ¦               ¦       ¦--RuleHedge_16378273                                                   limit  0.75               NA           
234      ¦       ¦               ¦       ¦   °--*Storie Factor X erosion class = 3                                                         NA           
235      ¦       ¦               ¦       ¦       °--RuleHedge_c65bf0da                                         null_or     0               NA           
236      ¦       ¦               ¦       ¦           °--*Storie Factor X erosion class = 3                                   13217         NA      13217
237      ¦       ¦               ¦       ¦--RuleHedge_68a3b3e6                                                   limit  0.65               NA           
238      ¦       ¦               ¦       ¦   °--*Storie Factor X erosion class = 4                                                         NA           
239      ¦       ¦               ¦       ¦       °--RuleHedge_772054de                                         null_or     0               NA           
240      ¦       ¦               ¦       ¦           °--*Storie Factor X erosion class = 4                                   13216         NA      13216
241      ¦       ¦               ¦       °--*Storie Factor X erosion class = 0                                                             NA           
242      ¦       ¦               ¦           °--RuleHedge_b3c4b963                                             null_or     0               NA           
243      ¦       ¦               ¦               °--*Storie Factor X erosion class = 0                                       13212         NA      13212
244      ¦       ¦               °--RuleHedge_ea4b1839                                                             not     0               NA           
245      ¦       ¦                   °--*Storie Factor A Profile Group 7,8,9 landform                                                      NA           
246      ¦       ¦                       °--RuleHedge_608f03c8                                            not_null_and     0               NA           
247      ¦       ¦                           °--*Storie Factor A Pedon Group 7, 8, 9 landform                                12917         NA      12917
248      ¦       °--*Storie Factor X (wetness in growing season, 25-100cm)                                                                 NA           
249      ¦           °--RuleHedge_7981f6f4                                                                     null_or     0               NA           
250      ¦               °--*Storie Factor X landscape wetness, grow. season, 25-100                                         12954         NA      12954
251      °--*Storie Factor X (temperature regime)                                                                                          NA           
252          °--*Storie Factor X temperature regime                                                                          50482         NA      50482

</pre>


### DHS - Catastrophic Mortality, Large Animal Disposal, Pit 
<pre style="font-size: 70%; font-family: monospace">
                                                                                levelName           Type Value RefId rule_refid eval_refid
1   DHS - Catastrophic Mortality, Large Animal Disposal, Pit                                                                 NA           
2    °--RuleOperator_b6496b7d                                                                         or                     NA           
3        ¦--Permafrost                                                                                                       NA           
4        ¦   °--RuleOperator_dd37796c                                                                 or                     NA           
5        ¦       ¦--RuleHedge_ea3fa12b                                                      not_null_and     0               NA           
6        ¦       ¦   °--Permafrost (Consolidated) InLieuOf                                                       167         NA        167
7        ¦       ¦--RuleHedge_296e9a0c                                                      not_null_and     0               NA           
8        ¦       ¦   °--Texture Modifier (Permanently Frozen)                                                    351         NA        351
9        ¦       °--RuleHedge_f6fc035d                                                      not_null_and     0               NA           
10       ¦           °--Shallow to Permafrost (50 to 100cm (20 to 40"))                                        10356         NA      10356
11       ¦--Ponded > 4 hours, Max                                                                                            NA           
12       ¦   °--RuleOperator_9fea508b                                                                and                     NA           
13       ¦       ¦--RuleHedge_278a7dc1                                                               not     0               NA           
14       ¦       ¦   °--RuleHedge_1a7cc2f2                                                  not_null_and     0               NA           
15       ¦       ¦       °--Ponding Frequency None, Max                                                        16087         NA      16087
16       ¦       °--RuleHedge_a68678bf                                                      not_null_and     0               NA           
17       ¦           °--Ponding Duration > Very Brief, Max                                                     16088         NA      16088
18       ¦--Flooding  Very Rare/Rare Freq.                                                                                   NA           
19       ¦   °--RuleOperator_1ead536d                                                                 or                     NA           
20       ¦       ¦--RuleHedge_4bc678de                                                          multiply   0.4               NA           
21       ¦       ¦   °--RuleHedge_82c14f91                                                  not_null_and     0               NA           
22       ¦       ¦       °--Flooding "RARE"                                                                      198         NA        198
23       ¦       ¦--RuleHedge_5856520a                                                          multiply   0.2               NA           
24       ¦       ¦   °--RuleHedge_d9736f1f                                                  not_null_and     0               NA           
25       ¦       ¦       °--Flooding "VERY RARE"                                                                 200         NA        200
26       ¦       ¦--RuleHedge_fe17083b                                                      not_null_and     0               NA           
27       ¦       ¦   °--Flooding "FREQUENT"                                                                      201         NA        201
28       ¦       ¦--RuleHedge_943e79e7                                                      not_null_and     0               NA           
29       ¦       ¦   °--Flooding "OCCASIONAL"                                                                    199         NA        199
30       ¦       °--RuleHedge_dd896630                                                      not_null_and     0               NA           
31       ¦           °--Flooding "VERY FREQUENT"                                                                 202         NA        202
32       ¦--Slope 5 to > 12%                                                                                                 NA           
33       ¦   °--RuleHedge_c668603b                                                        null_not_rated     0               NA           
34       ¦       °--Slope 5 to 12%                                                                             15619         NA      15619
35       ¦--Ground Water Within 200 cm of the Surface                                                                        NA           
36       ¦   °--RuleOperator_a0c45760                                                                 or                     NA           
37       ¦       ¦--RuleHedge_add57c27                                                      not_null_and     0               NA           
38       ¦       ¦   °--Ground Water Within 200 cm of the Surface                                              16090         NA      16090
39       ¦       °--RuleHedge_f046d2fd                                                      not_null_and     0               NA           
40       ¦           °--Ground Water Perched 60 to 200cm                                                       16091         NA      16091
41       ¦--Shallow to Hard Bedrock < 200cm                                                                                  NA           
42       ¦   °--RuleHedge_8682598e                                                          not_null_and     0               NA           
43       ¦       °--Shallow to Hard Bedrock < 200cm                                                            27583         NA      27583
44       ¦--Seepage Bottom Layer, Not Aridic, LAD                                                                            NA           
45       ¦   °--RuleOperator_f26d715b                                                                and                     NA           
46       ¦       ¦--Not Aridic                                                                                               NA           
47       ¦       ¦   °--RuleHedge_a3172638                                                           not     0               NA           
48       ¦       ¦       °--RuleOperator_34adf09e                                                     or                     NA           
49       ¦       ¦           ¦--RuleHedge_780e4de6                                          not_null_and     0               NA           
50       ¦       ¦           ¦   °--Taxonomic SubGroup - aridic                                                  769         NA        769
51       ¦       ¦           ¦--RuleHedge_f635440b                                          not_null_and     0               NA           
52       ¦       ¦           ¦   °--Taxonomic Great Group - *torr*                                              1028         NA       1028
53       ¦       ¦           °--RuleHedge_1ab0e41a                                          not_null_and     0               NA           
54       ¦       ¦               °--Taxonomic Order - aridisol                                                   776         NA        776
55       ¦       °--RuleHedge_d5715d34                                                      not_null_and     0               NA           
56       ¦           °--Seepage (Bottom layer) disposal                                                        16688         NA      16688
57       ¦--Effective sand 30-200cm, thickest layer                                                                          NA           
58       ¦   °--RuleHedge_af76a7e7                                                          not_null_and     0               NA           
59       ¦       °--RuleHedge_055b13af                                                          multiply  1.00               NA           
60       ¦           °--Sand less clay in depth 30-200cm, thickest layer                                       15625         NA      15625
61       ¦--Humus Between 25 to 180cm (10 to 72")                                                                            NA           
62       ¦   °--RuleHedge_7717c28f                                                          not_null_and     0               NA           
63       ¦       °--Unified Organic pt, oh, ol 25 to 180cm (10-72")                                            10364         NA      10364
64       ¦--Large Stones (Fragments >75mm Wt. Ave. to 60")                                                                   NA           
65       ¦   °--RuleHedge_ea66f739                                                        null_not_rated     0               NA           
66       ¦       °--Fragments >75mm in 0-180cm                                                                  1044         NA       1044
67       ¦--Sodium, Soil Max SAR > 13 and Not Aridic                                                                         NA           
68       ¦   °--RuleOperator_82ec2e2b                                                                and                     NA           
69       ¦       ¦--Not Aridic                                                                                               NA           
70       ¦       ¦   °--RuleHedge_a3172638                                                           not     0               NA           
71       ¦       ¦       °--RuleOperator_34adf09e                                                     or                     NA           
72       ¦       ¦           ¦--RuleHedge_780e4de6                                          not_null_and     0               NA           
73       ¦       ¦           ¦   °--Taxonomic SubGroup - aridic                                                  769         NA        769
74       ¦       ¦           ¦--RuleHedge_f635440b                                          not_null_and     0               NA           
75       ¦       ¦           ¦   °--Taxonomic Great Group - *torr*                                              1028         NA       1028
76       ¦       ¦           °--RuleHedge_1ab0e41a                                          not_null_and     0               NA           
77       ¦       ¦               °--Taxonomic Order - aridisol                                                   776         NA        776
78       ¦       °--RuleHedge_87d13e20                                                      not_null_and     0               NA           
79       ¦           °--Excess Sodium SAR >13                                                                  10365         NA      10365
80       ¦--pH Minimum to a depth of 200cm (acid)                                                                            NA           
81       ¦   °--RuleHedge_72b22f25                                                        null_not_rated     0               NA           
82       ¦       °--pH Minimum to a depth of 180cm (Acid)                                                      10366         NA      10366
83       ¦--Salinity (EC > 16mmhos)                                                                                          NA           
84       ¦   °--RuleHedge_d8796b43                                                          not_null_and     0               NA           
85       ¦       °--Salinity > 16 mmhos/cm                                                                     10367         NA      10367
86       ¦--Cemented Pan < 182cm (72")                                                                                       NA           
87       ¦   °--RuleOperator_9cb8d097                                                                and                     NA           
88       ¦       ¦--RuleOperator_b5afcd4e                                                             or                     NA           
89       ¦       ¦   ¦--RuleHedge_35cecfc5                                                      multiply   0.5               NA           
90       ¦       ¦   ¦   °--RuleHedge_31701dc6                                              not_null_and     0               NA           
91       ¦       ¦   ¦       °--Shallow to Thin Cemented Pan < 182cm (72")                                       377         NA        377
92       ¦       ¦   °--RuleHedge_d96baa47                                                  not_null_and     0               NA           
93       ¦       ¦       °--Shallow to Thick Cemented Pan < 182 cm (72")                                         376         NA        376
94       ¦       °--RuleHedge_7573d199                                                               not     0               NA           
95       ¦           °--RuleHedge_9242d77e                                                  not_null_and     0               NA           
96       ¦               °--Restrictive Feature Hardness Noncemented                                           12852         NA      12852
97       ¦--Large Fragments in Surface Layer                                                                                 NA           
98       ¦   °--RuleHedge_603f5168                                                        null_not_rated     0               NA           
99       ¦       °--Surface Fragments > 250mm (10 inches)                                                        208         NA        208
100      ¦--Rock Outcrop                                                                                                     NA           
101      ¦   °--RuleHedge_fd8e9c06                                                          not_null_and     0               NA           
102      ¦       °--Rock outcrop present                                                                       16875         NA      16875
103      ¦--Adsorption 30-200 cm                                                                                             NA           
104      ¦   °--RuleHedge_19803206                                                          not_null_and     0               NA           
105      ¦       °--RuleHedge_7170cceb                                                          multiply  0.25               NA           
106      ¦           °--Adsorption 30-200 cm                                                                   15383         NA      15383
107      ¦--Bedrock Susceptible to Flow Channel Formation                                                                    NA           
108      ¦   °--RuleOperator_150ba473                                                                 or                     NA           
109      ¦       ¦--RuleHedge_28ec690b                                                    null_not_rated     0               NA           
110      ¦       ¦   °--Parent Material Origin is Soluble Salt                                                 18697         NA      18697
111      ¦       °--RuleHedge_e2edb4a2                                                    null_not_rated     0               NA           
112      ¦           °--BEDROCK IS LIMESTONE                                                                   15623         NA      15623
113      ¦--Water Gathering Surface                                                                                          NA           
114      ¦   °--RuleHedge_807ee918                                                        null_not_rated     0               NA           
115      ¦       °--Water Gathering Surface                                                                    16202         NA      16202
116      ¦--RuleHedge_20108138                                                                  multiply   0.5               NA           
117      ¦   °--Unstable Excavation Walls, Catastrophic Events                                                               NA           
118      ¦       °--RuleHedge_dad60756                                                          multiply     1               NA           
119      ¦           °--RuleOperator_b606a62b                                                         or                     NA           
120      ¦               ¦--RuleHedge_f9803567                                                       add  0.01               NA           
121      ¦               ¦   °--Coarse Material                                                                              NA           
122      ¦               ¦       °--RuleOperator_43ca726c                                             or                     NA           
123      ¦               ¦           ¦--Coarse Material, Fragments                                                           NA           
124      ¦               ¦           ¦   °--RuleHedge_4a45e661                              not_null_and     0               NA           
125      ¦               ¦           ¦       °--FRAGMENT CONTENT IN DEPTH 30 TO 200cm                          15615         NA      15615
126      ¦               ¦           °--Coarse Material, Sand                                                                NA           
127      ¦               ¦               °--RuleHedge_ef2cd957                              not_null_and     0               NA           
128      ¦               ¦                   °--SAND PERCENT LESS CLAY IN DEPTH 30-200cm                       15613         NA      15613
129      ¦               ¦--RuleHedge_80e7c85c                                                       add  0.01               NA           
130      ¦               ¦   °--Silt and loess                                                                               NA           
131      ¦               ¦       °--RuleOperator_39999d4e                                        product                     NA           
132      ¦               ¦           ¦--RuleHedge_f25390da                                  not_null_and     0               NA           
133      ¦               ¦           ¦   °--SILT CONTENT 30-200cm                                              15610         NA      15610
134      ¦               ¦           °--RuleHedge_903c2278                                  not_null_and     0               NA           
135      ¦               ¦               °--PARENT MATERIAL ORIGIN IS LOESS                                    15611         NA      15611
136      ¦               ¦--RuleHedge_6776e77b                                                       add  0.01               NA           
137      ¦               ¦   °--LEP 30-200cm Above a Restriction                                                             NA           
138      ¦               ¦       °--RuleHedge_87ef6954                                          multiply     1               NA           
139      ¦               ¦           °--RuleHedge_26abe6c5                                  not_null_and     0               NA           
140      ¦               ¦               °--LEP 30-200cm OR ABOVE RESTRICTIVE LAYER                            15609         NA      15609
141      ¦               °--RuleHedge_19371ebd                                                       add  0.01               NA           
142      ¦                   °--Coarse Material, Gypsum                                                                      NA           
143      ¦                       °--RuleOperator_c9dae6a4                                            and                     NA           
144      ¦                           ¦--RuleHedge_3380582c                                  not_null_and     0               NA           
145      ¦                           ¦   °--Depth to Restrictive Layer 50 to 150cm                             18479         NA      18479
146      ¦                           °--RuleHedge_b2430953                                  not_null_and     0               NA           
147      ¦                               °--Gypsum WTD_AVG from 10cm to Restriction                            18478         NA      18478
148      ¦--RuleHedge_03cebf03                                                                  multiply   0.5               NA           
149      ¦   °--Clayey 30-200cm, Moisture Modified, Catastrophic Events                                                      NA           
150      ¦       °--RuleHedge_64894d0a                                                          multiply   0.5               NA           
151      ¦           °--RuleOperator_c5a22b88                                                    product                     NA           
152      ¦               ¦--Taxonomic Moisture Rating                                                                        NA           
153      ¦               ¦   °--RuleHedge_8d689f49                                        null_not_rated     0               NA           
154      ¦               ¦       °--Taxonomic Soil Moisture Class Rating                                       16769         NA      16769
155      ¦               °--RuleOperator_ac419cb6                                                product                     NA           
156      ¦                   ¦--RuleHedge_d6511ba7                                                   not     0               NA           
157      ¦                   ¦   °--RuleHedge_9c4de3ed                                          multiply  0.85               NA           
158      ¦                   ¦       °--RuleHedge_6a24ec97                                  not_null_and     0               NA           
159      ¦                   ¦           °--CLAY CONTENT 30-200CM WTD AVE                                      15616         NA      15616
160      ¦                   °--RuleHedge_9f7cdbac                                          not_null_and     0               NA           
161      ¦                       °--Taxonomic Mineralogy Exclusion - Kaolinitic (nssc)                           778         NA        778
162      °--Dust PM10 and PM2.5 Generation                                                                                   NA           
163          °--RuleHedge_de473ab5                                                              multiply   0.5               NA           
164              °--RuleOperator_0a397761                                                        product                     NA           
165                  ¦--Dryness Index 0.5 to 3                                                                 18448         NA      18448
166                  °--RuleOperator_7025ab26                                                        sum                     NA           
167                      ¦--Dust Due to Gypsum                                                                               NA           
168                      ¦   °--RuleHedge_5c18cb73                                          not_null_and     0               NA           
169                      ¦       °--Dust from Gypsum Content 2 to 15 Percent                                   18446         NA      18446
170                      °--Dust Due to Silt and Clay                                                                        NA           
171                          °--RuleHedge_caf7e2e0                                        null_not_rated     0               NA           
172                              °--Dust from Silt and Clay Content 20 to 70 Percent Sand                      18447         NA      18447

</pre>