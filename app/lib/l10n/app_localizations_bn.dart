// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get loveToLearnSign => 'বাংলা ইশারা ভাষা';

  @override
  String get headlineSignLanguage => 'বাংলা ইশারা ভাষা';

  @override
  String get drawerMenu => 'মেনু';

  @override
  String get settings => 'সেটিংস';

  @override
  String get addWord => 'শব্দ যোগ';

  @override
  String get drawerLogin => 'লগইন';

  @override
  String get drawerLogout => 'লগআউট';

  @override
  String get logoutSuccess => 'লগআউট সম্পন্ন হয়েছে';

  @override
  String get play => 'শুরু';

  @override
  String get pause => 'বিরতি';

  @override
  String get share => 'শেয়ার';

  @override
  String get favorite => 'ফেভারিটে যোগ করুন';

  @override
  String get unfavorite => 'ফেভারিট থেকে সরিয়ে দিন';

  @override
  String get tabHome => 'হোম';

  @override
  String get tabDictionary => 'ডিকশনারি';

  @override
  String get tabGame => 'গেমস';

  @override
  String get settingsSectionLanguage => 'ভাষা';

  @override
  String get settingsLanguage => 'অ্যাপ ভাষা';

  @override
  String get english => 'ইংরেজি';

  @override
  String get bengali => 'বাংলা';

  @override
  String get settingsLanguageSubtitle => 'অ্যাপের ভাষা পরিবর্তন করুন';

  @override
  String get general => 'সাধারণ';

  @override
  String get darkMode => 'ডার্ক মোড';

  @override
  String get settingsSectionCachingOptions => 'ক্যাশিং অপশন';

  @override
  String get preloadVideosTitle => 'ক্যাটাগরি খোলার আগে ভিডিও লোড করুন';

  @override
  String get preloadVideosSubtitle =>
      'অপেক্ষার সময় কমাবে, তবে বেশি ডেটা ব্যবহার হবে';

  @override
  String get clearCachedVideosTitle => 'ক্যাশ ভিডিও মুছে ফেলুন';

  @override
  String get clearCachedVideosSubtitle => 'ক্যাশে সব ভিডিও মুছুন';

  @override
  String get dialogClearCacheTitle => 'ক্যাশ মুছে ফেলুন';

  @override
  String get dialogClearCacheContent => 'আপনি কি ক্যাশে ভিডিও মুছে ফেলতে চান?';

  @override
  String get snackbarCacheNotFound => '⚠️ ক্যাশ ডিরেক্টরি পাওয়া যায়নি।';

  @override
  String get snackbarCacheCleared => '✅ ক্যাশ সফলভাবে পরিষ্কার হয়েছে';

  @override
  String get maxCacheSizeTitle => 'সর্বোচ্চ ক্যাশ সাইজ';

  @override
  String get maxCacheSizeSubtitle =>
      'কত এমবি ক্যাশ ব্যবহার করবে তা নির্ধারণ করুন';

  @override
  String get cacheWifiTitle => 'শুধুমাত্র Wi-Fi এ ভিডিও ক্যাশ করুন';

  @override
  String get cacheWifiSubtitle =>
      'চালু থাকলে Wi-Fi এ সংযুক্ত থাকলে ব্যাকগ্রাউন্ডে ভিডিও ক্যাশিং হবে।';

  @override
  String get storageSectionTitle => 'স্টোরেজ';

  @override
  String currentCacheUsage(Object mb) {
    return 'বর্তমান ক্যাশ: $mb এমবি';
  }

  @override
  String get openSystemStorageSettings => 'সিস্টেম স্টোরেজ খুলুন';

  @override
  String get calculating => 'হিসাব হচ্ছে…';

  @override
  String get notificationNewWordsTitle => 'নতুন শব্দ যোগ হয়েছে';

  @override
  String get notificationNewWordsBody =>
      'ডিকশনারিতে নতুন শব্দ যোগ হয়েছে! তা দেখতে হোমপেজে যান।';

  @override
  String get settingsSectionNotifications => 'নোটিফিকেশন';

  @override
  String currentCacheTitle(String mb) {
    return 'বর্তমান ক্যাশ — $mb এমবি';
  }

  @override
  String get currentCacheSubtitle =>
      'ভিডিও এবং থাম্বনেল দ্রুত চালানোর জন্য স্থানীয়ভাবে সংরক্ষিত আনুমানিক সাইজ। পুনরায় গণনার জন্য রিফ্রেশ করুন।';

  @override
  String get notificationLearnWordTitle => 'আজ একটি সাইন শিখুন!';

  @override
  String get notificationLearnWordHelp =>
      'রিমাইন্ডার দেখতে না পেলে, অনুগ্রহ করে সিস্টেম সেটিংসে Love to Learn Sign অ্যাপের Notifications চালু করুন। কিছু Android ফোনে অ্যাপের জন্য battery optimization বন্ধ করতে / background activity অনুমতি দিতে হতে পারে।';

  @override
  String get notificationLearnWordTimeTitle => 'নোটিফিকেশন সময়';

  @override
  String get notificationCategoryTitle => 'বিভাগ বাছাই করুন';

  @override
  String notificationLearnWordBody(Object word) {
    return 'আপনি কি আজ নতুন শব্দ শিখেছেন? $word';
  }

  @override
  String get welcomeTitle => 'স্বাগতম';

  @override
  String get headlineTitle => 'Love to Learn Sign';

  @override
  String get favoritesVideos => 'ফেভারেট ভিডিও';

  @override
  String get noFavorites => 'কোনো ফেভারেট নেই';

  @override
  String get whatsNew => 'নতুন বিষয়';

  @override
  String get noNewVideos => 'কোনো নতুন ভিডিও যোগ হয়নি';

  @override
  String get learnAlso => 'আরও শিখুন';

  @override
  String get online => 'অনলাইন';

  @override
  String get website => 'ওয়েবসাইট';

  @override
  String get instagram => 'ইনস্টাগ্রাম';

  @override
  String get facebook => 'ফেসবুক';

  @override
  String get donation => 'ডোনেশন';

  @override
  String get contactUs => 'যোগাযোগ';

  @override
  String get removedFromFavorites => 'ফেভারিট থেকে সরানো হয়েছে';

  @override
  String get tabHistory => 'ইতিহাস';

  @override
  String get searchHint => 'ইংরেজি বা বাংলা দ্বারা সার্চ করুন';

  @override
  String get selectCategory => 'অথবা বিভাগ নির্বাচন করুন';

  @override
  String get allWords => 'সকল শব্দ';

  @override
  String get noResults => 'কোনো ফলাফল নেই';

  @override
  String get containerBText => 'একটি শব্দ খুজুন অথবা বিভাগ বাছাই করুন';

  @override
  String get noHistory => 'এখনও কোনো তথ্য নেই';

  @override
  String get clearHistoryTooltip => 'ইতিহাস মুছুন';

  @override
  String get chooseGame => 'গেম বাছাই করুন';

  @override
  String get donationErrorInvalidAmount => 'বৈধ পরিমাণ লিখুন অথবা বাছাই করুন';

  @override
  String get donationErrorSelectMethod => 'পেমেন্ট পদ্ধতি বাছাই করুন';

  @override
  String get donationErrorStripeCustomMonthly =>
      'স্ট্রাইপের জন্য পুনরাবৃত্ত কাস্টম অ্যামাউন্ট সমর্থিত না';

  @override
  String get donationErrorStripeCustom =>
      'স্ট্রাইপের জন্য জন্য কাস্টম অ্যামাউন্ট সমর্থিত না';

  @override
  String get donationBankTransferTitle => 'ব্যাংক ট্রান্সফার নির্দেশাবলী';

  @override
  String donationBankTransferContentWithAmount(Object amount) {
    return '$amount দানের জন্য ধন্যবাদ। অনুগ্রহ করে নিম্নলিখিত অ্যাকাউন্টে ট্রান্সফার করুন: অ্যাকাউন্ট হোল্ডার: আপনার নাম বা প্রতিষ্ঠান IBAN: XX00 0000 0000 0000 0000 BIC/SWIFT: ABCDUSXX রেফারেন্সে লিখুন “Donation $amount।”';
  }

  @override
  String get donationBankTransferContent =>
      'দানের ইচ্ছার জন্য ধন্যবাদ। অনুগ্রহ করে নিম্নলিখিত অ্যাকাউন্টে ট্রান্সফার করুনঃ অ্যাকাউন্ট হোল্ডার: আপনার নাম বা প্রতিষ্ঠান IBAN: XX00 0000 0000 0000 0000 BIC/SWIFT: ABCDUSXX রেফারেন্সে লিখুন “Donation”।';

  @override
  String get donationButton => 'দান করুন';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get cancel => 'বাতিল';

  @override
  String get flashcardGame => 'ফ্ল্যাশকার্ড';

  @override
  String get noVideo => 'কোন ভিডিও নেই';

  @override
  String get numberOfFlashcards => 'ফ্ল্যাশকার্ডের সংখ্যা';

  @override
  String get numberOfFlashcardsDesc => 'কতগুলো কার্ড পড়বেন তা বাছাই করুন';

  @override
  String get flashcardContent => 'ফ্ল্যাশকার্ডের বিষয়বস্তু';

  @override
  String get flashcardContentDesc => 'ফ্ল্যাশকার্ডের বিভাগ বাছাই করুন';

  @override
  String get flashcardStartingPointTitle => 'শুরুর ধরন';

  @override
  String get flashcardStartingPointDesc =>
      'ফ্ল্যাশকার্ডের সামনে কি দেখা যাবে তা বাছাই করুন।';

  @override
  String get flashcardStartingPointWord => 'একটি শব্দ';

  @override
  String get flashcardStartingPointSign => 'ইশারাভাষায় ভিডিও';

  @override
  String get quizCompleted => 'কুইজ সম্পন্ন';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get backToCategories => 'ক্যাটাগরিতে ফিরুন';

  @override
  String get backToGamePage => 'গেম পেজে ফিরুন';

  @override
  String get randomWordsQuiz => 'র‍্যান্ডম শব্দ';

  @override
  String get quizByCategory => 'বিভাগ অনুযায়ী কুইজ';

  @override
  String get questionPrompt => 'এই ইশারার মানে কী?';

  @override
  String get noWordsFound => 'এই বিভাগে কোনো শব্দ নেই';

  @override
  String get selectAnswerFirst => 'প্রথমে উত্তর বাছাই করুন';

  @override
  String get submit => 'সাবমিট';

  @override
  String get next => 'পরবর্তী';

  @override
  String shareText(Object score, Object total) {
    return 'সাইন ভাষার কুইজে $score/$total পেয়েছি! আপনি কি তা করতে পারবেন? Love to Learn Sign ডাউনলোড করুন: https://love2learnsign.com/download';
  }

  @override
  String get loginSuccess => 'সফলভাবে লগইন করেছেন';

  @override
  String get loginTitle => 'সাইন ইন';

  @override
  String get emailLabel => 'ইমেইল';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get passwordHelperText =>
      'কমপক্ষে ১২ অক্ষরের পাসওয়ার্ড দিন (বড় ও ছোট হাতের অক্ষর, সংখ্যা ও বিশেষ চিহ্নসহ)';

  @override
  String get passwordValidatorEmpty => 'অনুগ্রহ করে পাসওয়ার্ড লিখুন';

  @override
  String get passwordValidatorRequirements =>
      'পাসওয়ার্ড কমপক্ষে ১২ অক্ষরের হতে হবে এবং বড় ও ছোট হাতের অক্ষর, একটি সংখ্যা ও বিশেষ চিহ্ন থাকতে হবে';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get loginButton => 'সাইন ইন';

  @override
  String get resetPasswordSent =>
      'পাসওয়াার্ড রিসেটের নির্দেশনা ই-মেইলে চেক করুন';

  @override
  String get resetPasswordTitle => 'পাসওয়ার্ড রিসেট করুন';

  @override
  String get resetPasswordInstructions => 'ইমেইল লিখুন';

  @override
  String get validatorEnterEmail => 'অনুগ্রহ করে ই-মেইল লিখুন';

  @override
  String get validatorValidEmail => 'ভ্যালিড ই-মেইল লিখুন';

  @override
  String get resetPasswordButton => 'রিসেট লিঙ্ক পাঠান';

  @override
  String get chooseCategory => 'বিভাগ বাছাই করুন';

  @override
  String get errorPrefix => 'সমস্যা হয়েছে';

  @override
  String get noCategories => 'বিভাগ পাওয়া যায়নি।';

  @override
  String get infoMinimumCategories => 'বিভাগগুলো কমপক্ষে চারটি শব্দ দেখায়';

  @override
  String get reviewedModeTitle => 'ভুলগুলো পুনরায় দেখুন';

  @override
  String get reviewedModeSubtitle => 'কুইজ শেষে সব ভুল আবার দেখানো হবে।';

  @override
  String get speedModeTitle => 'সময়-ভিত্তিক উত্তর মোড';

  @override
  String get speedModeSubtitle => 'উত্তর দেওয়ার সময় সীমিত';

  @override
  String get timeLimitTitle => 'সময়সীমা';

  @override
  String get setTimeLimitTitle => 'সময়সীমা নির্দিষ্ট করুন';

  @override
  String get numberOfQuestions => 'প্রশ্নের সংখ্যা';

  @override
  String get setQuestionCountTitle => 'প্রশ্ন সংখ্যা বাছাই করুন';

  @override
  String get quizMessageLevel1 => 'চিন্তা করবেন না';

  @override
  String get quizMessageLevel2 => 'আপনি উন্নতি করছেন।';

  @override
  String get quizMessageLevel3 => 'ভালো চেষ্টা!';

  @override
  String get quizMessageLevel4 => 'সুন্দর!';

  @override
  String get quizMessageLevel5 => 'চমৎকার!';

  @override
  String quizTitleDynamic(Object category) {
    return 'কুইজঃ $category ';
  }

  @override
  String get notEnoughWords => 'এই বিভাগে পর্যাপ্ত শব্দ নেই।';

  @override
  String get timeUpMessage => 'সময় শেষ!';

  @override
  String questionProgress(Object current, Object total) {
    return '$current / $total প্রশ্ন';
  }

  @override
  String reviewedQuestionProgress(Object current) {
    return 'প্রশ্ন #$current দেখা হয়েছে';
  }

  @override
  String get activitiesAndHobbies => 'কার্যকলাপ ও শখ';

  @override
  String get adjectives => 'বিশেষণ';

  @override
  String get businessAndManagement => 'ব্যবসা ও ব্যবস্থাপনা';

  @override
  String get educationAndAcademia => 'শিক্ষা ও শিক্ষাজগৎ';

  @override
  String get familyAndRelationships => 'পরিবার ও সম্পর্ক';

  @override
  String get foodAndDrinks => 'খাবার ও পানীয়';

  @override
  String get geographyBangladesh => 'ভূগোল – বাংলাদেশ';

  @override
  String get geographyInternational => 'ভূগোল – আন্তর্জাতিক';

  @override
  String get health => 'স্বাস্থ্য';

  @override
  String get house => 'বাড়ি';

  @override
  String get languageBasics => 'ভাষার মূলনীতি';

  @override
  String get mediaAndCommunication => 'মিডিয়া ও যোগাযোগ';

  @override
  String get natureAndEnvironment => 'প্রকৃতি ও পরিবেশ';

  @override
  String get nouns => 'বিশেষ্য';

  @override
  String get technologyAndScience => 'প্রযুক্তি ও বিজ্ঞান';

  @override
  String get timeAndDates => 'সময় ও তারিখ';

  @override
  String get transport => 'পরিবহন';

  @override
  String get verbs => 'ক্রিয়া';

  @override
  String get reviewBox => 'রিভিউ বক্স';

  @override
  String get sortByDate => 'তারিখ';

  @override
  String get sortByVolume => 'শব্দের পরিমাণ';

  @override
  String get overdue => 'দেরি';

  @override
  String inDays(num days) {
    return '$days দিনে';
  }

  @override
  String get today => 'আজ';

  @override
  String signCount(num signCount) {
    String _temp0 = intl.Intl.pluralLogic(
      signCount,
      locale: localeName,
      other: 'সমূহ',
      one: '',
    );
    return 'সাইন$_temp0';
  }

  @override
  String get reviewNow => 'রিভিউ করুন';

  @override
  String signsToReview(num count, Object dayLabel) {
    return '$count সাইন — গুলো রিভিউ করুন $dayLabel';
  }

  @override
  String get howToReorderFavorites => 'ফেভারিট পুনরায় সাজানোর নিয়ম';

  @override
  String get longPressThumbnail => 'টেনে ধরতে থাম্বনেইলে লং-প্রেস করুন';

  @override
  String get dragLeftRight => '• বামে বা ডানে টেনে অবস্থান পরিবর্তন করুন।';

  @override
  String get releaseToDrop => '• ছেড়ে দিয়ে নতুন অর্ডার সেভ করুন';

  @override
  String get newFavoritesAdded => '• নতুন ফেভারিট সাধারণত শেষে যোগ হয়।';

  @override
  String get gotIt => 'বুঝেছি';

  @override
  String get randomAllCategories => 'র‍্যান্ডম ( সব ক্যাটাগরি )';

  @override
  String get wordsFromEntireDatabase => 'পুরো ডাটাবেস থেকে শব্দ';

  @override
  String get chooseQuizCategory => 'কুইজ ক্যাটাগরি বাছাই করুন';

  @override
  String get quizCategoriesInfo =>
      'কুইজ খেলার জন্য ক্যাটাগরিতে অন্তত ৪টি শব্দ থাকতে হবে।';

  @override
  String get quizGame => 'কুইজ';

  @override
  String get flashcardOptions => 'ফ্ল্যাশকার্ড অপশন';

  @override
  String get newFlashcardGame => 'নতুন ফ্ল্যাশকার্ড';

  @override
  String get flashcardMastered => 'দক্ষতা অর্জন করেছেন';

  @override
  String get flashcardToReview => 'রিভিশন';

  @override
  String get flashcardChooseReviewFrequency => 'রিভিয়ের হার বাছাই করুন';

  @override
  String flashcardDays(num days) {
    return '$days দিন';
  }

  @override
  String get flashcardCongratsTitle => 'অসাধারণ! 🎉';

  @override
  String flashcardSessionCompleted(Object count) {
    return 'আপনি $count টি ফ্ল্যাশকার্ড সম্পন্ন করেছেন!';
  }

  @override
  String get flashcardStatsMastered => '✅দক্ষতা অর্জন করেছেন';

  @override
  String get flashcardStatsToReview => '🔄 পরে দেখুন';

  @override
  String get flashcardStatsByFrequency => 'ফ্রিকোয়েন্সি অনুযায়ী রিভিউ:';

  @override
  String get flashcardFinish => 'শেষ';

  @override
  String get flashcardTapToFlip => 'ট্যাপ টু ফ্লিপ';

  @override
  String get onboardingIntroText =>
      'লাভ টু লার্ন সাইনে স্বাগতম! আমরা আনন্দিত যে আপনি অ্যাপটি ডাউনলোড করেছেন। আশা করি এটি আপনাকে বাংলা সাইন ল্যাঙ্গুয়েজ শিখতে সাহায্য করবে। শব্দ খোজা এবং গেমের মাধ্যমে ধাপে ধাপে শিখে, অনুশীলন করে উন্নতি করতে পারবেন। আপনি বধির হোন বা না হোন এই অ্যাপটি সবার সাইন ল্যাঙ্গুয়েজ জ্ঞ্যান ও আত্মবিশ্বাস বাড়াবে। আবারও স্বাগতম এবং সবচেয়ে গুরুত্বপূর্ণ বিষয় শেখার অভিজ্ঞতা উপভোগ করুন!';

  @override
  String get loadingNextQuestion => 'প্রশ্ন লোড হচ্ছে…';

  @override
  String get loadingQuizPleaseWait => 'কুইজ লোড হচ্ছে';

  @override
  String get privacySectionTitle => 'Legal & Privacy';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'Privacy Policy & Data Practices পড়ুন';

  @override
  String get privacyDialogIntro =>
      'Love to Learn Sign আপনার ব্যক্তিগত তথ্য ও গোপনীয়তাকে সম্মান নিশ্চিত করে';

  @override
  String get privacyDialogDataUsageTitle =>
      'আমাদের অ্যাপ ডেটা সংগ্রহ এবং ব্যবহার করে:';

  @override
  String get privacyDialogPointPersonalized =>
      '• ব্যক্তিগত শিক্ষার সুযোগ প্রদান করা';

  @override
  String get privacyDialogPointAccount =>
      '• অ্যাকাউন্ট পরিচালনা করুন (সাইন-ইন/সাইন-আপের জন্য ইমেইল)';

  @override
  String get privacyDialogPointPremium =>
      '• প্রিমিয়াম সাবস্ক্রিপশন প্রক্রিয়া করা (Google Play/App Store এর মাধ্যমে)';

  @override
  String get privacyDialogPointAds =>
      '• বিজ্ঞাপন প্রদর্শন করা (Google AdMob এর মাধ্যমে নন-প্রিমিয়াম ব্যবহারকারীদের জন্য)';

  @override
  String get privacyDialogPointReminders => '• প্রতিদিন রিমাইন্ডার পাঠান';

  @override
  String get privacyDialogPointCaching =>
      '• অফলাইনে দেখার জন্য ভিডিও কন্টেন্ট লোকালি সেভ করুন';

  @override
  String get privacyDialogPointTracking =>
      'ফিচার (ভিডিও ভিউ, গেম সেশন) উন্নত করতে অ্যাপ ব্যাবহার ট্র্যাক করুন';

  @override
  String get privacyDialogPointSearchAnalytics =>
      '• অভিধান সার্চের তথ্য নেওয়া হয় (শব্দ, বিভাগ, ফলাফলের সংখ্যা, পাওয়া/না-পাওয়া) যাতে নতুন কনটেন্ট উন্নত করা যায় — কোনো আইডি সংরক্ষণ করা হয় না';

  @override
  String get privacyDialogPointDemographic =>
      '• ডেমোগ্রাফিক তথ্য সংগ্রহ করা (শ্রবণ ক্ষমতা) যাতে আমাদের ব্যবহারকারীরা বেস বুঝতে পারে এবং বধির ও শ্রবণশক্তিসম্পন্ন উভয় শিক্ষার্থীদের জন্য কন্টেন্ট উন্নত করতে পারি';

  @override
  String get privacyDialogPointImprove => '• অ্যাপ ও তার বৈশিষ্ট্য উন্নত করা';

  @override
  String get privacyDialogThirdPartyTitle => 'তৃতীয় পক্ষের পরিষেবা:';

  @override
  String get privacyDialogThirdPartyFirebase =>
      '• Google Firebase - প্রমাণীকরণ, ডাটাবেস, বিশ্লেষণ';

  @override
  String get privacyDialogThirdPartyAdmob =>
      '• Google Mobile Ads (AdMob) - বিজ্ঞাপন প্রদর্শন ও ট্র্যাকিং';

  @override
  String get privacyDialogThirdPartyStores =>
      '• Google Play Store / Apple App Store - প্রিমিয়াম সাবস্ক্রিপশন পেমেন্ট';

  @override
  String get privacyDialogRightsTitle => 'আপনার অধিকার:';

  @override
  String get privacyDialogRightsAccess =>
      '• অ্যাপ সেটিংসের মাধ্যমে ডেটা অ্যাক্সেস, পরিবর্তন বা মুছে ফেলুন';

  @override
  String get privacyDialogRightsCancel =>
      '• স্টোর সেটিংসের মাধ্যমে প্রিমিয়াম সাবস্ক্রিপশন বাতিল করুন';

  @override
  String get privacyDialogRightsAds =>
      '• ব্যক্তিগত বিজ্ঞাপন এড়াতে Advertising ID রিসেট করুন';

  @override
  String get privacyDialogRightsDelete =>
      'যোগাযোগ করে ডেটা মুছে ফেলার আবেদন করুন';

  @override
  String get privacyDialogPremiumTitle => 'প্রিমিয়াম ব্যবহারকারী:';

  @override
  String get privacyDialogPremiumNoAds =>
      '• প্রিমিয়াম সাবস্ক্রিপশন সমস্ত বিজ্ঞাপন সরিয়ে দেয়';

  @override
  String get privacyDialogPremiumPayment =>
      'পেমেন্টের তথ্য প্ল্যাটফর্মে সুরক্ষিতভাবে প্রসেস করা হয়';

  @override
  String get privacyDialogPremiumNoCard => 'আপনার পেমেন্ট তথ্য আমরা রাখি না।';

  @override
  String get privacyDialogFullPolicy =>
      'সম্পূর্ণ Privacy Policy-র জন্য ওয়েবসাইটে যান:';

  @override
  String get privacyDialogContact => 'যোগাযোগ: info@netcreative-swas.net';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get flashcardReminderTitle => 'ফ্ল্যাশকার্ড রিভিউ';

  @override
  String get flashcardReminderTime => 'রিমাইন্ডারের সময়';

  @override
  String get administrationAndPublicServices => 'প্রশাসন ও জনসেবা';

  @override
  String get cultureAndIdentity => 'সংস্কৃতি ও পরিচয়';

  @override
  String get politicsAndSociety => 'রাজনীতি ও সমাজ';

  @override
  String get professionsAndOccupations => 'পেশা';

  @override
  String get religion => 'ধর্ম';

  @override
  String get jwOrganisation => 'যিহোবার সাক্ষিদের সংগঠন';

  @override
  String get biblicalContent => 'বাইবেলের বিষয়বস্তু';

  @override
  String get grammarAndBasics => 'ব্যাকরণ ও মূলনীতি';

  @override
  String get outdoorAndSports => 'আউটডোর ও স্পোর্টস';

  @override
  String get artsAndCrafts => 'শিল্পকলা';

  @override
  String get musicAndDance => 'সঙ্গীত ও নাচ';

  @override
  String get games => 'গেমস';

  @override
  String get homeAndHobbies => 'বাড়ি ও শখ';

  @override
  String get qualities => 'গুণাবলী';

  @override
  String get flawsAndWeaknesses => 'ত্রুটি ও দুর্বলতা';

  @override
  String get emotions => 'আবেগ';

  @override
  String get condition => 'অবস্থা';

  @override
  String get citizenServicesAndIds => 'নাগরিক সেবা ও আইডি';

  @override
  String get publicServicesAndFacilities => 'জনসেবা ও সুবিধা';

  @override
  String get governmentOfficesAndAuthorities => 'সরকারি অফিস ও কর্তৃপক্ষ';

  @override
  String get documentsAndLaw => 'ডকুমেন্ট ও আইন';

  @override
  String get planningAndOrganizing => 'পরিকল্পনা ও সংগঠন';

  @override
  String get moneyAndEconomy => 'টাকা-পয়সা ও অর্থনীতি';

  @override
  String get dealsAndContracts => 'চুক্তি ও লেনদেন';

  @override
  String get moneyAndAccounts => 'হিসাব-নিকাশ';

  @override
  String get operationsAndSupply => 'কার্যক্রম ও সরবরাহ';

  @override
  String get marketingAndSales => 'মার্কেটিং';

  @override
  String get peopleAndHr => 'জনশক্তি ও মানবসম্পদ ( HR )';

  @override
  String get languages => 'ভাষা';

  @override
  String get clothesAndDress => 'পোশাক';

  @override
  String get foodAndCooking => 'খাদ্য ও রান্না';

  @override
  String get traditionsAndFestivals => 'উৎসব ও রীতি-নীতি';

  @override
  String get artsAndHeritage => 'শিল্প-ঐতিহ্য';

  @override
  String get schoolsAndColleges => 'স্কুল-কলেজ';

  @override
  String get subjects => 'সাব্জেট';

  @override
  String get examsAndGrades => 'পরীক্ষা ও ফলাফল';

  @override
  String get classroomAndTools => 'ক্লাসরুম';

  @override
  String get researchAndPapers => 'গবেষণা';

  @override
  String get familyMembers => 'পরিবারের সদস্য';

  @override
  String get marriageAndInLaws => 'বিয়ে ও শ্বশুরবাড়ি';

  @override
  String get relationshipsAndStatus => 'সম্পর্ক ও সম্মান';

  @override
  String get ingredients => 'উপকরণ';

  @override
  String get dishes => 'খাবার';

  @override
  String get drinks => 'পানীয়';

  @override
  String get cookingAndTools => 'রান্না ও উপকরণ';

  @override
  String get eatingPlaces => 'খাওয়ার জায়গা';

  @override
  String get citiesAndDistricts => 'শহর ও জেলা';

  @override
  String get towns => 'শহর';

  @override
  String get neighborhoodsAndLocalities => 'মহল্লা ও এলাকা';

  @override
  String get institutionsAndFacilities => 'প্রতিষ্ঠান ও সুবিধা';

  @override
  String get countriesAndRegions => 'দেশ ও অঞ্চল';

  @override
  String get citiesAndCapitals => 'শহর ও রাজধানী';

  @override
  String get natureLandAndWater => 'প্রকৃতি';

  @override
  String get landmarks => 'বিখ্যাত স্থান';

  @override
  String get orgsAndCodes => 'সংস্থা ও কোড';

  @override
  String get body => 'শরীর';

  @override
  String get illnessAndSymptoms => 'রোগ ও লক্ষণ';

  @override
  String get careAndTreatment => 'যত্ন ও চিকিৎসা';

  @override
  String get medicineAndTools => 'ওষুধ ও চিকিৎসা সরঞ্জাম';

  @override
  String get fitnessAndDiet => 'ব্যায়াম ও খাদ্যাভ্যাস';

  @override
  String get rooms => 'কক্ষ';

  @override
  String get furniture => 'আসবাবপত্র';

  @override
  String get appliances => 'যন্ত্রপাতি';

  @override
  String get toolsAndRepair => 'সরঞ্জাম ও মেরামত';

  @override
  String get householdItems => 'বাসার জিনিসপত্র';

  @override
  String get alphabet => 'বর্ণমালা';

  @override
  String get numbers => 'সংখ্যা';

  @override
  String get personalPronoun => 'ব্যক্তিবাচক সর্বনাম';

  @override
  String get questionWords => 'প্রশ্নসূচক শব্দ';

  @override
  String get newsAndTvRadio => 'সংবাদ ও মাধ্যম';

  @override
  String get onlineAndWeb => 'অনলাইন ও ওয়েব';

  @override
  String get socialMedia => 'সোশ্যাল মিডিয়া';

  @override
  String get messagingAndCalls => 'মেসেজিং ও কল';

  @override
  String get mediaTypes => 'মিডিয়ার ধরন';

  @override
  String get devices => 'ডিভাইস';

  @override
  String get weatherAndSeasons => 'আবহাওয়া ও ঋতু';

  @override
  String get animals => 'প্রাণী';

  @override
  String get plants => 'উদ্ভিদ';

  @override
  String get placesAndHabitats => 'বাসস্থান';

  @override
  String get earthAndDisasters => 'পৃথিবী ও দুর্যোগ';

  @override
  String get people => 'জনগন';

  @override
  String get objects => 'বস্তু';

  @override
  String get abstractObjects => 'কল্পনার বস্তু';

  @override
  String get socialBehaviour => 'সামাজিক আচরণ';

  @override
  String get habits => 'অভ্যাস';

  @override
  String get politicalSystemAndElections => 'রাজনৈতিক ও নির্বাচন ব্যাবস্থা';

  @override
  String get ideologiesAndMovements => 'আন্দোলন';

  @override
  String get conflictsAndWars => 'সংঘাত ও যুদ্ধ';

  @override
  String get governanceAndPolicyDebate => 'নিয়ম ও শাসনব্যবস্থা আলাপ';

  @override
  String get socialIssuesAndCivilSociety => 'সামাজিক বিষয় ও সমাজ';

  @override
  String get publicServiceRoles => 'সরকারি পদ';

  @override
  String get businessRoles => 'ব্যবসায়িক পদ';

  @override
  String get educationAndKnowledgeRoles => 'শিক্ষা ও জ্ঞানের ভূমিকা';

  @override
  String get generalProfessions => 'সাধারণ পেশা';

  @override
  String get technicalJobs => 'প্রযুক্তিগত কাজ';

  @override
  String get beliefsAndPractices => 'বিশ্বাস ও রীতি';

  @override
  String get religiousPeople => 'মানুষ';

  @override
  String get religiousObjects => 'বস্তু';

  @override
  String get religiousPlaces => 'ধর্মীয় স্থান';

  @override
  String get festivals => 'উৎসব';

  @override
  String get concepts => 'ধারণা';

  @override
  String get communication => 'যোগাযোগ';

  @override
  String get cognition => 'চিন্তা-ভাবনা';

  @override
  String get emotionAndAttitude => 'আবেগ ও মনোভাব';

  @override
  String get perception => 'ধারণা';

  @override
  String get actionAndManipulation => 'কাজ ও পরিচালনা';

  @override
  String get movementAndPosture => 'চলাফেরা ও অঙ্গভঙ্গি';

  @override
  String get stateAndChange => 'পরিস্থিতি ও পরিবর্তন';

  @override
  String get devicesAndHardware => 'ডিভাইস ও হার্ডওয়্যার';

  @override
  String get softwareAndData => 'সফটওয়্যার ও ডেটা';

  @override
  String get internetAndNetworks => 'ইন্টারনেট ও নেটওয়ার্ক';

  @override
  String get engineeringAndMaking => 'ইঞ্জিনিয়ারিং';

  @override
  String get newTechAndAi => 'নতুন প্রযুক্তি ও এআই';

  @override
  String get calendar => 'ক্যালেন্ডার';

  @override
  String get dayAndTime => 'দিন ও সময়';

  @override
  String get schedules => 'সময়সূচি';

  @override
  String get frequencyAndDuration => 'সময় ও পুনরাবৃত্তি';

  @override
  String get vehicles => 'যানবাহন';

  @override
  String get places => 'স্থানসমূহ';

  @override
  String get travelAndTickets => 'ভ্রমণ';

  @override
  String get roadAndTraffic => 'সড়ক ও ট্রাফিক';

  @override
  String get responsibility => 'দায়িত্ব';

  @override
  String get publicationsAndMaterials => 'প্রকাশনা ও সামগ্রী';

  @override
  String get meetingsAndAssemblies => 'সভা-সমাবেশ';

  @override
  String get manualAndBibleUse => 'ম্যানুয়াল ও বাইবেল ব্যবহার';

  @override
  String get serviceAndMinistry => 'মন্ত্রণালয় ও সেবা';

  @override
  String get locations => 'জায়গা';

  @override
  String get bibleCharacters => 'বাইবেলের চরিত্রসমূহ';

  @override
  String get historicalOrPropheticEvents => 'ঐতিহাসিক ঘটনা বা ভবিষ্যদবাণী';

  @override
  String get booksOfTheBible => 'বাইবেলের বই';

  @override
  String get bibleTeaching => 'বাইবেলের শিক্ষা';

  @override
  String get biblicalSymbols => 'বাইবেলের প্রতীক';

  @override
  String get wantToLearn => 'আরও শিখুন';

  @override
  String get tryTheOpposite => 'বিপরীতটি শিখুন';

  @override
  String get signUpTitle => 'নিবন্ধন';

  @override
  String get displayNameLabel => 'প্রদর্শিত নাম';

  @override
  String get displayNameValidatorEmpty => 'অনুগ্রহ করে আপনার নাম লিখুন';

  @override
  String get displayNameValidatorMinLength => 'নাম কমপক্ষে ২ অক্ষরের হতে হবে';

  @override
  String get countryLabel => 'দেশ *';

  @override
  String get countryHelperText => 'অনুগ্রহ করে দেশ নির্বাচন করুন';

  @override
  String get countryValidatorEmpty => 'অনুগ্রহ করে দেশ নির্বাচন করুন';

  @override
  String get userTypeLabel => 'আমি';

  @override
  String get userTypeHelperText =>
      'দয়া করে বলুন, আপনি কি শ্রবণ প্রতিবন্ধী (বধির) নাকি শ্রবণক্ষম ব্যক্তি?';

  @override
  String get userTypeValidator =>
      'দয়া করে বাছাই করুন, আপনি কি শ্রবণ প্রতিবন্ধী (বধির) নাকি শ্রবণক্ষম ব্যক্তি?';

  @override
  String get userTypeOptionHearingImpaired => 'শ্রবণ প্রতিবন্ধী (বধির)';

  @override
  String get userTypeOptionHearing => 'শ্রবণশক্তিসম্পন্ন ব্যক্তি';

  @override
  String get confirmPasswordLabel => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get confirmPasswordValidatorEmpty =>
      'অনুগ্রহ করে পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get confirmPasswordValidatorMismatch => 'পাসওয়ার্ড মিলছে না';

  @override
  String get noteToAdministratorLabel =>
      'অ্যাডমিনিস্ট্রেটরের জন্য নোট (ঐচ্ছিক)';

  @override
  String get noteToAdministratorHint =>
      'অ্যাডমিনিস্ট্রেটরের জন্য বার্তা লিখুন (ঐচ্ছিক)';

  @override
  String get noteToAdministratorHelperText =>
      'অ্যাডমিনিস্ট্রেটরকে বলুন কেন আপনি যোগ দিতে চান (ঐচ্ছিক)';

  @override
  String get optionalLabel => 'ঐচ্ছিক';

  @override
  String get signUpButton => 'নিবন্ধন';

  @override
  String get alreadyHaveAccount => 'অ্যাকাউন্ট আছে? ';

  @override
  String get signInLink => 'সাইন ইন';

  @override
  String get passwordMismatchError => 'পাসওয়ার্ড মিলছে না';

  @override
  String get selectCountryError => 'অনুগ্রহ করে দেশ নির্বাচন করুন';

  @override
  String get captchaRequiredMessage =>
      'চালিয়ে যেতে নিরাপত্তা যাচাইকরণ সম্পূর্ণ করুন।';

  @override
  String get emailAlreadyExistsError => 'এই ইমেইলে অ্যাকাউন্ট ইতিমধ্যেই রয়েছে';

  @override
  String get dontHaveAccount => 'অ্যাকাউন্ট নেই? ';

  @override
  String get premiumSignInRequiredBody =>
      'প্রিমিয়াম কিনতে বা রিস্টোর করতে সাইন ইন করুন, যাতে এটি আপনার অ্যাকাউন্টের সাথে যুক্ত করা যায়।';

  @override
  String get newUserSignUp => 'নতুন ব্যবহারকারী? দয়া করে নিবন্ধন করুন';

  @override
  String get signUpLink => 'নিবন্ধন';

  @override
  String get signInWithGoogle => 'Google দিয়ে সাইন ইন করুন';

  @override
  String get signInWithApple => 'Apple দিয়ে সাইন ইন করুন';

  @override
  String get signUpWithGoogle => 'Google দিয়ে সাইন আপ করুন';

  @override
  String get approvingYourAccount => 'অ্যাকাউন্ট অনুমোদিত হচ্ছে...';

  @override
  String get emailVerifiedApprovedMessage =>
      'ই-মেইল যাচাই করা হয়েছে! আপনার অ্যাকাউন্ট অনুমোদিত। অনুগ্রহ করে সাইন ইন করুন।';

  @override
  String get accountPendingApprovalTitle => 'অ্যাকাউন্ট অনুমোদনের অপেক্ষায়';

  @override
  String get accountAwaitingApprovalHeadline =>
      'আপনার অ্যাকাউন্ট অনুমোদনের অপেক্ষায় রয়েছে';

  @override
  String get emailVerifiedSuccess => 'আপনার ইমেল সফলভাবে যাচাইকৃত হচ্ছে';

  @override
  String get accountPendingApprovalBody =>
      'আপনার ই-মেইল যাচাই করা হয়েছে। অ্যাকাউন্টটি এখন অ্যাডমিনিস্ট্রেটরের অনুমোদনের অপেক্ষায় রয়েছে। অ্যাডমিন অ্যাকাউন্ট অনুমোদন দিলে আপনি অ্যাক্সেস পাবেন।';

  @override
  String get accessAfterApproval => 'অনুমোদনের পর অ্যাক্সেস';

  @override
  String get whatHappensNext => 'এরপর কী হবে?';

  @override
  String get nextAdminReview =>
      'একজন অ্যাডমিনিস্ট্রেটর আপনার অ্যাকাউন্ট রিভিউ করবে';

  @override
  String get nextRoleAssignment => 'আপনাকে উপযুক্ত ভূমিকা দেওয়া হবে';

  @override
  String get nextAccessAfterApproved => 'আপনি অ্যাপের সম্পূর্ণ অ্যাক্সেস পাবেন';

  @override
  String get returnToApp => 'অ্যাপে ফিরে যান';

  @override
  String get verifyStatusError => 'যাচাইকরণ নির্ণয়ে সমস্যা';

  @override
  String get verifyEmailResentSuccess =>
      'যাচাইকরণ ই-মেইল সফলভাবে পুনরায় পাঠানো হয়েছে';

  @override
  String get verifyEmailResentError =>
      'যাচাইকরণ ই-মেইল পুনরায় পাঠাতে সমস্যা হয়েছে';

  @override
  String get verifyYourEmailTitle => 'ই-মেইল যাচাই করুন';

  @override
  String get verifyYourEmailHeadline => 'অনুগ্রহ করে আপনার ই-মেইল যাচাই করুন';

  @override
  String get verifyEmailSentTo => 'যাচাইকরণ ই-মেইল পাঠানো হয়েছে:';

  @override
  String get verifyEmailInfoHeader => 'আপনার ইনবক্স চেক করুন';

  @override
  String get verifyEmailInfoBody =>
      'আপনার ই-মেইলে একটি যাচাইকরণ লিঙ্ক পাঠানো হয়েছে। অনুগ্রহ করে আপনার ইনবক্স ( অথবা স্প্যাম ফোল্ডার) চেক করুন এবং অ্যাকাউন্ট যাচাই করতে লিঙ্কে ক্লিক করুন।';

  @override
  String get verifyEmailAutoRedirectHint =>
      'ই-মেইল যাচাইয়ের পর স্বয়ংক্রিয়ভাবে রিডাইরেক্ট হবেন।';

  @override
  String get sendingLabel => 'পাঠানো হচ্ছে...';

  @override
  String get resendVerificationEmail => 'যাচাইকরণ ই-মেইল পুনরায় পাঠান';

  @override
  String get checkingVerificationStatus => 'যাচাই করা হচ্ছে…';

  @override
  String get premiumSectionTitle => 'প্রিমিয়াম';

  @override
  String get upgradeToPremium => 'প্রিমিয়ামে আপগ্রেড করুন';

  @override
  String get removeAdsUnlimitedAccess =>
      'বিজ্ঞাপন সরান এবং আনলিমিটেড অ্যাক্সেস পান';

  @override
  String get removeAllAdsForever =>
      'প্রিমিয়ামে আপগ্রেড করে সমস্ত বিজ্ঞাপন সরিয়ে দিন';

  @override
  String get noThanks => 'না ধন্যবাদ';

  @override
  String get upgrade => 'আপগ্রেড';

  @override
  String get monthlyLimitReached => 'মাসিক সীমা অতিক্রম হয়েছে';

  @override
  String get quizLimitReachedMessage =>
      'আপনি এই মাসের ফ্রি কুইজ সেশন ব্যবহার করেছেন। (ছোট / সংক্ষিপ্ত) বিজ্ঞাপন দেখে 3টি কুইজ সেশন আনলক করুন।';

  @override
  String get flashcardLimitReachedMessage =>
      'আপনি এই মাসের ফ্রি ফ্ল্যাশকার্ড সেশন ব্যবহার করেছেন। (ছোট / সংক্ষিপ্ত) বিজ্ঞাপন দেখে 3টি ফ্ল্যাশকার্ড সেশন আনলক করুন।';

  @override
  String get goPremiumUnlimited => 'সীমাহীন শিক্ষার জন্য প্রিমিয়ামে যান';

  @override
  String get watchAd => 'বিজ্ঞাপন দেখুন';

  @override
  String get quizSessionsUnlocked =>
      '✅ 3টি অতিরিক্ত কুইজ সেশন আনলক করা হয়েছে!';

  @override
  String get flashcardSessionsUnlocked =>
      '✅ 3টি অতিরিক্ত ফ্ল্যাশকার্ড সেশন আনলক করা হয়েছে!';

  @override
  String get failedToLoadAd =>
      'বিজ্ঞাপন লোডে ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get watchAdCompletely => 'রিওয়ার্ড পেতে বিজ্ঞাপনটি সম্পূর্ণ দেখুন।';

  @override
  String get premiumMember => 'আপনি প্রিমিয়াম মেম্বার!';

  @override
  String get renews => 'রিনিউ তারিখ:';

  @override
  String get switchToYearlyPlan => 'বার্ষিক পরিকল্পনা পরিবর্তন করুন';

  @override
  String get saveMoreBestValue => 'সেরা মূল্যে আরও সঞ্চয় করুন';

  @override
  String get premiumBenefits => 'প্রিমিয়াম সুবিধাগুলো';

  @override
  String get noAds => 'কোন বিজ্ঞাপন নেই';

  @override
  String get unlimitedQuiz => 'আনলিমিটেড কুইজ';

  @override
  String get unlimitedFlashcards => 'আনলিমিটেড ফ্ল্যাশকার্ড';

  @override
  String get supportAppDevelopment => 'অ্যাপ উন্নয়ন সমর্থন করুন';

  @override
  String get subscriptionPlans => 'সাবস্ক্রিপশন পরিকল্পনা';

  @override
  String subscriptionAppliesToSelectedDictionary(String tenant) {
    return 'এই সাবস্ক্রিপশনটি নির্বাচিত অভিধানের জন্য প্রযোজ্য (tenant=$tenant)।';
  }

  @override
  String get monthly => 'মাসিক';

  @override
  String get yearly => 'বার্ষিক';

  @override
  String get bestValue => 'সেরা মূল্য';

  @override
  String get restorePurchase => 'ক্রয় পুনরুদ্ধার করুন';

  @override
  String get upgradeInitiated => 'আপগ্রেড হচ্ছে…';

  @override
  String get failedToInitiateUpgrade => 'আপগ্রেড করতে ব্যর্থ হয়েছে';

  @override
  String get restoringPurchases => 'ক্রয় পুনরুদ্ধার করা হচ্ছে...';

  @override
  String get noPurchasesFound => 'কোন ক্রয় পাওয়া যায়নি';

  @override
  String get premium => 'প্রিমিয়াম';

  @override
  String get unlimitedLearningAdFree => 'বিজ্ঞাপন ছাড়া আনলিমিটেড শিখুন';

  @override
  String get noAdsDescription => 'সমস্ত বিজ্ঞাপন সরিয়ে বাধাহীন শিখুন';

  @override
  String get unlimitedQuizDescription => 'যতবার খুশি কুইজ খেলুন';

  @override
  String get unlimitedFlashcardsDescription =>
      'যতবার খুশি ফ্ল্যাশকার্ড সেশন খেলুন';

  @override
  String get supportAppDescription =>
      'আমাদেরকে সাইন ল্যাঙ্গুয়েজ ডিকশনারি উন্নয়নে সাহায্য করুন';

  @override
  String get purchaseInitiated => 'ক্রয় শুরু হয়েছে...';

  @override
  String get failedToInitiatePurchase => 'ক্রয় ব্যর্থ হয়েছে';

  @override
  String get yourProgress => 'আপনার অগ্রগতি!';

  @override
  String learnedSignsThisMonth(int count) {
    return 'এই মাসে আপনি $countটি সাইন শিখেছেন!';
  }

  @override
  String get supportAppRemoveAds =>
      'প্রিমিয়ামে আপগ্রেড করার মাধ্যমে অ্যাপকে সমর্থন করুন এবং বিজ্ঞাপনগুলি সরান';

  @override
  String get viewPremium => 'প্রিমিয়াম প্ল্যান দেখুন';

  @override
  String get aboutSectionTitle => 'অ্যাপ সম্পর্কে';

  @override
  String get appVersionTitle => 'অ্যাপ ভার্সন';

  @override
  String freeSessions(int remaining, int max) {
    return 'ফ্রি সেশন: $remaining / $max';
  }

  @override
  String get watchAdRestoreTokensButton => '৩টি টোকেন পেতে বিজ্ঞাপন দেখুন';

  @override
  String get googleSignUpCompleteSteps =>
      'অনুগ্রহ করে নিম্নলিখিত ধাপগুলি সম্পন্ন করুন';

  @override
  String get flashcardReviewExisting => 'বিদ্যমান পর্যালোচনা';

  @override
  String get delete => 'মুছে ফেলুন';

  @override
  String get drawerAboutThisApp => 'অ্যাপ সম্বন্ধে';

  @override
  String get aboutTitle => 'অ্যাপ সম্বন্ধে';

  @override
  String get aboutSection1Title => 'অ্যাপ সম্বন্ধে';

  @override
  String get aboutSection1Body =>
      'অ্যাপটি তৈরি করার লক্ষ্য হল সাধারণ, সেটি হল বাংলাদেশে সবচেয়ে বেশি ব্যবহৃত সাইনগুলোকে একত্রিত করা। এই অ্যাপ কোনো অফিসিয়াল স্ট্যান্ডার্ড তৈরি বা ঘোষণা করার চেষ্টা করে না।\n\nযেহেতু বাংলাদেশে এখনো কোনো স্ট্যান্ডার্ড বা জাতীয় সাইন ল্যাঙ্গুয়েজ নাই, তাই বিভিন্ন বই, স্কুল ও কমিনিউটিতে ব্যবহৃত কিছু শব্দের ভিন্ন ভিন্ন একাধিক সাইন অ্যাপে রাখা হয়েছে।\n\nবাংলাদেশে অনেক বধির ব্যক্তি Indian Sign Language (ISL) বা American Sign Language (ASL)-এর মতো অন্যান্য সাইন ল্যাঙ্গুয়েজও ব্যবহার করেন। তাই, এই অ্যাপের উদ্দেশ্য হল মানুষের দৈনন্দিন জীবনে ব্যবহৃত জীবন্ত ভাষাকে যতটা সম্ভব সঠিকভাবে তুলে ধরা।\n\nআমরা আশা করি এই অ্যাপটি আপনার জন্য উপকারী ও আনন্দদায়ক হবে।';

  @override
  String get aboutSection2Title => 'ভবিষ্যৎ পরিকল্পনা';

  @override
  String get aboutSection2Body =>
      'আমাদের লক্ষ্য সাধারণ অভিধানেই না বরং এমন একটি পূর্ণাঙ্গ শেখার টুল তৈরি করা, যেটির মাধ্যমে আপনি ধাপে ধাপে এবং স্পষ্টভাবে সাইন ল্যাঙ্গুয়েজ শিখতে পারবেন, নিজের অগ্রগতি দেখা এবং বিভিন্ন অনুশীলন, গেম ও ধারাবাহিকভাবে শিখা।\n\nএই টুলটি আপনাকে সাহায্য করবে:\n\n• ধাপে ধাপে এবং স্পষ্টভাবে সাইন ল্যাঙ্গুয়েজ শিখতে\n• নিজের অগ্রগতি দেখতে/ট্র্যাক করতে\n• বিভিন্ন অনুশীলন ও গেমের মাধ্যমে প্র্যাকটিস করতে\n\nভবিষ্যতে আমরা আরও করতে চাই:\n\n• যারা শিখছে তাদেরকে প্রশিক্ষিত/অভিজ্ঞ সাইন ল্যাঙ্গুয়েজ শিক্ষকদের সাথে সংযুক্ত করা\n• বধির ব্যক্তিদের স্বাভাবিক উপায়ে ( যেমন বধির কমিউনিটিদের দ্বারা ব্যবহৃত নেটিভ সাইন স্ট্রাকচার, ভিজ্যুয়াল ব্যাকরণ এবং প্রচলিত স্বাভাবিক অভিব্যক্তি ) সাইন ল্যাঙ্গুয়েজের উপর ভিত্তি করে শেখানোর এক পদ্ধতি তৈরি করা\n• স্কুল ও টিচারদের এমন টুল দেওয়া, যাতে তারা তাদের শিক্ষার্থীদের অগ্রগতি দেখতে পারে এবং কোন কোন সাইন তাদের জন্য বেশ কঠিন তা বুঝতে পারে\n\nআমাদের লক্ষ্য হল এমন ব্যক্তি, পরিবার এবং স্কুলকে সমর্থন করা, যারা বাংলাদেশে বধির সম্প্রদায়কে নিয়ে কাজ/সাহায্য করে';

  @override
  String get processingPleaseWaitTitle => 'অনুগ্রহ করে অপেক্ষা করুন';

  @override
  String get processingWaitMessage =>
      'অনুগ্রহ করে অপেক্ষা করুন, প্রক্রিয়াকরণ চলছে…';

  @override
  String get processingTakingLongerMessage =>
      'স্বাভাবিকের চেয়ে বেশি সময় লাগছে। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get processingStillWorkingMessage =>
      'এখনও প্রক্রিয়াকরণ চলছে। আপনি স্ট্যাটাস রিফ্রেশ করতে পারেন, অথবা বন্ধ করে পরে আবার দেখে নিতে পারেন।';

  @override
  String get processingCreatingAccountTitle => 'আপনার অ্যাকাউন্ট তৈরি হচ্ছে…';

  @override
  String get processingCreatingAccountMessage =>
      'অনুগ্রহ করে অপেক্ষা করুন, আপনার অ্যাকাউন্ট তৈরি করা হচ্ছে…';

  @override
  String get processingSigningInTitle => 'লগইন হচ্ছে…';

  @override
  String get processingSigningInMessage =>
      'অনুগ্রহ করে অপেক্ষা করুন, লগইন করা হচ্ছে…';

  @override
  String get processingFinishingSetupTitle => 'সেটআপ সম্পন্ন হচ্ছে…';

  @override
  String get processingFinishingSetupMessage =>
      'অনুগ্রহ করে অপেক্ষা করুন, সেটআপ সম্পন্ন করা হচ্ছে…';

  @override
  String get processingPremiumActivatingTitle => 'প্রিমিয়াম সক্রিয় হচ্ছে…';

  @override
  String get processingPremiumActivatingMessage =>
      'অনুগ্রহ করে অপেক্ষা করুন, প্রক্রিয়াকরণ চলছে…';

  @override
  String get back => 'ফিরে যান';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get refresh => 'রিফ্রেশ';

  @override
  String get dashboardAccessSectionTitle => 'ড্যাশবোর্ড অ্যাক্সেস';

  @override
  String get dashboardAccessSetPasswordTitle =>
      'পাসওয়ার্ড সেট করুন (গুগল অ্যাকাউন্ট)';

  @override
  String get dashboardAccessSetPasswordSubtitle =>
      'ড্যাশবোর্ডে শুধু ইমেইল/পাসওয়ার্ড দিয়ে লগইন করা যায়। অ্যাক্সেস পেতে একটি পাসওয়ার্ড সেট করুন।';

  @override
  String get enableDashboardAccessTitle => 'ড্যাশবোর্ড অ্যাক্সেস সক্রিয় করুন';

  @override
  String dashboardAccessAccount(String email) {
    return 'অ্যাকাউন্ট: $email';
  }

  @override
  String get newPasswordLabel => 'নতুন পাসওয়ার্ড';

  @override
  String get dashboardAccessHelpText =>
      'পাসওয়ার্ড সেট করার পর, আপনি ড্যাশবোর্ডে ইমেইল + পাসওয়ার্ড দিয়ে সাইন ইন করতে পারবেন।';

  @override
  String get setPasswordButton => 'পাসওয়ার্ড সেট করুন';

  @override
  String get pleaseSignInFirst => 'প্রথমে সাইন ইন করুন।';

  @override
  String get noEmailFoundForAccount =>
      'এই অ্যাকাউন্টের জন্য কোনো ইমেইল পাওয়া যায়নি।';

  @override
  String get passwordMinLength8 => 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে।';

  @override
  String get passwordsDoNotMatch => 'পাসওয়ার্ড দুটি মেলেনি।';

  @override
  String get badgeLearner => 'শিক্ষার্থী';

  @override
  String get badgePremium => 'প্রিমিয়াম';

  @override
  String get badgeComplimentaryPremium => 'বিনামূল্যে\\nপ্রিমিয়াম';

  @override
  String get badgeJW => 'JW';

  @override
  String get badgeEditor => 'এডিটর';

  @override
  String get badgeAnalyst => 'অ্যানালিস্ট';

  @override
  String get badgeTenantAdmin => 'টেন্যান্ট অ্যাডমিন';

  @override
  String get badgeOwner => 'মালিক';
}
