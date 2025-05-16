local QuestionGame = {}

QuestionGame.MENU_NAME = "QuestionType"

QuestionGame.QUESTION_COOLDOWN = 2.2
QuestionGame.QUESTION_SHOW_DELAY = 1
QuestionGame.MAIN_QUESTION_REMOVE_DELAY = 30
QuestionGame.OLD_QUESTION_REMOVE_DELAY = 7
QuestionGame.MAX_QUESTIONS = 3

QuestionGame.Questions = {
	["All"] = {
		"Some question in all category",
		"Some other question in all category",
	},
	["General"] = {
		"Some question in general category",
		"Some other question in general category",
	},
	["Deep"] = {
		"Some question in general category",
		"Some other question in general category",
	},
	["Funny"] = {
		"Some question in general category",
		"Some other question in general category",
	},
	["Weird"] = {
		"Some question in general category",
		"Some other question in general category",
	},
	["Intro"] = {
		"Some question in general category",
		"Some other question in general category",
	},
	["Yes/No"] = {
		"Have you ever traveled abroad?",
		"Do you like pineapple on pizza?",
		"Have you ever broken something expensive?",
		"Have you ever lied to get out of trouble?",
		"Do you believe in aliens?",
		"Have you ever cheated in a game?",
		"Do you enjoy playing video games?",
		"Have you ever been on a plane?",
		"Do you have a pet?",
		"Have you ever stayed up all night?",
		"Do you like to sing in the shower?",
		"Have you ever won a contest or competition?",
		"Do you think you’re a good cook?",
		"Have you ever met a celebrity?",
		"Do you believe in ghosts?",
		"Have you ever been to a theme park?",
		"Do you like spicy food?",
		"Have you ever forgotten someone’s birthday?",
		"Do you prefer mornings over nights?",
		"Have you ever been on a rollercoaster?",
		"Have you ever felt like someone was watching you when you were alone?",
		"Do you believe someone you loved has come back to visit you after they passed?",
		"Have you ever heard a noise in your house when no one was around?",
		"Do you believe in fate or destiny?",
		"Have you ever had a dream that felt too real to be just a dream?",
		"Have you ever experienced deja vu that scared you?",
		"Do you feel like something is following you when you walk alone at night?",
		"Have you ever seen something you couldn't explain in the dark?",
		"Do you believe in soulmates?",
		"Have you ever had a near-death experience?",
		"Do you ever feel like there’s something hiding in your reflection?",
		"Have you ever thought you saw something move out of the corner of your eye?",
		"Do you believe in supernatural forces controlling your life?",
		"Have you ever heard your name being called when no one was around?",
		"Do you ever get the feeling that someone is in your house when you're not home?",
		"Have you ever had a ghostly experience in your house?",
		"Do you get scared when you hear footsteps behind you at night?",
		"Have you ever experienced a traumatic event that still haunts you?",
		"Do you believe the eyes are the window to the soul?",
		"Have you ever seen a shadow figure lurking in the corner of a room?",
		"Do you feel like someone is standing behind you when you’re alone?",
		"Have you ever been in a place that gave you an overwhelming sense of dread?",
		"Do you believe dreams are a reflection of your subconscious fears?",
		"Have you ever seen a mysterious light in the sky that you couldn't explain?",
		"Do you feel like you’ve encountered someone from your past in a dream?",
		"Have you ever had a dream that predicted something that later happened?",
		"Do you think someone is watching you through your windows at night?",
		"Have you ever experienced something that made you question your sanity?",
		"Do you ever hear voices in your head when you're alone with your thoughts?",
		"Have you ever wondered if you’re being followed by something you can't see?",
		"Have you ever felt someone watching you?",
		"Do you believe in ghosts?",
		"Have you heard footsteps when alone?",
		"Do you ever feel like you're being followed?",
		"Have you ever seen something move by itself?",
		"Do you believe in evil spirits?",
		"Have you ever had a nightmare that felt real?",
		"Do you hear voices when no one’s around?",
		"Have you ever felt a presence in the room?",
		"Do you get chills when no one’s near?",
		"Have you seen a shadow figure?",
		"Do you believe in curses?",
		"Have you ever been in an abandoned building?",
		"Do you feel like something's always watching you?",
		"Have you ever seen an unexplainable light?",
		"Do you ever feel something's hiding in the dark?",
		"Have you ever heard your name called when alone?",
		"Do you think spirits can communicate with us?",
		"Have you ever had a feeling of dread for no reason?",
		"Do you believe in demons?",
		"Have you ever felt like you were in a bad dream?",
		"Do you think objects can be haunted?",
		"Have you ever experienced déjà vu in a scary way?",
		"Do you believe in life after death?",
		"Have you ever been touched by something unseen?",
		"Do you feel uneasy around mirrors at night?",
		"Have you ever heard someone crying when no one's there?",
		"Do you believe in superstitions?",
		"Have you ever seen something disappear in front of you?",
		"Do you get scared in the dark?",
	},
	["This Or That"] = {
		"Coffee or Tea?",
		"Cats or Dogs?",
		"Morning person or Night owl?",
		"Pizza or Burgers?",
		"City life or Country life?",
		"Texting or Calling?",
		"Netflix binge or Movie night out?",
		"Super strength or Invisibility?",
		"Beach vacation or Mountain retreat?",
		"Books or Video games?",
		"Chocolate or Vanilla?",
		"Instagram or TikTok?",
		"Time travel to the past or future?",
		"Aliens or Ghosts",
		"Win the lottery or live twice as long?",
		"Teleportation or Mind Reading?",
		"Fight one horse-sized duck or 100 duck-sized horses?",
		"Permanently speak in rhymes or only whisper?",
		"Live with no internet or no AC/heating?",
		"Pineapple on pizza or pickles in ice cream?",
		"Lose your phone or lose your wallet?",
		"Have hiccups forever or sneeze every 30 minutes?",
		"Talk to animals or speak every language?",
		"Be able to fly or breathe underwater?",
		"Only be able to walk backward or only be able to whisper?",
		"Always feel slightly itchy or always feel a pebble in your shoe?",
		"Never use social media again or never watch TV again?",
		"Unlimited sushi for life or unlimited tacos?",
		"Sleep 2 hours a day and feel rested or sleep 10 hours and always feel tired?",
		"Marry your celebrity crush or become a celebrity yourself?",
		"Have your dream job but low pay or boring job with high pay?",
		"Eat only sweet food or only salty food for the rest of your life?",
		"Be stuck in a comedy movie or a horror movie?",
		"Live in space or live underwater?",
		"Always be 5 minutes late or always be 20 minutes early?",
	},
	["Would You Rather"] = {
		"Would you rather disappoint someone you love or let yourself down to keep them happy?",
		"Would you rather change one decision from your past or know one decision from your future?",
		"Would you rather never feel fear again or never feel regret again?",
		"Would you rather be known for something you're proud of but few people care, or be famous for something you're embarrassed about?",
		"Would you rather your only mode of transportation be a pogo stick or a shopping cart?",
		"Would you rather have your shadow tell dad jokes nonstop or your reflection wink at you at random times?",
		"Would you rather burp confetti or fart glitter",
		"Would you rather have a rewind button or a pause button for your life?",
		"Would you rather have fingers made of spaghetti or legs made of pool noodles?",
		"Would you rather be able to taste music or see people's moods as colors?",
		"Would you rather be loved deeply by one person or liked by many?",
		"Would you rather have infinite time or infinite knowledge?",
		"Would you rather only be able to use your elbows to eat, or your feet to type?",
		"Would you rather always be 10 minutes too late or 20 minutes too early for everything, forever?",
	},
}

QuestionGame.START_QUESTION_TYPE = "All"
QuestionGame.QUESTION_HIDE_STUDS_OFFSET = Vector3.yAxis * 2

QuestionGame.HIGHLIGHT_PROPERTIES = {
	FillColor = Color3.new(1, 1, 1),
	DepthMode = Enum.HighlightDepthMode.Occluded,
}

QuestionGame.BUTTON_SELECTED_COLOR = Color3.fromRGB(215, 224, 244)
QuestionGame.BUTTON_COLOR = Color3.new(1, 1, 1)

QuestionGame.SPRING_SPEED = 20
QuestionGame.SPRING_RESPONSIVENESS = 0.5
QuestionGame.ADDED_SIZE = UDim2.fromOffset(10, 10)

QuestionGame.TWEEN_INFO = TweenInfo.new(0.25)

QuestionGame.MAX_CHARACTER_INTERACT_DISTANCE = 30

return QuestionGame