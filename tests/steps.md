Ξ forgit/tests git:(master) ▶ chmod +x select_all_commit_sha.sh                    
Ξ forgit/tests git:(master) ▶ vi select_all_commit_sha.sh 
Ξ forgit/tests git:(master) ▶ cat multiselect-commits.txt |grep -Eo '[a-f0-9]{7,7}' > all_sha_list
Ξ forgit/tests git:(master) ▶ cat all_sha_list                                                    
60e1a25
713236f
93826bd
Ξ forgit/tests git:(master) ▶ cat all_sha_list |head
60e1a25
713236f
93826bd
Ξ forgit/tests git:(master) ▶ cat all_sha_list |head -1
60e1a25
Ξ forgit/tests git:(master) ▶ cat all_sha_list |tail -1
93826bd
Ξ forgit/tests git:(master) ▶ a=$(cat multiselect-commits.txt |grep -Eo '[a-f0-9]{7,7}')          
Ξ forgit/tests git:(master) ▶ echo $a           
60e1a25
713236f
93826bd
Ξ forgit/tests git:(master) ▶ echo $a|head -1                                           
60e1a25
Ξ forgit/tests git:(master) ▶ start="$(echo $a|head -1) $(echo $a|tail -1)"                
Ξ forgit/tests git:(master) ▶ start_and_end_commits_sha="$(echo $a|head -1) $(echo $a|tail -1)" 
Ξ forgit/tests git:(master) ▶ echo $start_and_end_commits_sha                                        
60e1a25 93826bd
