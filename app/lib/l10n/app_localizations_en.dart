// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loveToLearnSign => 'Bangla Sign Language';

  @override
  String get headlineSignLanguage => 'Bangla Sign Language';

  @override
  String get drawerMenu => 'Menu';

  @override
  String get settings => 'Settings';

  @override
  String get addWord => 'Add a new word';

  @override
  String get drawerLogin => 'Login';

  @override
  String get drawerLogout => 'Logout';

  @override
  String get logoutSuccess => 'You have successfully logged out!';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get share => 'Share';

  @override
  String get favorite => 'Add to Favorite';

  @override
  String get unfavorite => 'Remove from Favorite';

  @override
  String get tabHome => 'Home';

  @override
  String get tabDictionary => 'Dictionary';

  @override
  String get tabGame => 'Games';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsLanguage => 'App Language';

  @override
  String get english => 'English';

  @override
  String get bengali => 'Bengali';

  @override
  String get settingsLanguageSubtitle =>
      'Change the app\'s language across all screens';

  @override
  String get general => 'General';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get settingsSectionCachingOptions => 'Caching Options';

  @override
  String get preloadVideosTitle => 'Preload videos when opening a category';

  @override
  String get preloadVideosSubtitle =>
      'This can reduce wait time but may use more data';

  @override
  String get clearCachedVideosTitle => 'Clear cached videos';

  @override
  String get clearCachedVideosSubtitle =>
      'Remove all downloaded videos from cache';

  @override
  String get dialogClearCacheTitle => 'Clear Cache';

  @override
  String get dialogClearCacheContent =>
      'Are you sure you want to delete all cached videos?';

  @override
  String get snackbarCacheNotFound => '⚠️ Cache directory not found.';

  @override
  String get snackbarCacheCleared => '✅ Cache cleared successfully';

  @override
  String get maxCacheSizeTitle => 'Maximum cache size';

  @override
  String get maxCacheSizeSubtitle =>
      'Set how much space the cache is allowed to use (in MB)';

  @override
  String get cacheWifiTitle => 'Cache videos only on Wi-Fi';

  @override
  String get cacheWifiSubtitle =>
      'When enabled, videos will be cached in the background only if the device is connected to Wi-Fi.';

  @override
  String get storageSectionTitle => 'Storage';

  @override
  String currentCacheUsage(Object mb) {
    return 'Current cache: $mb MB';
  }

  @override
  String get openSystemStorageSettings => 'Open system storage settings';

  @override
  String get calculating => 'Calculating...';

  @override
  String get notificationNewWordsTitle => 'New words added';

  @override
  String get notificationNewWordsBody =>
      'New words added to the dictionary! Go to the app’s homepage to see what’s new.';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String currentCacheTitle(String mb) {
    return 'Current Cache — $mb MB';
  }

  @override
  String get currentCacheSubtitle =>
      'Approximate size of videos and thumbnails stored locally for faster playback. Tap refresh to recalculate.';

  @override
  String get notificationLearnWordTitle => 'Learn one sign today!';

  @override
  String get notificationLearnWordHelp =>
      'If you are unable to see the notification then please go to Settings > Apps > Special app access > Alarms & reminders and allow reminders for the Love to Learn Sign app.';

  @override
  String get notificationLearnWordTimeTitle => 'Notification Time';

  @override
  String get notificationCategoryTitle => 'Select category';

  @override
  String notificationLearnWordBody(Object word) {
    return 'Have you learned your new word today?\n$word';
  }

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get headlineTitle => 'Love to Learn Sign';

  @override
  String get favoritesVideos => 'Favorite Videos';

  @override
  String get noFavorites => 'No favorites yet.';

  @override
  String get whatsNew => 'What\'s New';

  @override
  String get noNewVideos => 'No new videos recently.';

  @override
  String get online => 'Online';

  @override
  String get website => 'Website';

  @override
  String get instagram => 'Instagram';

  @override
  String get facebook => 'Facebook';

  @override
  String get donation => 'Donation';

  @override
  String get contactUs => 'Contact us';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get tabHistory => 'History';

  @override
  String get searchHint => 'Search by English or Bengali...';

  @override
  String get selectCategory => 'Or select a category';

  @override
  String get allWords => 'All Words';

  @override
  String get noResults => 'No results found.';

  @override
  String get containerBText => 'Search for a word or select a category';

  @override
  String get noHistory => 'No history yet.';

  @override
  String get clearHistoryTooltip => 'Clear history';

  @override
  String get chooseGame => 'Choose a game';

  @override
  String get donationErrorInvalidAmount =>
      'Please enter or select a valid amount.';

  @override
  String get donationErrorSelectMethod => 'Please select a payment method.';

  @override
  String get donationErrorStripeCustomMonthly =>
      'Custom recurring amount not supported for Stripe.';

  @override
  String get donationErrorStripeCustom =>
      'Custom amount not supported for Stripe.';

  @override
  String get donationBankTransferTitle => 'Bank Transfer Instructions';

  @override
  String donationBankTransferContentWithAmount(Object amount) {
    return 'Thank you for your willingness to donate $amount.\n\nPlease transfer to:\nAccount holder: Your Name or Organization\nIBAN: XX00 0000 0000 0000 0000\nBIC/SWIFT: ABCDUSXX\n\nIn the reference, indicate \"Donation $amount\".';
  }

  @override
  String get donationBankTransferContent =>
      'Thank you for your willingness to donate.\n\nPlease transfer to:\nAccount holder: Your Name or Organization\nIBAN: XX00 0000 0000 0000 0000\nBIC/SWIFT: ABCDUSXX\n\nIn the reference, indicate \"Donation\".';

  @override
  String get donationButton => 'Donate';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get flashcardGame => 'Flashcard';

  @override
  String get noVideo => 'No video available';

  @override
  String get numberOfFlashcards => 'Number of flashcards';

  @override
  String get numberOfFlashcardsDesc => 'Choose how many cards to study.';

  @override
  String get flashcardContent => 'Flashcard content';

  @override
  String get flashcardContentDesc =>
      'Select which category the flashcards come from.';

  @override
  String get flashcardStartingPointTitle => 'Starting side';

  @override
  String get flashcardStartingPointDesc =>
      'Choose what appears on the front of the card.';

  @override
  String get flashcardStartingPointWord => 'A word';

  @override
  String get flashcardStartingPointSign => 'A sign language video';

  @override
  String get quizCompleted => 'Quiz completed';

  @override
  String get tryAgain => 'Try again';

  @override
  String get backToCategories => 'Back to categories';

  @override
  String get backToGamePage => 'Back to game page';

  @override
  String get randomWordsQuiz => 'Random words';

  @override
  String get quizByCategory => 'Quiz by category';

  @override
  String get questionPrompt => 'What does this sign mean?';

  @override
  String get noWordsFound => 'No words found.';

  @override
  String get selectAnswerFirst => 'Select your answer first';

  @override
  String get submit => 'Submit';

  @override
  String get next => 'Next';

  @override
  String shareText(Object score, Object total) {
    return 'I scored $score/$total in the sign language quiz! Can you beat me? Download Love to Learn Sign: https://love2learnsign.com/download';
  }

  @override
  String get loginSuccess => 'You have successfully logged in!';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHelperText =>
      'Use at least 12 characters with uppercase, lowercase, numbers, and symbols';

  @override
  String get passwordValidatorEmpty => 'Please enter a password';

  @override
  String get passwordValidatorRequirements =>
      'Password must be at least 12 characters and include uppercase, lowercase, a number, and a symbol';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Sign In';

  @override
  String get resetPasswordSent =>
      'Please check your email for password reset instructions.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordInstructions => 'Enter your email below';

  @override
  String get validatorEnterEmail => 'Please enter your email';

  @override
  String get validatorValidEmail => 'Enter a valid email';

  @override
  String get resetPasswordButton => 'Send reset link';

  @override
  String get chooseCategory => 'Choose category';

  @override
  String get errorPrefix => 'Error';

  @override
  String get noCategories => 'No categories found.';

  @override
  String get infoMinimumCategories =>
      'Categories with at least 4 words are shown.';

  @override
  String get reviewedModeTitle => 'Reviewed mode';

  @override
  String get reviewedModeSubtitle => 'Review wrong answers at the end.';

  @override
  String get speedModeTitle => 'Timed answers mode';

  @override
  String get speedModeSubtitle => 'You have a time limit to answer.';

  @override
  String get timeLimitTitle => 'Time limit';

  @override
  String get setTimeLimitTitle => 'Set time limit';

  @override
  String get numberOfQuestions => 'Number of questions';

  @override
  String get setQuestionCountTitle => 'Set question count';

  @override
  String get quizMessageLevel1 => 'Oh no, don\'t worry.';

  @override
  String get quizMessageLevel2 => 'You\'re improving.';

  @override
  String get quizMessageLevel3 => 'Good try!';

  @override
  String get quizMessageLevel4 => 'Nice job!';

  @override
  String get quizMessageLevel5 => 'Excellent work!';

  @override
  String quizTitleDynamic(Object category) {
    return 'Quiz: $category';
  }

  @override
  String get notEnoughWords => 'Not enough words in this category.';

  @override
  String get timeUpMessage => 'Time\'s up!';

  @override
  String questionProgress(Object current, Object total) {
    return '$current / $total questions';
  }

  @override
  String reviewedQuestionProgress(Object current) {
    return 'Reviewed question #$current';
  }

  @override
  String get activitiesAndHobbies => 'Activities & Hobbies';

  @override
  String get adjectives => 'Adjectives';

  @override
  String get businessAndManagement => 'Business & Management';

  @override
  String get educationAndAcademia => 'Education & Academia';

  @override
  String get familyAndRelationships => 'Family & Relationships';

  @override
  String get foodAndDrinks => 'Food & Drinks';

  @override
  String get geographyBangladesh => 'Geography – Bangladesh';

  @override
  String get geographyInternational => 'Geography – International';

  @override
  String get health => 'Health';

  @override
  String get house => 'House';

  @override
  String get languageBasics => 'Language Basics';

  @override
  String get mediaAndCommunication => 'Media & Communication';

  @override
  String get natureAndEnvironment => 'Nature & Environment';

  @override
  String get nouns => 'Nouns';

  @override
  String get technologyAndScience => 'Technology & Science';

  @override
  String get timeAndDates => 'Time & Dates';

  @override
  String get transport => 'Transport';

  @override
  String get verbs => 'Verbs';

  @override
  String get reviewBox => 'Review Box';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByVolume => 'Volume';

  @override
  String get overdue => 'overdue';

  @override
  String inDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'in $days day$_temp0';
  }

  @override
  String get today => 'today';

  @override
  String signCount(num signCount) {
    String _temp0 = intl.Intl.pluralLogic(
      signCount,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Sign$_temp0';
  }

  @override
  String get reviewNow => 'Review now';

  @override
  String signsToReview(num count, Object dayLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count sign$_temp0 to review — $dayLabel';
  }

  @override
  String get howToReorderFavorites => 'How to reorder favorites';

  @override
  String get longPressThumbnail =>
      '• Long-press a thumbnail to start dragging.';

  @override
  String get dragLeftRight => '• Drag left or right to change its position.';

  @override
  String get releaseToDrop => '• Release to drop and save the new order.';

  @override
  String get newFavoritesAdded =>
      '• New favorites are added at the end by default.';

  @override
  String get gotIt => 'Got it';

  @override
  String get randomAllCategories => 'Random (all categories)';

  @override
  String get wordsFromEntireDatabase => 'Words from the entire database';

  @override
  String get chooseQuizCategory => 'Choose Quiz Category';

  @override
  String get quizCategoriesInfo =>
      'Categories must have at least 4 words to be playable.';

  @override
  String get quizGame => 'Quiz';

  @override
  String get flashcardOptions => 'Flashcard Options';

  @override
  String get newFlashcardGame => 'New Flashcard Game';

  @override
  String get flashcardMastered => 'Mastered';

  @override
  String get flashcardToReview => 'To review';

  @override
  String get flashcardChooseReviewFrequency => 'Choose review frequency:';

  @override
  String flashcardDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$days day$_temp0';
  }

  @override
  String get flashcardCongratsTitle => 'Great job! 🎉';

  @override
  String flashcardSessionCompleted(Object count) {
    return 'You’ve completed your $count flashcards!';
  }

  @override
  String get flashcardStatsMastered => '✅ Mastered';

  @override
  String get flashcardStatsToReview => '🔄 To review';

  @override
  String get flashcardStatsByFrequency => 'Words to review by frequency:';

  @override
  String get flashcardFinish => 'Finish';

  @override
  String get flashcardTapToFlip => 'Tap to flip';

  @override
  String get onboardingIntroText =>
      'Welcome to the Love to Learn Sign app!\nWe\'re excited that you\'ve downloaded the app, and we hope it becomes a valuable tool for your journey in learning Bangla Sign Language.\n\nThrough word searches and interactive games, you\'ll be able to learn step by step, practice, and make real progress. Whether you are hearing or deaf, this app is designed to help you grow in your knowledge and confidence in sign language.\n\nOnce again, welcome aboard — and most importantly, enjoy the experience while you learn!';

  @override
  String get loadingNextQuestion => 'Loading next question...';

  @override
  String get loadingQuizPleaseWait => 'Loading the quiz, please wait...';

  @override
  String get privacySectionTitle => 'Legal & Privacy';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle =>
      'Read our privacy policy and data practices';

  @override
  String get privacyDialogIntro =>
      'Love to Learn Sign respects your privacy and is committed to protecting your personal information.';

  @override
  String get privacyDialogDataUsageTitle =>
      'Our app collects and uses data to:';

  @override
  String get privacyDialogPointPersonalized =>
      '• Provide personalized learning experience';

  @override
  String get privacyDialogPointAccount =>
      '• Manage user accounts (email for sign-in/sign-up)';

  @override
  String get privacyDialogPointPremium =>
      '• Process premium subscriptions (via Google Play/App Store)';

  @override
  String get privacyDialogPointAds =>
      '• Display advertisements (for non-premium users via Google AdMob)';

  @override
  String get privacyDialogPointReminders =>
      '• Send daily reminder notifications';

  @override
  String get privacyDialogPointCaching =>
      '• Store video content locally for offline access';

  @override
  String get privacyDialogPointTracking =>
      '• Track usage (video views, game sessions) to improve features';

  @override
  String get privacyDialogPointSearchAnalytics =>
      '• Log anonymous dictionary search analytics (query text, category, result count, found/missing) to improve content — no user IDs are stored';

  @override
  String get privacyDialogPointDemographic =>
      '• Collect demographic information (hearing status) to understand our user base and improve content for both deaf and hearing learners';

  @override
  String get privacyDialogPointImprove =>
      '• Improve app performance and features';

  @override
  String get privacyDialogThirdPartyTitle => 'Third-Party Services:';

  @override
  String get privacyDialogThirdPartyFirebase =>
      '• Google Firebase - Authentication, database, analytics';

  @override
  String get privacyDialogThirdPartyAdmob =>
      '• Google Mobile Ads (AdMob) - Advertisement display and tracking';

  @override
  String get privacyDialogThirdPartyStores =>
      '• Google Play Store / Apple App Store - Premium subscription payments';

  @override
  String get privacyDialogRightsTitle => 'Your Rights:';

  @override
  String get privacyDialogRightsAccess =>
      '• Access, modify, or delete your data through app settings';

  @override
  String get privacyDialogRightsCancel =>
      '• Cancel premium subscriptions through store settings';

  @override
  String get privacyDialogRightsAds =>
      '• Reset Advertising ID to opt-out of personalized ads';

  @override
  String get privacyDialogRightsDelete =>
      '• Request data deletion by contacting us';

  @override
  String get privacyDialogPremiumTitle => 'Premium Users:';

  @override
  String get privacyDialogPremiumNoAds =>
      '• Premium subscriptions remove all advertisements';

  @override
  String get privacyDialogPremiumPayment =>
      '• Payment data is processed securely by store platforms';

  @override
  String get privacyDialogPremiumNoCard =>
      '• We do not store your payment card information';

  @override
  String get privacyDialogFullPolicy =>
      'For the complete privacy policy, visit our website:';

  @override
  String get privacyDialogContact => 'Contact: info@netcreative-swas.net';

  @override
  String get close => 'Close';

  @override
  String get flashcardReminderTitle => 'Flashcard review reminders';

  @override
  String get flashcardReminderTime => 'Reminder time';

  @override
  String get administrationAndPublicServices =>
      'Administration & Public Services';

  @override
  String get cultureAndIdentity => 'Culture & Identity';

  @override
  String get politicsAndSociety => 'Politics & Society';

  @override
  String get professionsAndOccupations => 'Professions & Occupations';

  @override
  String get religion => 'Religion';

  @override
  String get jwOrganisation => 'JW Organisation';

  @override
  String get biblicalContent => 'Biblical Content';

  @override
  String get grammarAndBasics => 'Grammar & Basics';

  @override
  String get outdoorAndSports => 'Outdoor & Sports';

  @override
  String get artsAndCrafts => 'Arts & Crafts';

  @override
  String get musicAndDance => 'Music & Dance';

  @override
  String get games => 'Games';

  @override
  String get homeAndHobbies => 'Home & Hobbies';

  @override
  String get qualities => 'Qualities';

  @override
  String get flawsAndWeaknesses => 'Flaws & Weaknesses';

  @override
  String get emotions => 'Emotions';

  @override
  String get condition => 'Condition';

  @override
  String get citizenServicesAndIds => 'Citizen Services & IDs';

  @override
  String get publicServicesAndFacilities => 'Public Services & Facilities';

  @override
  String get governmentOfficesAndAuthorities =>
      'Government Offices & Authorities';

  @override
  String get documentsAndLaw => 'Documents & Law';

  @override
  String get planningAndOrganizing => 'Planning & Organizing';

  @override
  String get moneyAndEconomy => 'Money & Economy';

  @override
  String get dealsAndContracts => 'Deals & Contracts';

  @override
  String get moneyAndAccounts => 'Money & Accounts';

  @override
  String get operationsAndSupply => 'Operations & Supply';

  @override
  String get marketingAndSales => 'Marketing & Sales';

  @override
  String get peopleAndHr => 'People & HR';

  @override
  String get languages => 'Languages';

  @override
  String get clothesAndDress => 'Clothes & Dress';

  @override
  String get foodAndCooking => 'Food & Cooking';

  @override
  String get traditionsAndFestivals => 'Traditions & Festivals';

  @override
  String get artsAndHeritage => 'Arts & Heritage';

  @override
  String get schoolsAndColleges => 'Schools & Colleges';

  @override
  String get subjects => 'Subjects';

  @override
  String get examsAndGrades => 'Exams & Grades';

  @override
  String get classroomAndTools => 'Classroom & Tools';

  @override
  String get researchAndPapers => 'Research & Papers';

  @override
  String get familyMembers => 'Family Members';

  @override
  String get marriageAndInLaws => 'Marriage & In-Laws';

  @override
  String get relationshipsAndStatus => 'Relationships & Status';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get dishes => 'Dishes';

  @override
  String get drinks => 'Drinks';

  @override
  String get cookingAndTools => 'Cooking & Tools';

  @override
  String get eatingPlaces => 'Eating Places';

  @override
  String get citiesAndDistricts => 'Cities & Districts';

  @override
  String get towns => 'Towns';

  @override
  String get neighborhoodsAndLocalities => 'Neighborhoods & Localities';

  @override
  String get institutionsAndFacilities => 'Institutions & Facilities';

  @override
  String get countriesAndRegions => 'Countries & Regions';

  @override
  String get citiesAndCapitals => 'Cities & Capitals';

  @override
  String get natureLandAndWater => 'Nature (Land & Water)';

  @override
  String get landmarks => 'Landmarks';

  @override
  String get orgsAndCodes => 'Orgs & Codes';

  @override
  String get body => 'Body';

  @override
  String get illnessAndSymptoms => 'Illness & Symptoms';

  @override
  String get careAndTreatment => 'Care & Treatment';

  @override
  String get medicineAndTools => 'Medicine & Tools';

  @override
  String get fitnessAndDiet => 'Fitness & Diet';

  @override
  String get rooms => 'Rooms';

  @override
  String get furniture => 'Furniture';

  @override
  String get appliances => 'Appliances';

  @override
  String get toolsAndRepair => 'Tools & Repair';

  @override
  String get householdItems => 'Household Items';

  @override
  String get alphabet => 'Alphabet';

  @override
  String get numbers => 'Numbers';

  @override
  String get personalPronoun => 'Personal Pronouns';

  @override
  String get questionWords => 'Question Words';

  @override
  String get newsAndTvRadio => 'News & TV/Radio';

  @override
  String get onlineAndWeb => 'Online & Web';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get messagingAndCalls => 'Messaging & Calls';

  @override
  String get mediaTypes => 'Media Types';

  @override
  String get devices => 'Devices';

  @override
  String get weatherAndSeasons => 'Weather & Seasons';

  @override
  String get animals => 'Animals';

  @override
  String get plants => 'Plants';

  @override
  String get placesAndHabitats => 'Places & Habitats';

  @override
  String get earthAndDisasters => 'Earth & Disasters';

  @override
  String get people => 'People';

  @override
  String get objects => 'Objects';

  @override
  String get abstractObjects => 'Abstract Objects';

  @override
  String get socialBehaviour => 'Social Behaviour';

  @override
  String get habits => 'Habits';

  @override
  String get politicalSystemAndElections => 'Political System & Elections';

  @override
  String get ideologiesAndMovements => 'Ideologies & Movements';

  @override
  String get conflictsAndWars => 'Conflicts & Wars';

  @override
  String get governanceAndPolicyDebate => 'Governance & Policy Debate';

  @override
  String get socialIssuesAndCivilSociety => 'Social Issues & Civil Society';

  @override
  String get publicServiceRoles => 'Public Service Roles';

  @override
  String get businessRoles => 'Business Roles';

  @override
  String get educationAndKnowledgeRoles => 'Education & Knowledge Roles';

  @override
  String get generalProfessions => 'General Professions';

  @override
  String get technicalJobs => 'Technical Jobs';

  @override
  String get beliefsAndPractices => 'Beliefs & Practices';

  @override
  String get religiousPeople => 'People';

  @override
  String get religiousObjects => 'Objects';

  @override
  String get religiousPlaces => 'Religious Places';

  @override
  String get festivals => 'Festivals';

  @override
  String get concepts => 'Concepts';

  @override
  String get communication => 'Communication';

  @override
  String get cognition => 'Cognition';

  @override
  String get emotionAndAttitude => 'Emotion & Attitude';

  @override
  String get perception => 'Perception';

  @override
  String get actionAndManipulation => 'Action & Manipulation';

  @override
  String get movementAndPosture => 'Movement & Posture';

  @override
  String get stateAndChange => 'State & Change';

  @override
  String get devicesAndHardware => 'Devices & Hardware';

  @override
  String get softwareAndData => 'Software & Data';

  @override
  String get internetAndNetworks => 'Internet & Networks';

  @override
  String get engineeringAndMaking => 'Engineering & Making';

  @override
  String get newTechAndAi => 'New Tech & AI';

  @override
  String get calendar => 'Calendar';

  @override
  String get dayAndTime => 'Day & Time';

  @override
  String get schedules => 'Schedules';

  @override
  String get frequencyAndDuration => 'Frequency & Duration';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get places => 'Places';

  @override
  String get travelAndTickets => 'Travel & Tickets';

  @override
  String get roadAndTraffic => 'Road & Traffic';

  @override
  String get responsibility => 'Responsibility';

  @override
  String get publicationsAndMaterials => 'Publications & Materials';

  @override
  String get meetingsAndAssemblies => 'Meetings & Assemblies';

  @override
  String get manualAndBibleUse => 'Manual & Bible Use';

  @override
  String get serviceAndMinistry => 'Service & Ministry';

  @override
  String get locations => 'Locations';

  @override
  String get bibleCharacters => 'Bible Characters';

  @override
  String get historicalOrPropheticEvents => 'Historical or Prophetic Events';

  @override
  String get booksOfTheBible => 'Books of the Bible';

  @override
  String get bibleTeaching => 'Bible Teaching';

  @override
  String get biblicalSymbols => 'Biblical Symbols';

  @override
  String get wantToLearn => 'LEARN ALSO';

  @override
  String get tryTheOpposite => 'LEARN THE OPPOSITE';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get displayNameValidatorEmpty => 'Please enter your display name';

  @override
  String get displayNameValidatorMinLength =>
      'Display name must be at least 2 characters';

  @override
  String get countryLabel => 'Country *';

  @override
  String get countryHelperText => 'Please select your country';

  @override
  String get countryValidatorEmpty => 'Please select your country';

  @override
  String get userTypeLabel => 'i am';

  @override
  String get userTypeHelperText =>
      'Please tell us whether you are hearing impaired (deaf) or a hearing person';

  @override
  String get userTypeValidator =>
      'Please select whether you are Hearing Impaired (Deaf) or a hearing person';

  @override
  String get userTypeOptionHearingImpaired => 'Hearing Impaired (Deaf)';

  @override
  String get userTypeOptionHearing => 'a hearing person';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordValidatorEmpty => 'Please confirm your password';

  @override
  String get confirmPasswordValidatorMismatch => 'Passwords do not match';

  @override
  String get noteToAdministratorLabel => 'Note to Administrator (Optional)';

  @override
  String get noteToAdministratorHint =>
      'Write a message to the administrator (optional)';

  @override
  String get noteToAdministratorHelperText =>
      'Tell the administrator why you want to join (optional)';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signInLink => 'Sign In';

  @override
  String get passwordMismatchError =>
      'Passwords do not match. Please try again.';

  @override
  String get selectCountryError => 'Please select your country';

  @override
  String get captchaRequiredMessage =>
      'Please complete the security check to continue.';

  @override
  String get emailAlreadyExistsError =>
      'An account already exists for this email';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get premiumSignInRequiredBody =>
      'Please sign in to buy or restore Premium so it can be linked to your account.';

  @override
  String get newUserSignUp => 'New user? Please sign up';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get signInWithGoogle => 'Sign In with Google';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get approvingYourAccount => 'Approving your account...';

  @override
  String get emailVerifiedApprovedMessage =>
      'Email verified! Your account has been approved. Please sign in.';

  @override
  String get accountPendingApprovalTitle => 'Account Pending Approval';

  @override
  String get accountAwaitingApprovalHeadline =>
      'Your account is awaiting approval';

  @override
  String get emailVerifiedSuccess =>
      'Your email has been successfully verified.';

  @override
  String get accountPendingApprovalBody =>
      'Your email has been successfully verified. Your account is now pending administrator approval. You will receive access once the admin approves your account.';

  @override
  String get accessAfterApproval => 'Access after approval';

  @override
  String get whatHappensNext => 'What happens next?';

  @override
  String get nextAdminReview => 'An administrator will review your account';

  @override
  String get nextRoleAssignment => 'You will be assigned appropriate roles';

  @override
  String get nextAccessAfterApproved =>
      'You will receive full access to the app';

  @override
  String get returnToApp => 'Return to App';

  @override
  String get verifyStatusError => 'Error checking verification status';

  @override
  String get verifyEmailResentSuccess =>
      'Verification email resent successfully';

  @override
  String get verifyEmailResentError => 'Error resending verification email';

  @override
  String get verifyYourEmailTitle => 'Verify Your Email';

  @override
  String get verifyYourEmailHeadline => 'Please verify your email address';

  @override
  String get verifyEmailSentTo => 'A verification email has been sent to:';

  @override
  String get verifyEmailInfoHeader => 'Check your inbox';

  @override
  String get verifyEmailInfoBody =>
      'We\'ve sent a verification link to your email address. Please check your inbox (and spam folder) and click the link to verify your account.';

  @override
  String get verifyEmailAutoRedirectHint =>
      'You will be automatically redirected once your email is verified.';

  @override
  String get sendingLabel => 'Sending...';

  @override
  String get resendVerificationEmail => 'Resend Verification Email';

  @override
  String get checkingVerificationStatus => 'Checking verification status...';

  @override
  String get premiumSectionTitle => 'Premium';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get removeAdsUnlimitedAccess => 'Remove ads and get unlimited access';

  @override
  String get removeAllAdsForever =>
      'Remove all ads forever — Upgrade to Premium.';

  @override
  String get noThanks => 'No Thanks';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get monthlyLimitReached => 'Monthly Limit Reached';

  @override
  String get quizLimitReachedMessage =>
      'You\'ve reached your monthly free Quiz sessions. Watch a short ad to unlock 3 additional Quiz sessions.';

  @override
  String get flashcardLimitReachedMessage =>
      'You\'ve reached your monthly free Flashcard sessions. Watch a short ad to unlock 3 additional Flashcard sessions.';

  @override
  String get goPremiumUnlimited => 'Go Premium for unlimited learning';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String get quizSessionsUnlocked => '✅ 3 additional Quiz sessions unlocked!';

  @override
  String get flashcardSessionsUnlocked =>
      '✅ 3 additional Flashcard sessions unlocked!';

  @override
  String get failedToLoadAd => 'Failed to load ad. Please try again.';

  @override
  String get watchAdCompletely =>
      'Please watch the ad completely to earn reward.';

  @override
  String get premiumMember => 'You are a Premium Member!';

  @override
  String get renews => 'Renews:';

  @override
  String get switchToYearlyPlan => 'Switch to Yearly Plan';

  @override
  String get saveMoreBestValue => 'Save more with Best Value';

  @override
  String get premiumBenefits => 'Premium Benefits';

  @override
  String get noAds => 'No Ads';

  @override
  String get unlimitedQuiz => 'Unlimited Quiz';

  @override
  String get unlimitedFlashcards => 'Unlimited Flashcards';

  @override
  String get supportAppDevelopment => 'Support App Development';

  @override
  String get subscriptionPlans => 'Subscription Plans';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get bestValue => 'Best Value';

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get upgradeInitiated => 'Upgrade initiated...';

  @override
  String get failedToInitiateUpgrade => 'Failed to initiate upgrade';

  @override
  String get restoringPurchases => 'Restoring purchases...';

  @override
  String get noPurchasesFound => 'No purchases found';

  @override
  String get premium => 'Premium';

  @override
  String get unlimitedLearningAdFree => 'Unlimited Learning, Ad-Free';

  @override
  String get noAdsDescription =>
      'Remove all ads and learn without interruption';

  @override
  String get unlimitedQuizDescription => 'Play as many quizzes as you want';

  @override
  String get unlimitedFlashcardsDescription =>
      'Play unlimited flashcard sessions';

  @override
  String get supportAppDescription =>
      'Help us improve the Sign Language Dictionary';

  @override
  String get purchaseInitiated => 'Purchase initiated...';

  @override
  String get failedToInitiatePurchase => 'Failed to initiate purchase';

  @override
  String get yourProgress => 'Your Progress!';

  @override
  String learnedSignsThisMonth(int count) {
    return 'You\'ve learned $count signs this month!';
  }

  @override
  String get supportAppRemoveAds =>
      'Support the app & remove ads with Premium.';

  @override
  String get viewPremium => 'View Premium';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get appVersionTitle => 'App Version';

  @override
  String freeSessions(int remaining, int max) {
    return 'Free Session: $remaining / $max';
  }

  @override
  String get watchAdRestoreTokensButton => 'Watch Ad to add 3 tokens';

  @override
  String get googleSignUpCompleteSteps => 'Please complete the following steps';

  @override
  String get flashcardReviewExisting => 'Review Existing';

  @override
  String get delete => 'Delete';

  @override
  String get drawerAboutThisApp => 'About This App';

  @override
  String get aboutTitle => 'About This App';

  @override
  String get aboutSection1Title => 'About This App';

  @override
  String get aboutSection1Body =>
      'This app was created with a simple goal: to collect the signs most commonly used by deaf people in Bangladesh. It does not try to create or declare an official standard.\n\nIn Bangladesh there is not yet one national standard sign language. Different books, schools and communities use slightly different versions. That is why some words have more than one sign in this app.\n\nMany deaf people who are open to other cultures also start to use signs from other sign languages, such as Indian Sign Language (ISL) or American Sign Language (ASL). This app is only trying to reflect the real, living language that people actually use in daily life.\n\nWe hope this app will be useful and enjoyable for you.';

  @override
  String get aboutSection2Title => 'Vision for the Future';

  @override
  String get aboutSection2Body =>
      'Our ambition is to go further than a simple dictionary. Step by step we want to build a learning tool that helps you:\n\n• learn sign language in a clear, progressive way\n• track your progress over time\n• practice with exercises, games and small learning paths\n\nIn the future we also want to:\n\n• allow learners to connect with sign language teachers trained with our method\n• allow schools to use this app in the classroom\n• give teachers tools to see their students\' progress and which signs are difficult for them\n\nOur goal is to support individuals, families and schools who care about the deaf community in Bangladesh.';
}
