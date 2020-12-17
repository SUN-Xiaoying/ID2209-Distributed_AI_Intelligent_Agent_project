/**
* Name: ID2209 - Project
* Based on the internal empty template. 
* Author: Xiaoying Sun, Yuehao Sui
* Tags: 
*/

model project

global 
{
	// A1 - Guest
	float max_energy <- 100.0;
	float energy_consum <- 0.05;
	int guest_number <- rnd(10)+20;
	float guest_speed <- 0.5;

	int approximateDetectionDistance <- 3;
	
	//A1 - Security + Prison + InfoCenter
	point info_location <- {50,50};
	float security_speed<- guest_speed * 1.5;
	point prison_location <- {5, 5};
    
    // A2 - Auctioner
	point master_location <- {-10,50};
	list<string> itemsAvailable <- ["bags","shirts","hats", "pants"];
	list<string> auctionTypes <- ["Dutch", "English", "Sealed"];
	int auctionerWaitTime <- 10;

	int showMasterIntervalMin <- 100;
	int showMasterIntervalMax <- 300;
	
	// Time when auctioneers are created
	int auctionCreationMin <- 150;
	int auctionCreationMax <- 200;
	
	// Guest accepted price range min and max
	int guest_accept_min <- 100;
	int guest_accept_max <- 1500;
	
	// A2 - Auction - English
	int eng_raise_min <- 30;
	int eng_raise_max <- 60;
	int eng_init_min <- 0;
	int eng_init_max <-1500;
	
	// A2 - Auction - Dutch
	int dutch_dec_min <- 5;
	int dutch_dec_max <- 15;
	int dutch_init_min <- 1504;
	int dutch_init_max <-1600;
	
	// A2 - Minimum price of the item, if the bids go below this the auction fails
	int auctionerMinimumValueMin <- 90;
	int auctionerMinimumValueMax <- 300;
	
	// A3 - Stage
	int stage_number<- 4;
	int stage_score_min <- 1;
	int stage_score_max <- 100;
	int durationMin <- 300;
	int durationMax <- 500;
	list<string> style_available<- ["sensational synthwave"
									,"trashy techno"
									,"dope darkwave"
									,"80's mega hits"
									,"traditional Russian song techno remixes"
									,"Sandstorm"
									,"incredible Italo Disco"
									,"impressive industrial"
									,"generic German New Wave"
									,"pompous punk rock"
									,"old people rock"
									,"extreme experimental"
									,"rubber chicken Despacito"
									,"ingenious indigenous instrumental"
									,"pungmul"
									,"pansori"
									,"geomungo sanjo"
									];
	list<rgb> stageColors <- [#lime, #pink, #lightblue, #yellow];
	
	
	//the global rate at which happiness will be decreased
    float happiness_consume <- 0.04;
	float globalHappiness <- max_energy * guest_number;
	
	float globalUtility <- 0.0;
	float globalEnergy <- 0.0;

	// Project - Bar
	int bar_number <- rnd(3, 4);
	
    // Project - personality
    list<string> personalityEnum <- ["Party", "Chill", "Leftist", "Rightist"];
    

    
	// Project - Everything happens only once per day
	int currDay <- 0;
	int cyclesPerDay <- 2400;
	
	//LongStayPlace configs
	float longStayPlaceRadius <- 4.0;
	float floatError <- 0.0001;
	int place_lifecycle_max <- 200;
	int place_lifecycle_min <- 100;
	
	//under this value, the guests will be disturbed by their nemesis
	float feelingFineValue <- 40.0;
	
	
	init
	{
		create ShowMaster number: 1
		{
			location <- master_location;
		}
		
		create Guest number: guest_number;
		
		create Bar number: bar_number;

		create InfoCenter number: 1
		{
			location <- info_location;
		}
			
		create Security number: 1;
		create Prison number: 1
		{
			location <- prison_location;
		}
	}
	
	reflex currDay when: time != 0 and mod(time, cyclesPerDay) = 0
	{
		currDay <- currDay + 1;
		write "===== Day " + currDay  + " ends  =====";
	}
}


species Guest skills:[moving, fipa]
{
	bool isFull <- true;

	float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy min: 0.0;
	float happiness <- max_energy update: happiness - happiness_consume max: max_energy min: 0.0;
	
	list<Building> guestBrain;
	Building target <- nil;
	pair<float, float> targetOffset <- 0.0 :: 0.0;
	
	//Project - LongStayPlaceConfigs
	int cyclesLeftToStay <- 0;
	 
	// A1 - Security
	bool isCaught <- false;
	bool isBad <- flip(0.2);
	
	// A2 - Auctioner
	Auctioner targetAuction;
	string preferredItem <- [];
	int guestMaxAcceptedPrice <- rnd(guest_accept_min, guest_accept_max);
	
	// A2 - Auctioner Loop
	list<string> wishList <- ["bags","shirts","hats", "pants"];
	
	// A3 - Stage 
	float guest_prefer_light <- rnd(stage_score_min,stage_score_max) * 0.01;
	float guest_prefer_band <- rnd(stage_score_min,stage_score_max) * 0.01;
	float guest_prefer_show <- rnd(stage_score_min,stage_score_max) * 0.01;
	float guest_prefer_speaker <- rnd(stage_score_min,stage_score_max) * 0.01;
	
	// A3 - Preference Bias
	string guest_prefer_style <- style_available[rnd(length(style_available) - 1)];
	float guest_prefer_styleBias <- 1.0 + rnd(0.0,10.0);
	int guest_prefer_size <- rnd(1,guest_number);
	float guest_prefer_sizeBias <- rnd(0.0,1.0);
	
	map stageUtilityPairs; 
	
	//A3 - Global Utility
	ShowMaster showMaster <- one_of(ShowMaster);
		
	Stage targetStage <- nil;
	float highestUtility <- 0.0;
	float currentUtility <- 0.0;
	int highestUtilityIndex;
	bool unsatisfied <- false;
	
	//Project - Interaction configs
	string personality <- personalityEnum[rnd(length(personalityEnum) - 1)];
	bool isDisturbed <- false;
	float beGenerous <- rnd(0.0, 1.0);
	
	aspect base
	{
		if(isBad) {
			color <- #black;
		}
		else if(isDisturbed){
			color <- #red;
		}
		else if(personality = "Party"){
			color <- rgb(252, 210, 23);
		}
		else if(personality = "Chill"){
			color <- rgb(22, 119, 179);
		}
		else if(personality = "Leftist"){
			color <- rgb(238, 72, 102);
		}
		else if(personality = "Rightist"){
			color <- rgb(43, 174, 133);
		}
		draw circle(2) at: location color: color;
		
		
		if(!contains(wishList, "bags"))
		{
			draw cube(1) at: location + point([0.0, 2.0]) color: #purple;
		}
		if(!contains(wishList, "hats"))
		{
			draw sphere(1) at: location + point([0.0, 1.0]) color: #orange;
		}
		if(!contains(wishList, "shirts"))
		{
			draw sphere(1) at: location + point([0.0, 0.0]) color: #lime;
		}
		if(!contains(wishList, "pants"))
		{
			draw sphere(1) at: location color: #pink;
		}
	}
	
	init
	{	
		if(length(itemsAvailable) > 0)
		{
			preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];	
		}
	}
	
		
	// 1.0  Prison
	reflex goPrison when: isCaught = true {
		happiness <- 0.0;
		target <- one_of(Prison);
	}
	
	// 1.1 Everything about life is eating
	reflex alwaysHungry
	{
		if(target = nil and (energy < feelingFineValue) and isFull)
		{
			isFull <- false;
			bool useBrain <- flip(0.5);
			
			if(length(guestBrain) > 0 and useBrain = true)
			{
				target <- one_of(guestBrain);
			}

			if(target = nil)
			{
				target <- one_of(InfoCenter);	
			}
		}
	}

	// 1.2  No target
	reflex wanderRandomly when: target = nil and isFull
	{
		do wander;
	}
	
	// 1.3  What? I have a target?
	reflex isTargetAlive when: target != nil
	{
		if(dead(target))
		{
			target <- nil;
			targetStage <- nil;
		}
	}

	// 1.4  Go for my target.
	reflex moveToTarget when: target != nil
	{
		do goto target:{target.location.x + targetOffset.key, target.location.y + targetOffset.value} speed: guest_speed;
	}
	
	// 1.5.1 Target is LongStayPlace || InfoCenter
	reflex reachedTargetExactly when: target != nil and location distance_to(target.location) = 0
	{
		if(species(target) = Bar or species(target) = Conference )
		{
			do longStayPlaceReached;
		}
		if(target = one_of(InfoCenter))
		{
			do infoCenterReached;
		}
	}
	
	// 1.5.2 LongStayPlace is Bar || Conference
	reflex atLongStayPlace when: species(target) = Bar or species(target) = Conference 
	and self distance_to target <= longStayPlaceRadius + floatError 
	{
		if(species(target) = Bar)
		{
			do beingAtBar;
		}
		else if(species(target) = Conference)
		{
			do beingAtConference;
		}
		
		cyclesLeftToStay <- cyclesLeftToStay - 1;
		if(cyclesLeftToStay = 0)
		{
			do leaveLongStayPlace;
		}
	}
	
	// 3.1  Target is Stage
	reflex gotoStageOrBeIdle when: target = nil and isFull
	{
		if(targetStage != nil and dead(targetStage))
		{
			targetStage <- nil;
		}
		if(targetStage != nil and location distance_to(targetStage) > approximateDetectionDistance)
		{
			target <- targetStage;
		}
	}
	
	// 3.2  reached to Stage
	reflex checkForTargetReachedApproximately when: target != nil and location distance_to(target.location) <= approximateDetectionDistance
	{
		if(Stage = species(target))
		{
			do stageReached;
		}
	}
	
	// 3.3 Choose my favorite Stage
	reflex calculateUtilities
	{
		if (!empty(Stage.population))
		{
			loop stg over: Stage.population
			{
				float utility <- stg.stageLights * guest_prefer_light +
								stg.stageBand * guest_prefer_band +
								stg.stageShow * guest_prefer_show +
								stg.stageSpeaker * guest_prefer_speaker;
					
				if(stg.stageStyle = guest_prefer_style)
				{
					utility <- utility * guest_prefer_styleBias;
				}
	
				if(length(stg.crowdedGuest) > guest_prefer_size)
				{
					utility <- utility * guest_prefer_sizeBias;
				}

				// Save the stage::utility pair
				stageUtilityPairs <+ stg::utility;	
			}
		}
		else if(!empty(stageUtilityPairs))
		{
			stageUtilityPairs <- [];
			targetStage <- nil;
		}
		
		// If targetStage is dead, we'll set that to nil
		if(dead(targetStage))
		{
			targetStage <- nil;
		}
		
		// The higher the better
		highestUtility <- 0.0; 
		loop stgUt over: stageUtilityPairs.pairs
		{
			if(float(stgUt.value) > highestUtility)
			{
				if(!dead(Stage(stgUt.key)))
				{
					highestUtility <- float(stgUt.value);
					if(targetStage != nil)
					{
						targetStage.crowdedGuest >- self;	
					}
					targetStage <- stgUt.key;
					targetStage.crowdedGuest <+ self;	
				}
				else
				{
					stageUtilityPairs >- stgUt.key;
				}
			}
		}
	}

	// 2. Auction
	reflex listenCFPSMessages when: (!empty(cfps))
	{
		message requestFromInitiator <- (cfps at 0);
		if(Auctioner.population contains requestFromInitiator.sender)
		{
			do processAuctionCFPSMessage(requestFromInitiator);
		}
	}
	
	reflex  listenInformMessages when: (!empty(informs))
	{
		message requestFromInitiator <- (informs at 0);
		if(Conference.population contains requestFromInitiator.sender)
		{
			do processConferenceInformMessage(requestFromInitiator);
		}
	}
	
	reflex replyMessages when: (!empty(proposes))
	{
		message requestFromInitiator <- (proposes at 0);
		if(Auctioner.population contains requestFromInitiator.sender)
		{
			do processAuctionProposeMessage(requestFromInitiator);
		}
		else if(Conference.population contains requestFromInitiator.sender)
		{
			do processConferenceProposeMessage(requestFromInitiator);
		}
		
	}

	/* ======= Action - Guest ======= */
	
	action longStayPlaceReached
	{
		float angle <- rnd(360.0) * #pi * 2.0;
		float x <- cos(angle) * longStayPlaceRadius;
		float y <- sin(angle) * longStayPlaceRadius;
		targetOffset <- x :: y;
		cyclesLeftToStay <- rnd(place_lifecycle_min, place_lifecycle_max);
		
		if(Bar = species(target))
		{
			do barReached;
		}else if(Conference = species(target))
		{
			do conferenceReached;
		}
	}
	
	action barReached
	{
		isFull <- true;
		energy <- max_energy;
		happiness <- happiness + 10;
		string nemesisOf <- personality;
		LongStayPlace place <-LongStayPlace(target);
		if(personality = "Chill" and length(self.getNemesisesAtLongStayPlace(nemesisOf, place)) > 0)
		{
			if(!isDisturbed)
 			{
 				if(happiness < feelingFineValue)
 				{
					write 'Chill, ' + name + ': Disturbed, I hate PARTY people! (at: ' + target + ')';
					happiness <- happiness - 20;
				}
				else
				{
					write "Chill, " + name + ": Disturbed, but too lazy to move. (at: " + target + ")";
					happiness <- happiness - 10;
				}
				isDisturbed <- true;
			}
		}
		else if(personality = "Party" and length(self.getNemesisesAtLongStayPlace(nemesisOf, place)) > 0)
		{
			if(happiness > feelingFineValue and beGenerous > 0.4){
				write "Party, " + name + ": Give the Chill a free drink. (at: " + target + ")";
				happiness <- happiness + 10;
			}
		}
		else
		{
			if(isDisturbed)
 			{
				write personality + ' , ' + name + ': Nice, no other personality here! (at: ' + target + ")" ;
				isDisturbed <- false;
				happiness <- happiness + 5;
			}
		}
	}

	action conferenceReached
	{
		 string nemesisOf <- personality;
		 LongStayPlace place <-LongStayPlace(target);
		 if(length(self.getNemesisesAtLongStayPlace(nemesisOf, place)) > 0)
		 {
		 	if(!isDisturbed)
			{
			 	if(personality = "Leftist")
				{
					if(energy < feelingFineValue or happiness < feelingFineValue)
					{
						write "Leftist, " + name + ": Disturbed, Rightists are dumb! (at: " + target + ")";
						happiness <- happiness -20;
					}
					else
					{
						write "Leftist, " + name + ": Disturbed, but  in a good mood. (at: " + target + ")";
						happiness <- happiness -10;
					}
				}
				if(personality = "Rightist")
				{
					if(energy< feelingFineValue or happiness < feelingFineValue)
					{
						write "Rightist, " + name + ": Disturbed, Leftist are crazy! (at: " + target + ")";
						happiness <- happiness - 20;
					}
					else
					{
						write "Rightist,  " + name + ": Disturbed, but  in a good mood.  (at: " + target + ")";
						happiness <- happiness - 10;
					}
				}
				isDisturbed <- true;
		 	}
			else
			{
				if(isDisturbed)
				{
					if(personality = "Leftist")
					{
						write "Leftist, " +name+  ": Finally, let's start a revolution!";
						happiness <- happiness + 10;
					}
					if(personality = "Rightist")
					{
						write "Rightist"+name + ": Finally, people know respect the tradition!";
						happiness <- happiness + 10;
					}
					isDisturbed <- false;
				}
			}
		}
	}


	action infoCenterReached
	{
		target <- nil;
		ask InfoCenter at_distance 0
		{
			myself.target <- one_of(Bar);
			if(!(myself.guestBrain contains myself.target))
			{
				myself.guestBrain <+ myself.target;
			}
		}
	}

	action leaveLongStayPlace
	{
		targetOffset <- 0.0 :: 0.0;
		target <- nil;
		cyclesLeftToStay <- -1;	
		
		isDisturbed <- false;
	}	
	
	action pickNewPreferredItem
	{
		if(!empty(wishList) and !contains(wishList, preferredItem))
		{
			preferredItem <- wishList[rnd(length(wishList) - 1)];
		}
	}

	action beingAtBar
	{
	}

	action beingAtConference
	{

	}

	 list<Guest> getNemesisesAtLongStayPlace(string nemesisOf, LongStayPlace place)
	 {
	 	string nemesis <- "";
		if(personality = "Chill")
		{
			nemesis <- "Party";
		}
		else if(personality = "Party")
		{
			nemesis <- "Chill";
		}
		else if(personality = "Leftist")
		{
			nemesis <- "Rightist";
		}
		else if(personality = "Rightist")
		{
			nemesis <- "Leftist";
		}

		list<Guest> nemesises <- Guest.population where (each.personality = nemesis and each.target = place and each distance_to target <= longStayPlaceRadius + floatError);
		return nemesises;
		
	 }

	action processAuctionCFPSMessage(message requestFromInitiator)
	{
		// the request's format is as follows: [String, auctionType, soldItem, ...]
		list<unknown> ls <- requestFromInitiator.contents;
		if(ls[0] = 'Start' and ls[1] = preferredItem and !isBad)
		{
			targetAuction <- requestFromInitiator.sender;

			// Send a message to the auctioner telling them the guest will participate
			write name + " joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
			targetAuction.interestedGuests <+ self;
			do joinAuction;
		}
		else if(ls[0] = 'Stop')
		{
			do postAuctionSettings;
		}
		else if(ls[0] = 'Bid For Sealed')
		{
			do start_conversation (to: requestFromInitiator.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', guestMaxAcceptedPrice]);
			do postAuctionSettings;
		}
		else if(ls[0] = 'Bid for English')
		{
			int currentBid <- int(ls[1]);
			//can bid more
			if (guestMaxAcceptedPrice > currentBid) 
			{
				int newBid <- currentBid + rnd(eng_raise_min, eng_raise_max);
				if(newBid > guestMaxAcceptedPrice)
				{
					newBid <- guestMaxAcceptedPrice;
				}
				do start_conversation (to: requestFromInitiator.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', newBid]);
			}
			//can't bid more
			else
			{
				do reject_proposal (message: requestFromInitiator, contents: ["Too much, sorry"]);
				do postAuctionSettings;
			}
		}
		else if(ls[0] = 'Winner')
		{
			happiness <- happiness + 10;
			
			write name + ' won the auction for ' + preferredItem;
			wishList >- preferredItem;
			do pickNewPreferredItem;
		}
	}
	
	action joinAuction
	{
		energy <- max_energy;
		isFull <- true;
		color <- #grey;
		
		happiness <- happiness+1;
		
		if(location distance_to(targetAuction.location) > 9)
		{
			target <- targetAuction;
		}
		else
		{
			target <- nil;
		}
	
	}
	
	action processAuctionProposeMessage(message requestFromInitiator)
	{
		list<unknown> ls <- requestFromInitiator.contents;
		string auctionType <-ls[1];
		if(auctionType = "Dutch")
		{
			int offer <- int(ls[2]);
			if (guestMaxAcceptedPrice >= offer) {
				do accept_proposal with: (message: requestFromInitiator, contents: ["I, " + name + ", accept your offer of " + offer + ", merchant."]);
			}
			else
			{
				do reject_proposal (message: requestFromInitiator, contents: ["I, " + name + ", already have a house full of crap, you scoundrel!"]);	
				do postAuctionSettings;
			}
		}
	}

	action postAuctionSettings
	{
		target <- nil;
		targetAuction <- nil;
	}
	
	action stageReached
	{
		happiness <- happiness + 3;
		target <- nil;
	}
	
	action processConferenceProposeMessage(message requestFromInitiator)
	{
		list<unknown> ls <- requestFromInitiator.contents;
		if(ls[0] = 'interested?')
		{
			if(target = nil)
			{
				do accept_proposal(message: requestFromInitiator, contents: ["I'd love a great little chitchat"]);	
			}
			else
			{
				do reject_proposal(message: requestFromInitiator, contents: ['lel dude, im here to drink']);
			}
		}
	}
	
	action processConferenceInformMessage(message requestFromInitiator)
	{
		list<unknown> ls <- requestFromInitiator.contents;
		if(ls[0] = 'conference start')
		{
			
		}
		else if(ls[0] = "you're in!")
		{
			target <- requestFromInitiator.sender;
		}
		
	}
	//Guest actions end
	
}// Guest end


species Building
{
	
}

species InfoCenter parent: Building
{
	
	// We only want to querry locations once
	bool hasLocations <- false;
	
	aspect base
	{
		draw square(4) at: location color: rgb(82,82,136);
	}

	reflex checkForBadGuest
	{
		ask Guest at_distance 0
		{
			if(self.isBad)
			{
				Guest badGuest <- self;
				ask Security
				{
					if(!(self.targets contains badGuest))
					{
						self.targets <+ badGuest;	
					}
				}
			}
		}
	}
}// InfoCenter end

species LongStayPlace parent: Building
{
	
}

species Bar parent: LongStayPlace
{
	aspect base
	{
		draw square(4) at: location color: #purple;
	}
}

species ShowMaster
{
	rgb myColor <- #gray;
	int mySize <- 10;
	list<Auctioner> auctioners <- [];
	bool auctionersInPosition <- false;
	
	
	list<Stage> stages <- [];
	
	//the last time when attractions happened
	int lastDayForAction <- -1;
	
	//the upcoming attraction is true
	bool auctionsNext <- true;
	bool stagesNext <- false;
	bool conferenceNext <- false;
	
	//is created variables
	bool auctionsCreated <- false;
	bool stagesCreated <- false;
	bool conferenceCreated <- false;
	
	//is running variables
	bool auctionsRunning <- false;
	bool stagesRunning <- false;
	bool conferenceRunning <- false;
	
	int nextActivityStartTime <- rnd(auctionCreationMin, auctionCreationMax);
	 
	aspect base
	{
		draw circle(mySize) color: myColor;
	}

	reflex startNewDay when: lastDayForAction < currDay
	{
		auctionsNext <- true;
		stagesNext <- false;
		lastDayForAction <- lastDayForAction + 1;
		nextActivityStartTime <- int(time + rnd(auctionCreationMin, auctionCreationMax));
		
	}
	
	reflex createActivity when: nextActivityStartTime = time
	{
		if(auctionsNext)
		{
			do createAuctions;
		}
		else if(stagesNext)
		{
			do createStages;
		}
		else if(conferenceNext)
		{
			do createConferences;
		}
	}

	reflex startAuctions when: auctionsCreated and !auctionsRunning
	{
		bool stillOnTheWay <- false;
		loop auc over: auctioners
		{
			if(auc.targetLocation != nil)
			{
				stillOnTheWay <- true;
			}
		}
		if(!stillOnTheWay)
		{
			auctionersInPosition <- true;
			write "====== Auctions start  ======";
			auctionsRunning <- true;	
		}
	}
	
	reflex areThereAnyAuctionersLeft when: empty(auctioners) and auctionsRunning
	{
		auctionsCreated <- false;
		auctionsRunning <- false;
		stagesNext <- true;
		do activityEnded;
		write" ====== Auctioners ended ======";
	}
	
	reflex areThereAnystagesLeft when: empty(stages) and stagesRunning
	{
		stagesCreated <- false;
		stagesRunning <- false;
		conferenceNext <- true;
		do activityEnded;
		write "====== Stages ended ======";
		
		// reset unsatisfied for all guests
		ask Guest
		{
			unsatisfied <- false;
		}
	}

	reflex calculateGlobalUtility when: !empty(stages)
	{
	 	globalUtility <- 0.0;
	 	loop gst over: Guest.population
	 	{
	 		loop staUti over: gst.stageUtilityPairs.pairs
	 		{
	 			if(staUti.key = gst.targetStage)
	 			{
	 				globalUtility <- globalUtility + float(staUti.value);
	 			}
	 		}
	 	}
	}
	
	reflex calculateGlobalHappiness 
	{
	 	globalHappiness <- 0.0;
	 	loop gst over: Guest.population
	 	{
	 		globalHappiness <- globalHappiness + gst.happiness;
	 	}
	}
	
	reflex calculateGlobalEnergy
	{
	 	globalEnergy <- 0.0;
	 	loop gst over: Guest.population
	 	{
	 		globalEnergy <- globalEnergy + gst.energy;
	 	}
	}
	

	reflex conferenceOver when: length(Conference.population) = 0{
		
	}
	

	action createAuctions
	{
		
		loop i from: 0 to: length(itemsAvailable)-1
		{
			create Auctioner
			{
				location <- myself.location;
				soldItem <- itemsAvailable[i];
				targetLocation <- {rnd(100),rnd(100)};
				myself.auctioners <+ self;
			}
		}
		
		auctionsCreated <- true;
		auctionsNext <- false;
		
	}
	
	action createStages
	{
		write "===== Stages start =====";

		int counter <- 0;
		create Stage number: length(stageColors)
		{
			myself.stages <+ self;
			myColor <- stageColors[counter];
			string genesisString <- name + " (" + myColor + ") with " + stageStyle + " ";
			myIndex <- counter;
			counter <- counter + 1;
			write genesisString;
		}
		
		stagesCreated <- true;
		stagesRunning <- true;
		stagesNext <- false;
	}
	
	action createConferences
	{
		create Conference{
			
		}
		conferenceCreated <- true;
		conferenceNext <- false;
		
		write "====== Conference starts ======";
	}
	
	action activityEnded
	{
		nextActivityStartTime <- int(time + rnd(showMasterIntervalMin, showMasterIntervalMax));
	}
	
}

species Auctioner skills:[fipa, moving] parent: Building
{
	// Auction's initial size and color, location used in the beginning
	int mySize <- 5;
	rgb myColor <- #gray;
	point targetLocation <- nil;
	
	int auctionerDutchPrice <- rnd(dutch_init_min, dutch_init_max);
	int auctionerEngPrice <- rnd(eng_init_min, eng_init_max);
	int auctionerMinimumValue <- rnd(auctionerMinimumValueMin, auctionerMinimumValueMax);
	
	// vars related to start and end of auction
	bool auctionRunning <- false;
	bool startAnnounced <- false;
	
	string auctionType <- auctionTypes[rnd(length(auctionTypes) - 1)];
	int currentBid <- 0;
	string currentWinner <- nil;
	message winner <- nil;
	
	float startTime;

	string soldItem <- "";
	list<Guest> interestedGuests;
	bool dieAnnounced <- false;

	aspect base
	{
		draw circle(mySize) color: myColor;
	}

	reflex casinoLigths when: targetLocation = nil
	{
		if(flip(0.5) and mySize < 4)
		{
			mySize <- mySize + 1;
		}
		else if(mySize >= 8)
		{
			mySize <- mySize - 1;
		}
	}
	

	 reflex goToLocation when: targetLocation != nil
	 {
	 	if(location distance_to targetLocation <= 0.1)
	 	{
	 		if(auctionRunning or dieAnnounced)
	 		{
	 			write name + " has finished";
	 			ask ShowMaster
	 			{
	 				auctioners >- myself;
	 			}
	 			do die;
	 		}
	 		targetLocation <- nil;
	 	}
	 	else
	 	{
	 		do goto target: targetLocation speed: security_speed* 2;	
	 		myColor <- #gray;
	 		mySize <- 5;
	 	}
	 }
	 
	  reflex auctionDie when: startAnnounced and empty(interestedGuests) and time >= startTime + auctionerWaitTime and !auctionRunning and !dieAnnounced
	  {
	  	write name + " ended.";
	  	targetLocation <- master_location;
	  	dieAnnounced <- true;
	  }

	reflex sendStartAuction when: !auctionRunning and one_of(ShowMaster).auctionsRunning and targetLocation = nil and !startAnnounced
	{
		write name + " starting " + auctionType + " soon";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', soldItem]);
		startAnnounced <- true;
		startTime <- time;
	}

	reflex guestsAreAround when: !auctionRunning and !empty(interestedGuests) and (interestedGuests max_of (location distance_to(each.location))) <= 13
	{
		auctionRunning <- true;
	}

	reflex auction_recv_acception when: auctionRunning and !empty(accept_proposals) and !empty(interestedGuests)
	{
		if(auctionType = "Dutch")
		{
			
			loop a over: accept_proposals {
				write name + ' got accepted by ' + a.sender + ': ' + a.contents;
				do start_conversation (to: a.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
			}
			targetLocation <- master_location;
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
			interestedGuests <- [];
		}
	}

	reflex auction_get_proposes when: (!empty(proposes)) and !empty(interestedGuests)
	{
		if(auctionType = "Sealed")
		{
			targetLocation <- master_location;

			loop p over: proposes {
				list<unknown> ls <- p.contents;
				if(currentBid < int(ls[1]))
				{
					currentBid <- int(ls[1]);
					currentWinner <- p.sender;
					winner <- p;
				}
			}
			do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
			do accept_proposal with: (message: winner, contents: ['Item is yours']);
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop"]);
			interestedGuests <- [];
		}
		else if(auctionType = "English")
		{
			loop p over: proposes {
				list<unknown> ls <- p.contents;
				if(currentBid < int(ls[1]))
				{
					currentBid <- int(ls[1]);
					currentWinner <- p.sender;
					winner <- p;
				}
			}
		}
	}

	reflex auction_recv_reject when: auctionRunning and !empty(reject_proposals) and !empty(interestedGuests)
	{
		if(auctionType = "Dutch")
		{
			
			auctionerDutchPrice <- auctionerDutchPrice - rnd(dutch_dec_min, dutch_dec_max);
			if(auctionerDutchPrice < auctionerMinimumValue)
			{
				targetLocation <- master_location;

				write name + ' price went below minimum value (' + auctionerMinimumValue + '). No more auction for thrifty guests!';
				do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
				interestedGuests <- [];
			}
		}
		else if(auctionType = "English")
		{	
			loop r over: reject_proposals 
			{
				interestedGuests >- r.sender;
			}
			if(length(interestedGuests) < 2)
			{
				targetLocation <- master_location;

				if(currentBid < auctionerMinimumValue)
				{
					write name + ' bid ended. No more auctions for poor people!';
				}
				else
				{
					write 'Bid ended. Winner is: ' + currentWinner + ' with a bid of ' + currentBid;	
					do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
				}
				if(!empty(interestedGuests))
				{
					do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop"]);
				}
				interestedGuests <- [];
			}
		}
	}

	reflex auction_send_info when: auctionRunning and !empty(interestedGuests){
		if(auctionType = "Dutch")
		{
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: ['Buy my merch, peasant', auctionType, auctionerDutchPrice]);
		}
		else if(auctionType = "English")
		{
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Bid for English", currentBid]);
		}
		else if(auctionType = "Sealed")
		{
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Bid For Sealed']);
		}
	}	
}// Auctioner

species Stage parent: Building
{
	float mySize <- 5.0;
	rgb myColor <- #gray;
	
	bool showExpired <- false;
	float startTime <- time;
	int duration <- rnd(durationMin, durationMax);
	
	int stageLights <- rnd(stage_score_min,stage_score_max);
	int stageBand <- rnd(stage_score_min,stage_score_max);
	int stageShow <- rnd(stage_score_min,stage_score_max);
	int stageSpeaker <- rnd(stage_score_min,stage_score_max);
	string stageStyle <- style_available[rnd(length(style_available) - 1)];
	
	// Stages keep a record of their crowd sizes
	list<Guest> crowdedGuest <-[];
	int myIndex;
	
	aspect base
	{
		draw circle(mySize) color: myColor at: location;
	}
	

	reflex showMustNotGoOn when: time >= startTime + duration
	{
		write name + "'s " + stageStyle + " show has finished";
		ask ShowMaster
		{
			stages >- myself;
		}
		do die;
	}	
	
}

species Conference skills: [fipa] parent: LongStayPlace
{
	int maxParticipants <- 8;
	
	int replyCounter <- 0;
	
	list<Guest> participants <- [];
	
	init
	{
		write 'Conference announces it starts soon';
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'propose', contents: ["interested?"]);
	}
	
	reflex receiveAcceptProposals when: !empty(accept_proposals) 
	{
		replyCounter <- replyCounter + length(accept_proposals);
		loop a over: accept_proposals
		{
			if(maxParticipants > length(participants))
			{
				participants <+ a.sender;
				write "" + a.sender + " joins the scientific conference!";
				do start_conversation (to: participants, protocol: 'no-protocol', performative: 'inform', contents: ["you're in!"]);
			}
		}
	}
	
	reflex receiveRejectProposals when: !empty(reject_proposals)
	{
		replyCounter <- replyCounter + length(reject_proposals);
	}
	
	reflex startConference when: (length(participants) = maxParticipants or replyCounter = length(Guest.population))
	{	
		if(!one_of(ShowMaster).conferenceRunning)
		{
			if(length(participants) > 0 and participants max_of (location distance_to(each.location)) <= longStayPlaceRadius)
			{
				ask ShowMaster
				{
					conferenceRunning <- true;
				}
				do start_conversation (to: participants, protocol: 'no-protocol', performative: 'inform', contents: ["conference start"]);
			}
			
		}
	}
	
	reflex guestsHaveLeft when: one_of(ShowMaster).conferenceRunning and participants min_of (location distance_to(each.location)) > longStayPlaceRadius
	{
		write "====== Conference ended ======";
		do die;
	}
	
	aspect base
	{
		draw circle(3.5) color: rgb(117, 49, 23) at: location;
	}
}

species Security skills:[moving]
{
	list<Guest> targets;
	aspect base
	{
		draw triangle(4) at: location color: #darkblue;
	}
	
	reflex catchBadGuest when: length(targets) > 0
	{
		if(targets[0].targetAuction != nil)
		{
			targets >- first(targets);
		}
		else
		{
			do goto target:(targets[0].location) speed: security_speed;
		}
	}
	
	reflex badGuestCaught when: length(targets) > 0 and location distance_to(targets[0].location) < 0.2
	{
		ask one_of(targets)
		{
			write name + ': locked by security!';
			isCaught <- true;
		}
	
		targets >- first(targets);
	}
		reflex guardBad when: empty(targets)
	{
		do goto target:one_of(Prison) speed:guest_speed;
	}
}//Security end

species Prison parent: Building
{
	aspect base
	{
		draw triangle(6) at: location color: #black;
	}
}

experiment main type: gui
{
	parameter "Initial number of guests: " var: guest_number min:0 max: 100 category:"Guest";
	//parameter "Energy consume rate: " var: energy_consume min:0 max: 1.0 category:"Guest";
	parameter "Happiness consume rate: " var: happiness_consume min:0.0 max: 1.0 category:"Guest";
	
	output
	{
		display main_display
		{
			species Guest aspect: base;
			species InfoCenter aspect: base;
			species Bar aspect: base;
			
			species Security aspect: base;
			species Prison aspect: base;
			
			species ShowMaster aspect: base;
			species Auctioner aspect: base;
			species Stage aspect: base;
			species Conference aspect: base;
		}
		display global_utility refresh: every(10#cycles) 
		{
			chart "global_util" type:series size: {1,0.5} position: {0, 0}{
				data "Global utility: " value: globalUtility color: #blue;
			}
		}
		
		display global_info refresh: every(10#cycles) 
		{
			chart "global_info" type:series size: {1,0.5} position: {0, 0}{
				data "Global energy: " value: globalEnergy color: #orange;
				data "Global happiness: " value: globalHappiness color: #pink;
			}
			
			chart "Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
				data "]0;25]" value: Guest count (each.energy <= 25.0) color:#orange;
				data "]25;50]" value: Guest count ((each.energy > 25.0) and (each.energy <= 50.0)) color:#orange;
				data "]50;75]" value: Guest count ((each.energy > 50.0) and (each.energy <= 75.0)) color:#orange;
				data "]75;100]" value: Guest count (each.energy > 75.0) color:#orange;
			}
			chart "Happiness Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {
				data "]0;25]" value: Guest count (each.happiness <= 25.0) color: #pink;
				data "]25;50]" value: Guest count ((each.happiness > 25.0) and (each.happiness <= 50.0)) color: #pink;
				data "]50;75]" value: Guest count ((each.happiness > 50.0) and (each.happiness <= 75.0)) color: #pink;
				data "]75;100]" value: Guest count (each.happiness > 75.0) color: #pink;
			}
		}
		

		monitor "Global Utility" value: globalUtility;
		monitor "Global Happiness" value: globalHappiness;
		monitor "Global Energy" value: globalEnergy;
	}
}
