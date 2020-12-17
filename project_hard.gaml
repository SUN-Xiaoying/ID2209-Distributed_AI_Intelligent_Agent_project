 /**
* Name: FestivalHard
* Based on the internal empty template. 
* Author: yuehao
* Tags: 
*/


model FestivalHard

/* Insert your model definition here */

global {
	int nb_stages <- 5;
    int nb_guests <- 20;
    
    bar the_bar;
    exit_gate the_exit;
    
    float step <- 10#mn;
    geometry shape <- square(20 #km);
    
    string stage_at_location <- "mine_at_location";
    string dislike_stage <- "dislike_stage";
    string watched_stage <- "watched_stage";
    string crowded_stage <- "crowded_stage";
    
    predicate stage_location <- new_predicate(stage_at_location) ;
    
    predicate check_show <- new_predicate("check a stage");
    
    predicate watch_show <- new_predicate("watch_show") ;
    
    predicate cool_down <- new_predicate("cool_down");
    predicate want_music <- new_predicate("want_music") ;
    predicate choose_stage <- new_predicate("choose_stage") ;
    
    predicate share_lager <- new_predicate("share lager") ;
    
//    predicate no_money <- new_predicate("no_money") ;
    predicate want_exit <- new_predicate("want_exit") ;
    
    emotion hate <- new_emotion("hate");
    emotion generous <- new_emotion("generous");
    
	init {
		create bar {
			the_bar <- self;
		}
		create exit_gate {
			the_exit <- self;
		}
		create stage number: nb_stages;
		create guest number: nb_guests;
	}
	
	reflex end_simulation when: sum(guest collect each.consumption) <= 0 {
        do pause;
        ask guest {
        	write name + " : " + length(friends);
    	}
    }
    reflex display_social_links{
        loop tempGuest over: guest{
            loop tempDestination over: tempGuest.social_link_base{
                if (tempDestination !=nil){
                    bool exists<-false;
                    loop tempLink over: socialLinkRepresentation{
                        if((tempLink.origin=tempGuest) and (tempLink.destination=tempDestination.agent)){
                            exists<-true;
                        }
                    }
                    if(not exists){
                        create socialLinkRepresentation number: 1{
                            origin <- tempGuest;
                            destination <- tempDestination.agent;
                            if(get_liking(tempDestination)=0){
                                my_color <- #green;
                            } else {
                                my_color <- #red;
                            }
                        }
                    }
                }
            }
        }
    } 
}

species guest skills:[moving] control:simple_bdi {
	 
	float view_dist <- 1000.0;
    float speed <- 2#km/#h;
    rgb my_color <- rnd_color(255);
    point target;
    stage current_stage; 
    int consumption <- 100;
    int fav <- int(rnd(1,nb_guests/2));
    
    int enter_cycle;
    
    bool use_emotions_architecture <- true;
    bool use_personality <- true;
    
    list<string> friends <- [];
    
    init {
    	do add_desire(want_music);
    }
	 
	aspect default {
        draw circle(200) color: my_color border: #black depth: consumption;
    }
    
    reflex no_money when: consumption <= 0 {
    	consumption <- 0; 
    	do add_desire(want_exit);
    }
    
    reflex hate_time when: ((cycle mod 10) = 6){
    		do add_emotion(hate);
    } 
    reflex happy_time when: ((cycle mod 10) != 6){
    		do remove_emotion(hate);
    }
    
    reflex i_am_rich when: consumption > 80{
    		do add_emotion(generous);
    } 
    reflex i_am_poor when: consumption < 80{
    		do remove_emotion(generous);
    }
    
    perceive target: stage in: view_dist {
	    focus id: stage_at_location var:location;
	    ask myself {
	        do remove_intention(want_music, false);
	    }
    }
    
    perceive target: guest in: 1 {
    	socialize liking: abs(myself.fav - fav);
    	if ((myself.fav = fav) and !(myself.friends contains name)) {
    		add name to: myself.friends;
    		write myself.name + " and " + name + " are friends now";
    	}
    }
    
    rule belief: stage_location new_desire: check_show strength: 2.0;
    rule belief: check_show new_desire: watch_show strength: 4.0;
    rule belief: watch_show new_desire: cool_down strength: 3.0;
    
    plan lets_wander intention: want_music {
    	do wander;
    }
    
    plan checking intention:check_show {
	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_stage, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: target;
	        if (target = location)  {
	        	current_stage <- stage first_with (target = each.location);
		        
		        if(!has_emotion(hate)){
			        if (current_stage.peoples < fav) {
			        	write self.name + " feel " + current_stage.name + " is a good show";
			            do add_belief(check_show);
			            ask current_stage {
			            	peoples <- peoples + 1;
			            }
			            do add_belief(new_predicate(watched_stage, ["location_value"::target]));
			            enter_cycle <- cycle;
			        } else {
			        	write self.name + " like " + current_stage.name + " but he feel too crowded";
			        	do add_belief(new_predicate(crowded_stage, ["location_value"::target]));
			        }
		        } else {
		        	write self.name + " dislike " + current_stage.name;
		            do add_belief(new_predicate(dislike_stage, ["location_value"::target]));
		        }
		        target <- nil;
	        }
	    }   
    }
    
    plan choose_closest_stage intention: choose_stage instantaneous: true {
	    list<point> possible_stages <- get_beliefs_with_name(stage_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    list<point> dislike_stages <- get_beliefs_with_name(dislike_stage) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    list<point> watched_stages <- get_beliefs_with_name(watched_stage) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    list<point> crowded_stages <- get_beliefs_with_name(crowded_stage) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    
	    loop cs over: crowded_stages {
	    	do remove_belief(new_predicate(crowded_stage, ["location_value"::cs]));
	    }
	    
	    possible_stages <- possible_stages - dislike_stages - watched_stages - crowded_stage;
	    if (empty(possible_stages)) {
	        do remove_intention(check_show, true); 
	    } else {
	        target <- (possible_stages with_min_of (each distance_to self)).location;
	    }
	    do remove_intention(choose_stage, true); 
    }
    
    plan watching intention: watch_show {
    	target <- nil;
    	
    	if(cycle > enter_cycle + 200){
    		do remove_belief(check_show);
    		do remove_intention(watch_show, true); 
    		
    		if (current_stage != nil) {
		     	ask current_stage {
		        	peoples <- peoples - 1;
		        }
		        current_stage <- nil;		      
		    }
        } else {
        	do remove_intention(check_show);
        	do add_belief(watch_show);
        }
    }
    
    plan return_to_free intention: cool_down {
	    do goto target: the_bar ;
	    if (the_bar.location = location)  {
	        do remove_belief(watch_show);
	        do remove_intention(cool_down, true);
	        consumption <- consumption - rnd(30,50);
	        
	        if (has_emotion(generous)) { 
                write self.name + " want to share a lager with his new friend!";
                do add_desire(predicate:share_lager, strength: 5.0);
            }
	        
	        do add_desire(want_music);
	    }
    }
    plan drink_with_friend intention:share_lager {
     	
     	list<guest> my_friends <- list<guest>((social_link_base where (each.liking = 0)) collect each.agent);
     	if (!empty(my_friends)){
     		target <- (my_friends with_min_of (each distance_to self)).location;
     	}
     	do remove_intention(share_lager, true);
    }
    plan want_exit intention:want_exit {
    	target <- {0,0,0};
    	do goto target: {0,0,0};
    }
}

species bar {
	int price <- rnd(30,50);
	aspect default {
        draw triangle(800 + 20 * price) color: #black;
    }
}

species stage {
	int peoples;
	aspect default {
        draw square(800) color: #yellow border: #black;
    }
    init {
    	peoples <- 0;
    }
}

species exit_gate {
	aspect default {
        draw square(1000) color: #red at: {0,0,0};
    }
}


species socialLinkRepresentation{
    guest origin;
    agent destination;
    rgb my_color;
    
    aspect base{
        draw line([origin,destination],50.0) color: my_color;
    }
}


experiment Run type: gui {
    output {
        display map type: opengl {
	        species bar;
	        species stage;
	        species guest;
	        species exit_gate;
	    }
	    
	    display socialLinks type: opengl{
	        species socialLinkRepresentation aspect: base;
	        species guest ;
	    }
	    
	    display stage_chart {
        	chart "People" type: series {
        		datalist legend: stage accumulate each.name value: stage accumulate each.peoples;
        	}
        }
        
        display consumption {
        	chart "Consumption" type: series {
        		datalist legend: guest accumulate each.name value: guest accumulate each.consumption color: guest accumulate each.my_color;
        	}
        }
        
        display friend {
        	chart "Friend" type: series {
        		datalist legend: guest accumulate each.name value: guest accumulate length(each.friends) color: guest accumulate each.my_color;
        	}
        }
    }
}
