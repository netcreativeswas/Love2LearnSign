import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @loveToLearnSign.
  ///
  /// In en, this message translates to:
  /// **'Bangla Sign Language'**
  String get loveToLearnSign;

  /// No description provided for @headlineSignLanguage.
  ///
  /// In en, this message translates to:
  /// **'Bangla Sign Language'**
  String get headlineSignLanguage;

  /// No description provided for @drawerMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get drawerMenu;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addWord.
  ///
  /// In en, this message translates to:
  /// **'Add a new word'**
  String get addWord;

  /// No description provided for @drawerLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get drawerLogin;

  /// No description provided for @drawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawerLogout;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have successfully logged out!'**
  String get logoutSuccess;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorite'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorite'**
  String get unfavorite;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabDictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get tabDictionary;

  /// No description provided for @tabGame.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get tabGame;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the app\'s language across all screens'**
  String get settingsLanguageSubtitle;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @settingsSectionCachingOptions.
  ///
  /// In en, this message translates to:
  /// **'Caching Options'**
  String get settingsSectionCachingOptions;

  /// No description provided for @preloadVideosTitle.
  ///
  /// In en, this message translates to:
  /// **'Preload videos when opening a category'**
  String get preloadVideosTitle;

  /// No description provided for @preloadVideosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This can reduce wait time but may use more data'**
  String get preloadVideosSubtitle;

  /// No description provided for @clearCachedVideosTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cached videos'**
  String get clearCachedVideosTitle;

  /// No description provided for @clearCachedVideosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloaded videos from cache'**
  String get clearCachedVideosSubtitle;

  /// No description provided for @dialogClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get dialogClearCacheTitle;

  /// No description provided for @dialogClearCacheContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all cached videos?'**
  String get dialogClearCacheContent;

  /// No description provided for @snackbarCacheNotFound.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Cache directory not found.'**
  String get snackbarCacheNotFound;

  /// No description provided for @snackbarCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'✅ Cache cleared successfully'**
  String get snackbarCacheCleared;

  /// No description provided for @maxCacheSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum cache size'**
  String get maxCacheSizeTitle;

  /// No description provided for @maxCacheSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set how much space the cache is allowed to use (in MB)'**
  String get maxCacheSizeSubtitle;

  /// No description provided for @cacheWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache videos only on Wi-Fi'**
  String get cacheWifiTitle;

  /// No description provided for @cacheWifiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When enabled, videos will be cached in the background only if the device is connected to Wi-Fi.'**
  String get cacheWifiSubtitle;

  /// No description provided for @storageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageSectionTitle;

  /// No description provided for @currentCacheUsage.
  ///
  /// In en, this message translates to:
  /// **'Current cache: {mb} MB'**
  String currentCacheUsage(Object mb);

  /// No description provided for @openSystemStorageSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system storage settings'**
  String get openSystemStorageSettings;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @notificationNewWordsTitle.
  ///
  /// In en, this message translates to:
  /// **'New words added'**
  String get notificationNewWordsTitle;

  /// No description provided for @notificationNewWordsBody.
  ///
  /// In en, this message translates to:
  /// **'New words added to the dictionary! Go to the app’s homepage to see what’s new.'**
  String get notificationNewWordsBody;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @currentCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Cache — {mb} MB'**
  String currentCacheTitle(String mb);

  /// No description provided for @currentCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approximate size of videos and thumbnails stored locally for faster playback. Tap refresh to recalculate.'**
  String get currentCacheSubtitle;

  /// No description provided for @notificationLearnWordTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn one sign today!'**
  String get notificationLearnWordTitle;

  /// No description provided for @notificationLearnWordHelp.
  ///
  /// In en, this message translates to:
  /// **'If you are unable to see the notification then please go to Settings > Apps > Special app access > Alarms & reminders and allow reminders for the Love to Learn Sign app.'**
  String get notificationLearnWordHelp;

  /// No description provided for @notificationLearnWordTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get notificationLearnWordTimeTitle;

  /// No description provided for @notificationCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get notificationCategoryTitle;

  /// No description provided for @notificationLearnWordBody.
  ///
  /// In en, this message translates to:
  /// **'Have you learned your new word today?\n{word}'**
  String notificationLearnWordBody(Object word);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @headlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Love to Learn Sign'**
  String get headlineTitle;

  /// No description provided for @favoritesVideos.
  ///
  /// In en, this message translates to:
  /// **'Favorite Videos'**
  String get favoritesVideos;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.'**
  String get noFavorites;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// No description provided for @noNewVideos.
  ///
  /// In en, this message translates to:
  /// **'No new videos recently.'**
  String get noNewVideos;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @donation.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donation;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by English or Bengali...'**
  String get searchHint;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Or select a category'**
  String get selectCategory;

  /// No description provided for @allWords.
  ///
  /// In en, this message translates to:
  /// **'All Words'**
  String get allWords;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @containerBText.
  ///
  /// In en, this message translates to:
  /// **'Search for a word or select a category'**
  String get containerBText;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get noHistory;

  /// No description provided for @clearHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryTooltip;

  /// No description provided for @chooseGame.
  ///
  /// In en, this message translates to:
  /// **'Choose a game'**
  String get chooseGame;

  /// No description provided for @donationErrorInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter or select a valid amount.'**
  String get donationErrorInvalidAmount;

  /// No description provided for @donationErrorSelectMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method.'**
  String get donationErrorSelectMethod;

  /// No description provided for @donationErrorStripeCustomMonthly.
  ///
  /// In en, this message translates to:
  /// **'Custom recurring amount not supported for Stripe.'**
  String get donationErrorStripeCustomMonthly;

  /// No description provided for @donationErrorStripeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom amount not supported for Stripe.'**
  String get donationErrorStripeCustom;

  /// No description provided for @donationBankTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer Instructions'**
  String get donationBankTransferTitle;

  /// No description provided for @donationBankTransferContentWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your willingness to donate {amount}.\n\nPlease transfer to:\nAccount holder: Your Name or Organization\nIBAN: XX00 0000 0000 0000 0000\nBIC/SWIFT: ABCDUSXX\n\nIn the reference, indicate \"Donation {amount}\".'**
  String donationBankTransferContentWithAmount(Object amount);

  /// No description provided for @donationBankTransferContent.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your willingness to donate.\n\nPlease transfer to:\nAccount holder: Your Name or Organization\nIBAN: XX00 0000 0000 0000 0000\nBIC/SWIFT: ABCDUSXX\n\nIn the reference, indicate \"Donation\".'**
  String get donationBankTransferContent;

  /// No description provided for @donationButton.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donationButton;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @flashcardGame.
  ///
  /// In en, this message translates to:
  /// **'Flashcard'**
  String get flashcardGame;

  /// No description provided for @noVideo.
  ///
  /// In en, this message translates to:
  /// **'No video available'**
  String get noVideo;

  /// No description provided for @numberOfFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Number of flashcards'**
  String get numberOfFlashcards;

  /// No description provided for @numberOfFlashcardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how many cards to study.'**
  String get numberOfFlashcardsDesc;

  /// No description provided for @flashcardContent.
  ///
  /// In en, this message translates to:
  /// **'Flashcard content'**
  String get flashcardContent;

  /// No description provided for @flashcardContentDesc.
  ///
  /// In en, this message translates to:
  /// **'Select which category the flashcards come from.'**
  String get flashcardContentDesc;

  /// No description provided for @flashcardStartingPointTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting side'**
  String get flashcardStartingPointTitle;

  /// No description provided for @flashcardStartingPointDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose what appears on the front of the card.'**
  String get flashcardStartingPointDesc;

  /// No description provided for @flashcardStartingPointWord.
  ///
  /// In en, this message translates to:
  /// **'A word'**
  String get flashcardStartingPointWord;

  /// No description provided for @flashcardStartingPointSign.
  ///
  /// In en, this message translates to:
  /// **'A sign language video'**
  String get flashcardStartingPointSign;

  /// No description provided for @quizCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quiz completed'**
  String get quizCompleted;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @backToCategories.
  ///
  /// In en, this message translates to:
  /// **'Back to categories'**
  String get backToCategories;

  /// No description provided for @backToGamePage.
  ///
  /// In en, this message translates to:
  /// **'Back to game page'**
  String get backToGamePage;

  /// No description provided for @randomWordsQuiz.
  ///
  /// In en, this message translates to:
  /// **'Random words'**
  String get randomWordsQuiz;

  /// No description provided for @quizByCategory.
  ///
  /// In en, this message translates to:
  /// **'Quiz by category'**
  String get quizByCategory;

  /// No description provided for @questionPrompt.
  ///
  /// In en, this message translates to:
  /// **'What does this sign mean?'**
  String get questionPrompt;

  /// No description provided for @noWordsFound.
  ///
  /// In en, this message translates to:
  /// **'No words found.'**
  String get noWordsFound;

  /// No description provided for @selectAnswerFirst.
  ///
  /// In en, this message translates to:
  /// **'Select your answer first'**
  String get selectAnswerFirst;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'I scored {score}/{total} in the sign language quiz! Can you beat me? Download Love to Learn Sign: https://love2learnsign.com/download'**
  String shareText(Object score, Object total);

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have successfully logged in!'**
  String get loginSuccess;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHelperText.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters with uppercase, lowercase, numbers, and symbols'**
  String get passwordHelperText;

  /// No description provided for @passwordValidatorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get passwordValidatorEmpty;

  /// No description provided for @passwordValidatorRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 12 characters and include uppercase, lowercase, a number, and a symbol'**
  String get passwordValidatorRequirements;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Please check your email for password reset instructions.'**
  String get resetPasswordSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email below'**
  String get resetPasswordInstructions;

  /// No description provided for @validatorEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validatorEnterEmail;

  /// No description provided for @validatorValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validatorValidEmail;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetPasswordButton;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get chooseCategory;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found.'**
  String get noCategories;

  /// No description provided for @infoMinimumCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories with at least 4 words are shown.'**
  String get infoMinimumCategories;

  /// No description provided for @reviewedModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviewed mode'**
  String get reviewedModeTitle;

  /// No description provided for @reviewedModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review wrong answers at the end.'**
  String get reviewedModeSubtitle;

  /// No description provided for @speedModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Timed answers mode'**
  String get speedModeTitle;

  /// No description provided for @speedModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have a time limit to answer.'**
  String get speedModeSubtitle;

  /// No description provided for @timeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get timeLimitTitle;

  /// No description provided for @setTimeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Set time limit'**
  String get setTimeLimitTitle;

  /// No description provided for @numberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get numberOfQuestions;

  /// No description provided for @setQuestionCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Set question count'**
  String get setQuestionCountTitle;

  /// No description provided for @quizMessageLevel1.
  ///
  /// In en, this message translates to:
  /// **'Oh no, don\'t worry.'**
  String get quizMessageLevel1;

  /// No description provided for @quizMessageLevel2.
  ///
  /// In en, this message translates to:
  /// **'You\'re improving.'**
  String get quizMessageLevel2;

  /// No description provided for @quizMessageLevel3.
  ///
  /// In en, this message translates to:
  /// **'Good try!'**
  String get quizMessageLevel3;

  /// No description provided for @quizMessageLevel4.
  ///
  /// In en, this message translates to:
  /// **'Nice job!'**
  String get quizMessageLevel4;

  /// No description provided for @quizMessageLevel5.
  ///
  /// In en, this message translates to:
  /// **'Excellent work!'**
  String get quizMessageLevel5;

  /// No description provided for @quizTitleDynamic.
  ///
  /// In en, this message translates to:
  /// **'Quiz: {category}'**
  String quizTitleDynamic(Object category);

  /// No description provided for @notEnoughWords.
  ///
  /// In en, this message translates to:
  /// **'Not enough words in this category.'**
  String get notEnoughWords;

  /// No description provided for @timeUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timeUpMessage;

  /// No description provided for @questionProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} questions'**
  String questionProgress(Object current, Object total);

  /// No description provided for @reviewedQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Reviewed question #{current}'**
  String reviewedQuestionProgress(Object current);

  /// No description provided for @activitiesAndHobbies.
  ///
  /// In en, this message translates to:
  /// **'Activities & Hobbies'**
  String get activitiesAndHobbies;

  /// No description provided for @adjectives.
  ///
  /// In en, this message translates to:
  /// **'Adjectives'**
  String get adjectives;

  /// No description provided for @businessAndManagement.
  ///
  /// In en, this message translates to:
  /// **'Business & Management'**
  String get businessAndManagement;

  /// No description provided for @educationAndAcademia.
  ///
  /// In en, this message translates to:
  /// **'Education & Academia'**
  String get educationAndAcademia;

  /// No description provided for @familyAndRelationships.
  ///
  /// In en, this message translates to:
  /// **'Family & Relationships'**
  String get familyAndRelationships;

  /// No description provided for @foodAndDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food & Drinks'**
  String get foodAndDrinks;

  /// No description provided for @geographyBangladesh.
  ///
  /// In en, this message translates to:
  /// **'Geography – Bangladesh'**
  String get geographyBangladesh;

  /// No description provided for @geographyInternational.
  ///
  /// In en, this message translates to:
  /// **'Geography – International'**
  String get geographyInternational;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @house.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get house;

  /// No description provided for @languageBasics.
  ///
  /// In en, this message translates to:
  /// **'Language Basics'**
  String get languageBasics;

  /// No description provided for @mediaAndCommunication.
  ///
  /// In en, this message translates to:
  /// **'Media & Communication'**
  String get mediaAndCommunication;

  /// No description provided for @natureAndEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Nature & Environment'**
  String get natureAndEnvironment;

  /// No description provided for @nouns.
  ///
  /// In en, this message translates to:
  /// **'Nouns'**
  String get nouns;

  /// No description provided for @technologyAndScience.
  ///
  /// In en, this message translates to:
  /// **'Technology & Science'**
  String get technologyAndScience;

  /// No description provided for @timeAndDates.
  ///
  /// In en, this message translates to:
  /// **'Time & Dates'**
  String get timeAndDates;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @verbs.
  ///
  /// In en, this message translates to:
  /// **'Verbs'**
  String get verbs;

  /// No description provided for @reviewBox.
  ///
  /// In en, this message translates to:
  /// **'Review Box'**
  String get reviewBox;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortByDate;

  /// No description provided for @sortByVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get sortByVolume;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get overdue;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} day{days, plural, =1{} other{s}}'**
  String inDays(num days);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @signCount.
  ///
  /// In en, this message translates to:
  /// **'Sign{signCount, plural, =1{} other{s}}'**
  String signCount(num signCount);

  /// No description provided for @reviewNow.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get reviewNow;

  /// No description provided for @signsToReview.
  ///
  /// In en, this message translates to:
  /// **'{count} sign{count, plural, =1{} other{s}} to review — {dayLabel}'**
  String signsToReview(num count, Object dayLabel);

  /// No description provided for @howToReorderFavorites.
  ///
  /// In en, this message translates to:
  /// **'How to reorder favorites'**
  String get howToReorderFavorites;

  /// No description provided for @longPressThumbnail.
  ///
  /// In en, this message translates to:
  /// **'• Long-press a thumbnail to start dragging.'**
  String get longPressThumbnail;

  /// No description provided for @dragLeftRight.
  ///
  /// In en, this message translates to:
  /// **'• Drag left or right to change its position.'**
  String get dragLeftRight;

  /// No description provided for @releaseToDrop.
  ///
  /// In en, this message translates to:
  /// **'• Release to drop and save the new order.'**
  String get releaseToDrop;

  /// No description provided for @newFavoritesAdded.
  ///
  /// In en, this message translates to:
  /// **'• New favorites are added at the end by default.'**
  String get newFavoritesAdded;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @randomAllCategories.
  ///
  /// In en, this message translates to:
  /// **'Random (all categories)'**
  String get randomAllCategories;

  /// No description provided for @wordsFromEntireDatabase.
  ///
  /// In en, this message translates to:
  /// **'Words from the entire database'**
  String get wordsFromEntireDatabase;

  /// No description provided for @chooseQuizCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose Quiz Category'**
  String get chooseQuizCategory;

  /// No description provided for @quizCategoriesInfo.
  ///
  /// In en, this message translates to:
  /// **'Categories must have at least 4 words to be playable.'**
  String get quizCategoriesInfo;

  /// No description provided for @quizGame.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizGame;

  /// No description provided for @flashcardOptions.
  ///
  /// In en, this message translates to:
  /// **'Flashcard Options'**
  String get flashcardOptions;

  /// No description provided for @newFlashcardGame.
  ///
  /// In en, this message translates to:
  /// **'New Flashcard Game'**
  String get newFlashcardGame;

  /// No description provided for @flashcardMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get flashcardMastered;

  /// No description provided for @flashcardToReview.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get flashcardToReview;

  /// No description provided for @flashcardChooseReviewFrequency.
  ///
  /// In en, this message translates to:
  /// **'Choose review frequency:'**
  String get flashcardChooseReviewFrequency;

  /// No description provided for @flashcardDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day{days, plural, =1{} other{s}}'**
  String flashcardDays(num days);

  /// No description provided for @flashcardCongratsTitle.
  ///
  /// In en, this message translates to:
  /// **'Great job! 🎉'**
  String get flashcardCongratsTitle;

  /// No description provided for @flashcardSessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'You’ve completed your {count} flashcards!'**
  String flashcardSessionCompleted(Object count);

  /// No description provided for @flashcardStatsMastered.
  ///
  /// In en, this message translates to:
  /// **'✅ Mastered'**
  String get flashcardStatsMastered;

  /// No description provided for @flashcardStatsToReview.
  ///
  /// In en, this message translates to:
  /// **'🔄 To review'**
  String get flashcardStatsToReview;

  /// No description provided for @flashcardStatsByFrequency.
  ///
  /// In en, this message translates to:
  /// **'Words to review by frequency:'**
  String get flashcardStatsByFrequency;

  /// No description provided for @flashcardFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get flashcardFinish;

  /// No description provided for @flashcardTapToFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap to flip'**
  String get flashcardTapToFlip;

  /// No description provided for @onboardingIntroText.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Love to Learn Sign app!\nWe\'re excited that you\'ve downloaded the app, and we hope it becomes a valuable tool for your journey in learning Bangla Sign Language.\n\nThrough word searches and interactive games, you\'ll be able to learn step by step, practice, and make real progress. Whether you are hearing or deaf, this app is designed to help you grow in your knowledge and confidence in sign language.\n\nOnce again, welcome aboard — and most importantly, enjoy the experience while you learn!'**
  String get onboardingIntroText;

  /// No description provided for @loadingNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Loading next question...'**
  String get loadingNextQuestion;

  /// No description provided for @loadingQuizPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Loading the quiz, please wait...'**
  String get loadingQuizPleaseWait;

  /// No description provided for @privacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get privacySectionTitle;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy and data practices'**
  String get privacyPolicySubtitle;

  /// No description provided for @privacyDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'Love to Learn Sign respects your privacy and is committed to protecting your personal information.'**
  String get privacyDialogIntro;

  /// No description provided for @privacyDialogDataUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Our app collects and uses data to:'**
  String get privacyDialogDataUsageTitle;

  /// No description provided for @privacyDialogPointPersonalized.
  ///
  /// In en, this message translates to:
  /// **'• Provide personalized learning experience'**
  String get privacyDialogPointPersonalized;

  /// No description provided for @privacyDialogPointAccount.
  ///
  /// In en, this message translates to:
  /// **'• Manage user accounts (email for sign-in/sign-up)'**
  String get privacyDialogPointAccount;

  /// No description provided for @privacyDialogPointPremium.
  ///
  /// In en, this message translates to:
  /// **'• Process premium subscriptions (via Google Play/App Store)'**
  String get privacyDialogPointPremium;

  /// No description provided for @privacyDialogPointAds.
  ///
  /// In en, this message translates to:
  /// **'• Display advertisements (for non-premium users via Google AdMob)'**
  String get privacyDialogPointAds;

  /// No description provided for @privacyDialogPointReminders.
  ///
  /// In en, this message translates to:
  /// **'• Send daily reminder notifications'**
  String get privacyDialogPointReminders;

  /// No description provided for @privacyDialogPointCaching.
  ///
  /// In en, this message translates to:
  /// **'• Store video content locally for offline access'**
  String get privacyDialogPointCaching;

  /// No description provided for @privacyDialogPointTracking.
  ///
  /// In en, this message translates to:
  /// **'• Track usage (video views, game sessions) to improve features'**
  String get privacyDialogPointTracking;

  /// No description provided for @privacyDialogPointSearchAnalytics.
  ///
  /// In en, this message translates to:
  /// **'• Log anonymous dictionary search analytics (query text, category, result count, found/missing) to improve content — no user IDs are stored'**
  String get privacyDialogPointSearchAnalytics;

  /// No description provided for @privacyDialogPointDemographic.
  ///
  /// In en, this message translates to:
  /// **'• Collect demographic information (hearing status) to understand our user base and improve content for both deaf and hearing learners'**
  String get privacyDialogPointDemographic;

  /// No description provided for @privacyDialogPointImprove.
  ///
  /// In en, this message translates to:
  /// **'• Improve app performance and features'**
  String get privacyDialogPointImprove;

  /// No description provided for @privacyDialogThirdPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Third-Party Services:'**
  String get privacyDialogThirdPartyTitle;

  /// No description provided for @privacyDialogThirdPartyFirebase.
  ///
  /// In en, this message translates to:
  /// **'• Google Firebase - Authentication, database, analytics'**
  String get privacyDialogThirdPartyFirebase;

  /// No description provided for @privacyDialogThirdPartyAdmob.
  ///
  /// In en, this message translates to:
  /// **'• Google Mobile Ads (AdMob) - Advertisement display and tracking'**
  String get privacyDialogThirdPartyAdmob;

  /// No description provided for @privacyDialogThirdPartyStores.
  ///
  /// In en, this message translates to:
  /// **'• Google Play Store / Apple App Store - Premium subscription payments'**
  String get privacyDialogThirdPartyStores;

  /// No description provided for @privacyDialogRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Rights:'**
  String get privacyDialogRightsTitle;

  /// No description provided for @privacyDialogRightsAccess.
  ///
  /// In en, this message translates to:
  /// **'• Access, modify, or delete your data through app settings'**
  String get privacyDialogRightsAccess;

  /// No description provided for @privacyDialogRightsCancel.
  ///
  /// In en, this message translates to:
  /// **'• Cancel premium subscriptions through store settings'**
  String get privacyDialogRightsCancel;

  /// No description provided for @privacyDialogRightsAds.
  ///
  /// In en, this message translates to:
  /// **'• Reset Advertising ID to opt-out of personalized ads'**
  String get privacyDialogRightsAds;

  /// No description provided for @privacyDialogRightsDelete.
  ///
  /// In en, this message translates to:
  /// **'• Request data deletion by contacting us'**
  String get privacyDialogRightsDelete;

  /// No description provided for @privacyDialogPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Users:'**
  String get privacyDialogPremiumTitle;

  /// No description provided for @privacyDialogPremiumNoAds.
  ///
  /// In en, this message translates to:
  /// **'• Premium subscriptions remove all advertisements'**
  String get privacyDialogPremiumNoAds;

  /// No description provided for @privacyDialogPremiumPayment.
  ///
  /// In en, this message translates to:
  /// **'• Payment data is processed securely by store platforms'**
  String get privacyDialogPremiumPayment;

  /// No description provided for @privacyDialogPremiumNoCard.
  ///
  /// In en, this message translates to:
  /// **'• We do not store your payment card information'**
  String get privacyDialogPremiumNoCard;

  /// No description provided for @privacyDialogFullPolicy.
  ///
  /// In en, this message translates to:
  /// **'For the complete privacy policy, visit our website:'**
  String get privacyDialogFullPolicy;

  /// No description provided for @privacyDialogContact.
  ///
  /// In en, this message translates to:
  /// **'Contact: info@netcreative-swas.net'**
  String get privacyDialogContact;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @flashcardReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Flashcard review reminders'**
  String get flashcardReminderTitle;

  /// No description provided for @flashcardReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get flashcardReminderTime;

  /// No description provided for @administrationAndPublicServices.
  ///
  /// In en, this message translates to:
  /// **'Administration & Public Services'**
  String get administrationAndPublicServices;

  /// No description provided for @cultureAndIdentity.
  ///
  /// In en, this message translates to:
  /// **'Culture & Identity'**
  String get cultureAndIdentity;

  /// No description provided for @politicsAndSociety.
  ///
  /// In en, this message translates to:
  /// **'Politics & Society'**
  String get politicsAndSociety;

  /// No description provided for @professionsAndOccupations.
  ///
  /// In en, this message translates to:
  /// **'Professions & Occupations'**
  String get professionsAndOccupations;

  /// No description provided for @religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religion;

  /// No description provided for @jwOrganisation.
  ///
  /// In en, this message translates to:
  /// **'JW Organisation'**
  String get jwOrganisation;

  /// No description provided for @biblicalContent.
  ///
  /// In en, this message translates to:
  /// **'Biblical Content'**
  String get biblicalContent;

  /// No description provided for @grammarAndBasics.
  ///
  /// In en, this message translates to:
  /// **'Grammar & Basics'**
  String get grammarAndBasics;

  /// No description provided for @outdoorAndSports.
  ///
  /// In en, this message translates to:
  /// **'Outdoor & Sports'**
  String get outdoorAndSports;

  /// No description provided for @artsAndCrafts.
  ///
  /// In en, this message translates to:
  /// **'Arts & Crafts'**
  String get artsAndCrafts;

  /// No description provided for @musicAndDance.
  ///
  /// In en, this message translates to:
  /// **'Music & Dance'**
  String get musicAndDance;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @homeAndHobbies.
  ///
  /// In en, this message translates to:
  /// **'Home & Hobbies'**
  String get homeAndHobbies;

  /// No description provided for @qualities.
  ///
  /// In en, this message translates to:
  /// **'Qualities'**
  String get qualities;

  /// No description provided for @flawsAndWeaknesses.
  ///
  /// In en, this message translates to:
  /// **'Flaws & Weaknesses'**
  String get flawsAndWeaknesses;

  /// No description provided for @emotions.
  ///
  /// In en, this message translates to:
  /// **'Emotions'**
  String get emotions;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @citizenServicesAndIds.
  ///
  /// In en, this message translates to:
  /// **'Citizen Services & IDs'**
  String get citizenServicesAndIds;

  /// No description provided for @publicServicesAndFacilities.
  ///
  /// In en, this message translates to:
  /// **'Public Services & Facilities'**
  String get publicServicesAndFacilities;

  /// No description provided for @governmentOfficesAndAuthorities.
  ///
  /// In en, this message translates to:
  /// **'Government Offices & Authorities'**
  String get governmentOfficesAndAuthorities;

  /// No description provided for @documentsAndLaw.
  ///
  /// In en, this message translates to:
  /// **'Documents & Law'**
  String get documentsAndLaw;

  /// No description provided for @planningAndOrganizing.
  ///
  /// In en, this message translates to:
  /// **'Planning & Organizing'**
  String get planningAndOrganizing;

  /// No description provided for @moneyAndEconomy.
  ///
  /// In en, this message translates to:
  /// **'Money & Economy'**
  String get moneyAndEconomy;

  /// No description provided for @dealsAndContracts.
  ///
  /// In en, this message translates to:
  /// **'Deals & Contracts'**
  String get dealsAndContracts;

  /// No description provided for @moneyAndAccounts.
  ///
  /// In en, this message translates to:
  /// **'Money & Accounts'**
  String get moneyAndAccounts;

  /// No description provided for @operationsAndSupply.
  ///
  /// In en, this message translates to:
  /// **'Operations & Supply'**
  String get operationsAndSupply;

  /// No description provided for @marketingAndSales.
  ///
  /// In en, this message translates to:
  /// **'Marketing & Sales'**
  String get marketingAndSales;

  /// No description provided for @peopleAndHr.
  ///
  /// In en, this message translates to:
  /// **'People & HR'**
  String get peopleAndHr;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @clothesAndDress.
  ///
  /// In en, this message translates to:
  /// **'Clothes & Dress'**
  String get clothesAndDress;

  /// No description provided for @foodAndCooking.
  ///
  /// In en, this message translates to:
  /// **'Food & Cooking'**
  String get foodAndCooking;

  /// No description provided for @traditionsAndFestivals.
  ///
  /// In en, this message translates to:
  /// **'Traditions & Festivals'**
  String get traditionsAndFestivals;

  /// No description provided for @artsAndHeritage.
  ///
  /// In en, this message translates to:
  /// **'Arts & Heritage'**
  String get artsAndHeritage;

  /// No description provided for @schoolsAndColleges.
  ///
  /// In en, this message translates to:
  /// **'Schools & Colleges'**
  String get schoolsAndColleges;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @examsAndGrades.
  ///
  /// In en, this message translates to:
  /// **'Exams & Grades'**
  String get examsAndGrades;

  /// No description provided for @classroomAndTools.
  ///
  /// In en, this message translates to:
  /// **'Classroom & Tools'**
  String get classroomAndTools;

  /// No description provided for @researchAndPapers.
  ///
  /// In en, this message translates to:
  /// **'Research & Papers'**
  String get researchAndPapers;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembers;

  /// No description provided for @marriageAndInLaws.
  ///
  /// In en, this message translates to:
  /// **'Marriage & In-Laws'**
  String get marriageAndInLaws;

  /// No description provided for @relationshipsAndStatus.
  ///
  /// In en, this message translates to:
  /// **'Relationships & Status'**
  String get relationshipsAndStatus;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @dishes.
  ///
  /// In en, this message translates to:
  /// **'Dishes'**
  String get dishes;

  /// No description provided for @drinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get drinks;

  /// No description provided for @cookingAndTools.
  ///
  /// In en, this message translates to:
  /// **'Cooking & Tools'**
  String get cookingAndTools;

  /// No description provided for @eatingPlaces.
  ///
  /// In en, this message translates to:
  /// **'Eating Places'**
  String get eatingPlaces;

  /// No description provided for @citiesAndDistricts.
  ///
  /// In en, this message translates to:
  /// **'Cities & Districts'**
  String get citiesAndDistricts;

  /// No description provided for @towns.
  ///
  /// In en, this message translates to:
  /// **'Towns'**
  String get towns;

  /// No description provided for @neighborhoodsAndLocalities.
  ///
  /// In en, this message translates to:
  /// **'Neighborhoods & Localities'**
  String get neighborhoodsAndLocalities;

  /// No description provided for @institutionsAndFacilities.
  ///
  /// In en, this message translates to:
  /// **'Institutions & Facilities'**
  String get institutionsAndFacilities;

  /// No description provided for @countriesAndRegions.
  ///
  /// In en, this message translates to:
  /// **'Countries & Regions'**
  String get countriesAndRegions;

  /// No description provided for @citiesAndCapitals.
  ///
  /// In en, this message translates to:
  /// **'Cities & Capitals'**
  String get citiesAndCapitals;

  /// No description provided for @natureLandAndWater.
  ///
  /// In en, this message translates to:
  /// **'Nature (Land & Water)'**
  String get natureLandAndWater;

  /// No description provided for @landmarks.
  ///
  /// In en, this message translates to:
  /// **'Landmarks'**
  String get landmarks;

  /// No description provided for @orgsAndCodes.
  ///
  /// In en, this message translates to:
  /// **'Orgs & Codes'**
  String get orgsAndCodes;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get body;

  /// No description provided for @illnessAndSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Illness & Symptoms'**
  String get illnessAndSymptoms;

  /// No description provided for @careAndTreatment.
  ///
  /// In en, this message translates to:
  /// **'Care & Treatment'**
  String get careAndTreatment;

  /// No description provided for @medicineAndTools.
  ///
  /// In en, this message translates to:
  /// **'Medicine & Tools'**
  String get medicineAndTools;

  /// No description provided for @fitnessAndDiet.
  ///
  /// In en, this message translates to:
  /// **'Fitness & Diet'**
  String get fitnessAndDiet;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @furniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get furniture;

  /// No description provided for @appliances.
  ///
  /// In en, this message translates to:
  /// **'Appliances'**
  String get appliances;

  /// No description provided for @toolsAndRepair.
  ///
  /// In en, this message translates to:
  /// **'Tools & Repair'**
  String get toolsAndRepair;

  /// No description provided for @householdItems.
  ///
  /// In en, this message translates to:
  /// **'Household Items'**
  String get householdItems;

  /// No description provided for @alphabet.
  ///
  /// In en, this message translates to:
  /// **'Alphabet'**
  String get alphabet;

  /// No description provided for @numbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get numbers;

  /// No description provided for @personalPronoun.
  ///
  /// In en, this message translates to:
  /// **'Personal Pronouns'**
  String get personalPronoun;

  /// No description provided for @questionWords.
  ///
  /// In en, this message translates to:
  /// **'Question Words'**
  String get questionWords;

  /// No description provided for @newsAndTvRadio.
  ///
  /// In en, this message translates to:
  /// **'News & TV/Radio'**
  String get newsAndTvRadio;

  /// No description provided for @onlineAndWeb.
  ///
  /// In en, this message translates to:
  /// **'Online & Web'**
  String get onlineAndWeb;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @messagingAndCalls.
  ///
  /// In en, this message translates to:
  /// **'Messaging & Calls'**
  String get messagingAndCalls;

  /// No description provided for @mediaTypes.
  ///
  /// In en, this message translates to:
  /// **'Media Types'**
  String get mediaTypes;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @weatherAndSeasons.
  ///
  /// In en, this message translates to:
  /// **'Weather & Seasons'**
  String get weatherAndSeasons;

  /// No description provided for @animals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get animals;

  /// No description provided for @plants.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get plants;

  /// No description provided for @placesAndHabitats.
  ///
  /// In en, this message translates to:
  /// **'Places & Habitats'**
  String get placesAndHabitats;

  /// No description provided for @earthAndDisasters.
  ///
  /// In en, this message translates to:
  /// **'Earth & Disasters'**
  String get earthAndDisasters;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @objects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get objects;

  /// No description provided for @abstractObjects.
  ///
  /// In en, this message translates to:
  /// **'Abstract Objects'**
  String get abstractObjects;

  /// No description provided for @socialBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Social Behaviour'**
  String get socialBehaviour;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @politicalSystemAndElections.
  ///
  /// In en, this message translates to:
  /// **'Political System & Elections'**
  String get politicalSystemAndElections;

  /// No description provided for @ideologiesAndMovements.
  ///
  /// In en, this message translates to:
  /// **'Ideologies & Movements'**
  String get ideologiesAndMovements;

  /// No description provided for @conflictsAndWars.
  ///
  /// In en, this message translates to:
  /// **'Conflicts & Wars'**
  String get conflictsAndWars;

  /// No description provided for @governanceAndPolicyDebate.
  ///
  /// In en, this message translates to:
  /// **'Governance & Policy Debate'**
  String get governanceAndPolicyDebate;

  /// No description provided for @socialIssuesAndCivilSociety.
  ///
  /// In en, this message translates to:
  /// **'Social Issues & Civil Society'**
  String get socialIssuesAndCivilSociety;

  /// No description provided for @publicServiceRoles.
  ///
  /// In en, this message translates to:
  /// **'Public Service Roles'**
  String get publicServiceRoles;

  /// No description provided for @businessRoles.
  ///
  /// In en, this message translates to:
  /// **'Business Roles'**
  String get businessRoles;

  /// No description provided for @educationAndKnowledgeRoles.
  ///
  /// In en, this message translates to:
  /// **'Education & Knowledge Roles'**
  String get educationAndKnowledgeRoles;

  /// No description provided for @generalProfessions.
  ///
  /// In en, this message translates to:
  /// **'General Professions'**
  String get generalProfessions;

  /// No description provided for @technicalJobs.
  ///
  /// In en, this message translates to:
  /// **'Technical Jobs'**
  String get technicalJobs;

  /// No description provided for @beliefsAndPractices.
  ///
  /// In en, this message translates to:
  /// **'Beliefs & Practices'**
  String get beliefsAndPractices;

  /// No description provided for @religiousPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get religiousPeople;

  /// No description provided for @religiousObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get religiousObjects;

  /// No description provided for @religiousPlaces.
  ///
  /// In en, this message translates to:
  /// **'Religious Places'**
  String get religiousPlaces;

  /// No description provided for @festivals.
  ///
  /// In en, this message translates to:
  /// **'Festivals'**
  String get festivals;

  /// No description provided for @concepts.
  ///
  /// In en, this message translates to:
  /// **'Concepts'**
  String get concepts;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @cognition.
  ///
  /// In en, this message translates to:
  /// **'Cognition'**
  String get cognition;

  /// No description provided for @emotionAndAttitude.
  ///
  /// In en, this message translates to:
  /// **'Emotion & Attitude'**
  String get emotionAndAttitude;

  /// No description provided for @perception.
  ///
  /// In en, this message translates to:
  /// **'Perception'**
  String get perception;

  /// No description provided for @actionAndManipulation.
  ///
  /// In en, this message translates to:
  /// **'Action & Manipulation'**
  String get actionAndManipulation;

  /// No description provided for @movementAndPosture.
  ///
  /// In en, this message translates to:
  /// **'Movement & Posture'**
  String get movementAndPosture;

  /// No description provided for @stateAndChange.
  ///
  /// In en, this message translates to:
  /// **'State & Change'**
  String get stateAndChange;

  /// No description provided for @devicesAndHardware.
  ///
  /// In en, this message translates to:
  /// **'Devices & Hardware'**
  String get devicesAndHardware;

  /// No description provided for @softwareAndData.
  ///
  /// In en, this message translates to:
  /// **'Software & Data'**
  String get softwareAndData;

  /// No description provided for @internetAndNetworks.
  ///
  /// In en, this message translates to:
  /// **'Internet & Networks'**
  String get internetAndNetworks;

  /// No description provided for @engineeringAndMaking.
  ///
  /// In en, this message translates to:
  /// **'Engineering & Making'**
  String get engineeringAndMaking;

  /// No description provided for @newTechAndAi.
  ///
  /// In en, this message translates to:
  /// **'New Tech & AI'**
  String get newTechAndAi;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @dayAndTime.
  ///
  /// In en, this message translates to:
  /// **'Day & Time'**
  String get dayAndTime;

  /// No description provided for @schedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedules;

  /// No description provided for @frequencyAndDuration.
  ///
  /// In en, this message translates to:
  /// **'Frequency & Duration'**
  String get frequencyAndDuration;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @travelAndTickets.
  ///
  /// In en, this message translates to:
  /// **'Travel & Tickets'**
  String get travelAndTickets;

  /// No description provided for @roadAndTraffic.
  ///
  /// In en, this message translates to:
  /// **'Road & Traffic'**
  String get roadAndTraffic;

  /// No description provided for @responsibility.
  ///
  /// In en, this message translates to:
  /// **'Responsibility'**
  String get responsibility;

  /// No description provided for @publicationsAndMaterials.
  ///
  /// In en, this message translates to:
  /// **'Publications & Materials'**
  String get publicationsAndMaterials;

  /// No description provided for @meetingsAndAssemblies.
  ///
  /// In en, this message translates to:
  /// **'Meetings & Assemblies'**
  String get meetingsAndAssemblies;

  /// No description provided for @manualAndBibleUse.
  ///
  /// In en, this message translates to:
  /// **'Manual & Bible Use'**
  String get manualAndBibleUse;

  /// No description provided for @serviceAndMinistry.
  ///
  /// In en, this message translates to:
  /// **'Service & Ministry'**
  String get serviceAndMinistry;

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locations;

  /// No description provided for @bibleCharacters.
  ///
  /// In en, this message translates to:
  /// **'Bible Characters'**
  String get bibleCharacters;

  /// No description provided for @historicalOrPropheticEvents.
  ///
  /// In en, this message translates to:
  /// **'Historical or Prophetic Events'**
  String get historicalOrPropheticEvents;

  /// No description provided for @booksOfTheBible.
  ///
  /// In en, this message translates to:
  /// **'Books of the Bible'**
  String get booksOfTheBible;

  /// No description provided for @bibleTeaching.
  ///
  /// In en, this message translates to:
  /// **'Bible Teaching'**
  String get bibleTeaching;

  /// No description provided for @biblicalSymbols.
  ///
  /// In en, this message translates to:
  /// **'Biblical Symbols'**
  String get biblicalSymbols;

  /// No description provided for @wantToLearn.
  ///
  /// In en, this message translates to:
  /// **'LEARN ALSO'**
  String get wantToLearn;

  /// No description provided for @tryTheOpposite.
  ///
  /// In en, this message translates to:
  /// **'LEARN THE OPPOSITE'**
  String get tryTheOpposite;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @displayNameValidatorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your display name'**
  String get displayNameValidatorEmpty;

  /// No description provided for @displayNameValidatorMinLength.
  ///
  /// In en, this message translates to:
  /// **'Display name must be at least 2 characters'**
  String get displayNameValidatorMinLength;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country *'**
  String get countryLabel;

  /// No description provided for @countryHelperText.
  ///
  /// In en, this message translates to:
  /// **'Please select your country'**
  String get countryHelperText;

  /// No description provided for @countryValidatorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please select your country'**
  String get countryValidatorEmpty;

  /// No description provided for @userTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'i am'**
  String get userTypeLabel;

  /// No description provided for @userTypeHelperText.
  ///
  /// In en, this message translates to:
  /// **'Please tell us whether you are hearing impaired (deaf) or a hearing person'**
  String get userTypeHelperText;

  /// No description provided for @userTypeValidator.
  ///
  /// In en, this message translates to:
  /// **'Please select whether you are Hearing Impaired (Deaf) or a hearing person'**
  String get userTypeValidator;

  /// No description provided for @userTypeOptionHearingImpaired.
  ///
  /// In en, this message translates to:
  /// **'Hearing Impaired (Deaf)'**
  String get userTypeOptionHearingImpaired;

  /// No description provided for @userTypeOptionHearing.
  ///
  /// In en, this message translates to:
  /// **'a hearing person'**
  String get userTypeOptionHearing;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordValidatorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordValidatorEmpty;

  /// No description provided for @confirmPasswordValidatorMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get confirmPasswordValidatorMismatch;

  /// No description provided for @noteToAdministratorLabel.
  ///
  /// In en, this message translates to:
  /// **'Note to Administrator (Optional)'**
  String get noteToAdministratorLabel;

  /// No description provided for @noteToAdministratorHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message to the administrator (optional)'**
  String get noteToAdministratorHint;

  /// No description provided for @noteToAdministratorHelperText.
  ///
  /// In en, this message translates to:
  /// **'Tell the administrator why you want to join (optional)'**
  String get noteToAdministratorHelperText;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLink;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match. Please try again.'**
  String get passwordMismatchError;

  /// No description provided for @selectCountryError.
  ///
  /// In en, this message translates to:
  /// **'Please select your country'**
  String get selectCountryError;

  /// No description provided for @captchaRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please complete the security check to continue.'**
  String get captchaRequiredMessage;

  /// No description provided for @emailAlreadyExistsError.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email'**
  String get emailAlreadyExistsError;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @premiumSignInRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to buy or restore Premium so it can be linked to your account.'**
  String get premiumSignInRequiredBody;

  /// No description provided for @newUserSignUp.
  ///
  /// In en, this message translates to:
  /// **'New user? Please sign up'**
  String get newUserSignUp;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get signInWithGoogle;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @approvingYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Approving your account...'**
  String get approvingYourAccount;

  /// No description provided for @emailVerifiedApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Email verified! Your account has been approved. Please sign in.'**
  String get emailVerifiedApprovedMessage;

  /// No description provided for @accountPendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Pending Approval'**
  String get accountPendingApprovalTitle;

  /// No description provided for @accountAwaitingApprovalHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your account is awaiting approval'**
  String get accountAwaitingApprovalHeadline;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your email has been successfully verified.'**
  String get emailVerifiedSuccess;

  /// No description provided for @accountPendingApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'Your email has been successfully verified. Your account is now pending administrator approval. You will receive access once the admin approves your account.'**
  String get accountPendingApprovalBody;

  /// No description provided for @accessAfterApproval.
  ///
  /// In en, this message translates to:
  /// **'Access after approval'**
  String get accessAfterApproval;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get whatHappensNext;

  /// No description provided for @nextAdminReview.
  ///
  /// In en, this message translates to:
  /// **'An administrator will review your account'**
  String get nextAdminReview;

  /// No description provided for @nextRoleAssignment.
  ///
  /// In en, this message translates to:
  /// **'You will be assigned appropriate roles'**
  String get nextRoleAssignment;

  /// No description provided for @nextAccessAfterApproved.
  ///
  /// In en, this message translates to:
  /// **'You will receive full access to the app'**
  String get nextAccessAfterApproved;

  /// No description provided for @returnToApp.
  ///
  /// In en, this message translates to:
  /// **'Return to App'**
  String get returnToApp;

  /// No description provided for @verifyStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error checking verification status'**
  String get verifyStatusError;

  /// No description provided for @verifyEmailResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification email resent successfully'**
  String get verifyEmailResentSuccess;

  /// No description provided for @verifyEmailResentError.
  ///
  /// In en, this message translates to:
  /// **'Error resending verification email'**
  String get verifyEmailResentError;

  /// No description provided for @verifyYourEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmailTitle;

  /// No description provided for @verifyYourEmailHeadline.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address'**
  String get verifyYourEmailHeadline;

  /// No description provided for @verifyEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to:'**
  String get verifyEmailSentTo;

  /// No description provided for @verifyEmailInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get verifyEmailInfoHeader;

  /// No description provided for @verifyEmailInfoBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to your email address. Please check your inbox (and spam folder) and click the link to verify your account.'**
  String get verifyEmailInfoBody;

  /// No description provided for @verifyEmailAutoRedirectHint.
  ///
  /// In en, this message translates to:
  /// **'You will be automatically redirected once your email is verified.'**
  String get verifyEmailAutoRedirectHint;

  /// No description provided for @sendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingLabel;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerificationEmail;

  /// No description provided for @checkingVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking verification status...'**
  String get checkingVerificationStatus;

  /// No description provided for @premiumSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumSectionTitle;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @removeAdsUnlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove ads and get unlimited access'**
  String get removeAdsUnlimitedAccess;

  /// No description provided for @removeAllAdsForever.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads forever — Upgrade to Premium.'**
  String get removeAllAdsForever;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No Thanks'**
  String get noThanks;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @monthlyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit Reached'**
  String get monthlyLimitReached;

  /// No description provided for @quizLimitReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your monthly free Quiz sessions. Watch a short ad to unlock 3 additional Quiz sessions.'**
  String get quizLimitReachedMessage;

  /// No description provided for @flashcardLimitReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your monthly free Flashcard sessions. Watch a short ad to unlock 3 additional Flashcard sessions.'**
  String get flashcardLimitReachedMessage;

  /// No description provided for @goPremiumUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Go Premium for unlimited learning'**
  String get goPremiumUnlimited;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @quizSessionsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'✅ 3 additional Quiz sessions unlocked!'**
  String get quizSessionsUnlocked;

  /// No description provided for @flashcardSessionsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'✅ 3 additional Flashcard sessions unlocked!'**
  String get flashcardSessionsUnlocked;

  /// No description provided for @failedToLoadAd.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ad. Please try again.'**
  String get failedToLoadAd;

  /// No description provided for @watchAdCompletely.
  ///
  /// In en, this message translates to:
  /// **'Please watch the ad completely to earn reward.'**
  String get watchAdCompletely;

  /// No description provided for @premiumMember.
  ///
  /// In en, this message translates to:
  /// **'You are a Premium Member!'**
  String get premiumMember;

  /// No description provided for @renews.
  ///
  /// In en, this message translates to:
  /// **'Renews:'**
  String get renews;

  /// No description provided for @switchToYearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Switch to Yearly Plan'**
  String get switchToYearlyPlan;

  /// No description provided for @saveMoreBestValue.
  ///
  /// In en, this message translates to:
  /// **'Save more with Best Value'**
  String get saveMoreBestValue;

  /// No description provided for @premiumBenefits.
  ///
  /// In en, this message translates to:
  /// **'Premium Benefits'**
  String get premiumBenefits;

  /// No description provided for @noAds.
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get noAds;

  /// No description provided for @unlimitedQuiz.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Quiz'**
  String get unlimitedQuiz;

  /// No description provided for @unlimitedFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Flashcards'**
  String get unlimitedFlashcards;

  /// No description provided for @supportAppDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Support App Development'**
  String get supportAppDevelopment;

  /// No description provided for @subscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlans;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get bestValue;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @upgradeInitiated.
  ///
  /// In en, this message translates to:
  /// **'Upgrade initiated...'**
  String get upgradeInitiated;

  /// No description provided for @failedToInitiateUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate upgrade'**
  String get failedToInitiateUpgrade;

  /// No description provided for @restoringPurchases.
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases...'**
  String get restoringPurchases;

  /// No description provided for @noPurchasesFound.
  ///
  /// In en, this message translates to:
  /// **'No purchases found'**
  String get noPurchasesFound;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @unlimitedLearningAdFree.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Learning, Ad-Free'**
  String get unlimitedLearningAdFree;

  /// No description provided for @noAdsDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads and learn without interruption'**
  String get noAdsDescription;

  /// No description provided for @unlimitedQuizDescription.
  ///
  /// In en, this message translates to:
  /// **'Play as many quizzes as you want'**
  String get unlimitedQuizDescription;

  /// No description provided for @unlimitedFlashcardsDescription.
  ///
  /// In en, this message translates to:
  /// **'Play unlimited flashcard sessions'**
  String get unlimitedFlashcardsDescription;

  /// No description provided for @supportAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Help us improve the Sign Language Dictionary'**
  String get supportAppDescription;

  /// No description provided for @purchaseInitiated.
  ///
  /// In en, this message translates to:
  /// **'Purchase initiated...'**
  String get purchaseInitiated;

  /// No description provided for @failedToInitiatePurchase.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate purchase'**
  String get failedToInitiatePurchase;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress!'**
  String get yourProgress;

  /// No description provided for @learnedSignsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'You\'ve learned {count} signs this month!'**
  String learnedSignsThisMonth(int count);

  /// No description provided for @supportAppRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Support the app & remove ads with Premium.'**
  String get supportAppRemoveAds;

  /// No description provided for @viewPremium.
  ///
  /// In en, this message translates to:
  /// **'View Premium'**
  String get viewPremium;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// No description provided for @appVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionTitle;

  /// No description provided for @freeSessions.
  ///
  /// In en, this message translates to:
  /// **'Free Session: {remaining} / {max}'**
  String freeSessions(int remaining, int max);

  /// No description provided for @watchAdRestoreTokensButton.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad to add 3 tokens'**
  String get watchAdRestoreTokensButton;

  /// No description provided for @googleSignUpCompleteSteps.
  ///
  /// In en, this message translates to:
  /// **'Please complete the following steps'**
  String get googleSignUpCompleteSteps;

  /// No description provided for @flashcardReviewExisting.
  ///
  /// In en, this message translates to:
  /// **'Review Existing'**
  String get flashcardReviewExisting;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @drawerAboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About This App'**
  String get drawerAboutThisApp;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About This App'**
  String get aboutTitle;

  /// No description provided for @aboutSection1Title.
  ///
  /// In en, this message translates to:
  /// **'About This App'**
  String get aboutSection1Title;

  /// No description provided for @aboutSection1Body.
  ///
  /// In en, this message translates to:
  /// **'This app was created with a simple goal: to collect the signs most commonly used by deaf people in Bangladesh. It does not try to create or declare an official standard.\n\nIn Bangladesh there is not yet one national standard sign language. Different books, schools and communities use slightly different versions. That is why some words have more than one sign in this app.\n\nMany deaf people who are open to other cultures also start to use signs from other sign languages, such as Indian Sign Language (ISL) or American Sign Language (ASL). This app is only trying to reflect the real, living language that people actually use in daily life.\n\nWe hope this app will be useful and enjoyable for you.'**
  String get aboutSection1Body;

  /// No description provided for @aboutSection2Title.
  ///
  /// In en, this message translates to:
  /// **'Vision for the Future'**
  String get aboutSection2Title;

  /// No description provided for @aboutSection2Body.
  ///
  /// In en, this message translates to:
  /// **'Our ambition is to go further than a simple dictionary. Step by step we want to build a learning tool that helps you:\n\n• learn sign language in a clear, progressive way\n• track your progress over time\n• practice with exercises, games and small learning paths\n\nIn the future we also want to:\n\n• allow learners to connect with sign language teachers trained with our method\n• allow schools to use this app in the classroom\n• give teachers tools to see their students\' progress and which signs are difficult for them\n\nOur goal is to support individuals, families and schools who care about the deaf community in Bangladesh.'**
  String get aboutSection2Body;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
