import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

// Type alias for convenience - allows using S instead of AppLocalizations
typedef S = AppLocalizations;

// Display label for category/subcategory keys coming from Firestore or code.
// New taxonomy: if we have generated getters use them; otherwise fall back to English labels.
String translateCategory(BuildContext context, String legacyKey) {
  final String normalized = legacyKey.replaceAll('_', ' ').replaceAll('–', '-').trim();
  final String lower = normalized.toLowerCase();

  // Helper to choose EN label when BN translation is not yet provided in ARB
  String en(String label) => label;

  // Game labels (keep using localized strings)
  if (lower == 'random words quiz') return S.of(context)!.randomWordsQuiz;
  if (lower == 'quiz by category') return S.of(context)!.quizByCategory;
  if (lower == 'flashcard game') return S.of(context)!.flashcardGame;

  // Special
  if (lower == 'all words' || lower == 'all') return S.of(context)!.allWords;

  // Canonicalization helpers: treat variations of punctuation and conjunctions as equivalent
  String canon(String s) {
    final t = s
        .toLowerCase()
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(' & ', ' and ')
        .replaceAll('&', ' and ')
        .replaceAll('-', ' - ')
        .replaceAll(RegExp(r"\s+"), ' ')
        .trim();
    return t;
  }

  final key = canon(normalized);

  // Map old taxonomy names to new canonical English labels
  String? canonical;
  switch (key) {
    // Top-level categories
    case 'activities and hobbies':
      canonical = 'Activities & Hobbies';
      break;
    case 'adjectives':
      canonical = 'Adjectives';
      break;
    case 'administration and public services':
      canonical = 'Administration & Public Services';
      break;
    case 'business and management':
      canonical = 'Business & Management';
      break;
    case 'culture and identity':
      canonical = 'Culture & Identity';
      break;
    case 'education and academia':
      canonical = 'Education & Academia';
      break;
    case 'family and relationships':
      canonical = 'Family & Relationships';
      break;
    case 'food and drinks':
      canonical = 'Food & Drinks';
      break;
    case 'geography - bangladesh':
    case 'geography bangladesh':
      canonical = 'Geography – Bangladesh';
      break;
    case 'geography - international':
    case 'geography international':
      canonical = 'Geography – International';
      break;
    case 'grammar':
    case 'grammar & basics':
    case 'grammar and basics':
      canonical = 'Grammar & Basics';
      break;
    case 'health':
      canonical = 'Health';
      break;
    case 'house':
      canonical = 'House';
      break;
    case 'media and communication':
      canonical = 'Media & Communication';
      break;
    case 'nature and environment':
      canonical = 'Nature & Environment';
      break;
    case 'nouns':
      canonical = 'Nouns';
      break;
    case 'politics and society':
      canonical = 'Politics & Society';
      break;
    case 'professions and occupations':
      canonical = 'Professions & Occupations';
      break;
    case 'religion':
      canonical = 'Religion';
      break;
    case 'technology and science':
      canonical = 'Technology & Science';
      break;
    case 'time and dates':
      canonical = 'Time & Dates';
      break;
    case 'transport':
      canonical = 'Transport';
      break;
    case 'verbs':
      canonical = 'Verbs';
      break;
    case 'jw organisation':
    case 'jw organization':
      canonical = 'JW Organisation';
      break;
    case 'biblical content':
      canonical = 'Biblical Content';
      break;

    // Subcategories — Activities & Hobbies
    case 'outdoor and sports':
      canonical = 'Outdoor & Sports';
      break;
    case 'arts and crafts':
      canonical = 'Arts & Crafts';
      break;
    case 'music and dance':
      canonical = 'Music & Dance';
      break;
    case 'games':
      canonical = 'Games';
      break;
    case 'home and hobbies':
      canonical = 'Home & Hobbies';
      break;

    // Subcategories — Adjectives
    case 'qualities':
      canonical = 'Qualities';
      break;
    case 'flaws and weaknesses':
      canonical = 'Flaws & Weaknesses';
      break;
    case 'emotions':
      canonical = 'Emotions';
      break;
    case 'condition':
      canonical = 'Condition';
      break;

    // Subcategories — Administration & Public Services
    case 'citizen services and ids':
      canonical = 'Citizen Services & IDs';
      break;
    case 'public services and facilities':
      canonical = 'Public Services & Facilities';
      break;
    case 'government offices and authorities':
      canonical = 'Government Offices & Authorities';
      break;
    case 'documents and law':
      canonical = 'Documents & Law';
      break;

    // Subcategories — Business & Management
    case 'planning and organizing':
      canonical = 'Planning & Organizing';
      break;
    case 'money and economy':
      canonical = 'Money & Economy';
      break;
    case 'deals and contracts':
      canonical = 'Deals & Contracts';
      break;
    case 'money and accounts':
      canonical = 'Money & Accounts';
      break;
    case 'operations and supply':
      canonical = 'Operations & Supply';
      break;
    case 'marketing and sales':
      canonical = 'Marketing & Sales';
      break;
    case 'people and hr':
      canonical = 'People & HR';
      break;

    // Subcategories — Culture & Identity
    case 'languages':
      canonical = 'Languages';
      break;
    case 'clothes and dress':
      canonical = 'Clothes & Dress';
      break;
    case 'food and cooking':
      canonical = 'Food & Cooking';
      break;
    case 'traditions and festivals':
      canonical = 'Traditions & Festivals';
      break;
    case 'arts and heritage':
      canonical = 'Arts & Heritage';
      break;

    // Subcategories — Education & Academia
    case 'schools and colleges':
      canonical = 'Schools & Colleges';
      break;
    case 'subjects':
      canonical = 'Subjects';
      break;
    case 'exams and grades':
      canonical = 'Exams & Grades';
      break;
    case 'classroom and tools':
      canonical = 'Classroom & Tools';
      break;
    case 'research and papers':
      canonical = 'Research & Papers';
      break;

    // Subcategories — Family & Relationships
    case 'family members':
      canonical = 'Family Members';
      break;
    case 'marriage and in-laws':
      canonical = 'Marriage & In-Laws';
      break;
    case 'relationships and status':
      canonical = 'Relationships & Status';
      break;

    // Subcategories — Food & Drinks
    case 'ingredients':
      canonical = 'Ingredients';
      break;
    case 'dishes':
      canonical = 'Dishes';
      break;
    case 'drinks':
      canonical = 'Drinks';
      break;
    case 'cooking and tools':
      canonical = 'Cooking & Tools';
      break;
    case 'eating places':
      canonical = 'Eating Places';
      break;

    // Subcategories — Geography – Bangladesh
    case 'cities and districts':
      canonical = 'Cities & Districts';
      break;
    case 'towns':
      canonical = 'Towns';
      break;
    case 'neighborhoods and localities':
      canonical = 'Neighborhoods & Localities';
      break;
    case 'institutions and facilities':
      canonical = 'Institutions & Facilities';
      break;

    // Subcategories — Geography – International
    case 'countries and regions':
      canonical = 'Countries & Regions';
      break;
    case 'cities and capitals':
      canonical = 'Cities & Capitals';
      break;
    case 'nature (land and water)':
      canonical = 'Nature (Land & Water)';
      break;
    case 'landmarks':
      canonical = 'Landmarks';
      break;
    case 'orgs and codes':
      canonical = 'Orgs & Codes';
      break;

    // Subcategories — Health
    case 'body':
      canonical = 'Body';
      break;
    case 'illness and symptoms':
      canonical = 'Illness & Symptoms';
      break;
    case 'care and treatment':
      canonical = 'Care & Treatment';
      break;
    case 'medicine and tools':
      canonical = 'Medicine & Tools';
      break;
    case 'fitness and diet':
      canonical = 'Fitness & Diet';
      break;

    // Subcategories — House
    case 'rooms':
      canonical = 'Rooms';
      break;
    case 'furniture':
      canonical = 'Furniture';
      break;
    case 'appliances':
      canonical = 'Appliances';
      break;
    case 'tools and repair':
      canonical = 'Tools & Repair';
      break;
    case 'household items':
      canonical = 'Household Items';
      break;

    // Subcategories — Media & Communication
    case 'news and tv/radio':
      canonical = 'News & TV/Radio';
      break;
    case 'online and web':
      canonical = 'Online & Web';
      break;
    case 'social media':
      canonical = 'Social Media';
      break;
    case 'messaging and calls':
      canonical = 'Messaging & Calls';
      break;
    case 'media types':
      canonical = 'Media Types';
      break;
    case 'devices':
      canonical = 'Devices';
      break;

    // Subcategories — Nature & Environment
    case 'weather and seasons':
      canonical = 'Weather & Seasons';
      break;
    case 'animals':
      canonical = 'Animals';
      break;
    case 'plants':
      canonical = 'Plants';
      break;
    case 'places and habitats':
      canonical = 'Places & Habitats';
      break;
    case 'earth and disasters':
      canonical = 'Earth & Disasters';
      break;

    // Subcategories — Nouns
    case 'people':
      canonical = 'People';
      break;
    case 'objects':
      canonical = 'Objects';
      break;
    case 'abstract objects':
      canonical = 'Abstract Objects';
      break;
    case 'social behaviour':
      canonical = 'Social Behaviour';
      break;
    case 'habits':
      canonical = 'Habits';
      break;

    // Subcategories — Politics & Society
    case 'political system and elections':
      canonical = 'Political System & Elections';
      break;
    case 'ideologies and movements':
      canonical = 'Ideologies & Movements';
      break;
    case 'conflicts and wars':
      canonical = 'Conflicts & Wars';
      break;
    case 'governance and policy debate':
      canonical = 'Governance & Policy Debate';
      break;
    case 'social issues and civil society':
      canonical = 'Social Issues & Civil Society';
      break;

    // Subcategories — Professions & Occupations
    case 'public service roles':
      canonical = 'Public Service Roles';
      break;
    case 'business roles':
      canonical = 'Business Roles';
      break;
    case 'education and knowledge roles':
      canonical = 'Education & Knowledge Roles';
      break;
    case 'general professions':
      canonical = 'General Professions';
      break;
    case 'technical jobs':
      canonical = 'Technical Jobs';
      break;

    // Subcategories — Religion
    case 'beliefs and practices':
      canonical = 'Beliefs & Practices';
      break;
    case 'religious places':
      canonical = 'Religious Places';
      break;
    case 'concepts':
      canonical = 'Concepts';
      break;

    // Subcategories — Verbs
    case 'communication':
      canonical = 'Communication';
      break;
    case 'cognition':
      canonical = 'Cognition';
      break;
    case 'emotion and attitude':
    case 'émotion and attitude':
      canonical = 'Emotion & Attitude';
      break;
    case 'perception':
      canonical = 'Perception';
      break;
    case 'action and manipulation':
      canonical = 'Action & Manipulation';
      break;
    case 'movement and posture':
      canonical = 'Movement & Posture';
      break;
    case 'state and change':
      canonical = 'State & Change';
      break;

    // Subcategories — Technology & Science
    case 'devices and hardware':
      canonical = 'Devices & Hardware';
      break;
    case 'software and data':
      canonical = 'Software & Data';
      break;
    case 'internet and networks':
      canonical = 'Internet & Networks';
      break;
    case 'engineering and making':
      canonical = 'Engineering & Making';
      break;
    case 'new tech and ai':
      canonical = 'New Tech & AI';
      break;

    // Subcategories — Time & Dates
    case 'calendar':
      canonical = 'Calendar';
      break;
    case 'day and time':
      canonical = 'Day & Time';
      break;
    case 'schedules':
      canonical = 'Schedules';
      break;
    case 'frequency and duration':
      canonical = 'Frequency & Duration';
      break;

    // Subcategories — Transport
    case 'places':
      canonical = 'Places';
      break;
    case 'travel and tickets':
      canonical = 'Travel & Tickets';
      break;
    case 'road and traffic':
      canonical = 'Road & Traffic';
      break;

    // Subcategories — JW Organisation
    case 'responsability':
    case 'responsibility':
      canonical = 'Responsibility';
      break;
    case 'publications and materials':
      canonical = 'Publications & Materials';
      break;
    case 'meetings and assemblies':
      canonical = 'Meetings & Assemblies';
      break;
    case 'manual and bible use':
      canonical = 'Manual & Bible Use';
      break;
    case 'service and ministry':
      canonical = 'Service & Ministry';
      break;

    // Subcategories — Biblical Content
    case 'locations':
      canonical = 'Locations';
      break;
    case 'bible characters':
      canonical = 'Bible Characters';
      break;
    case 'historical or prophetic events':
      canonical = 'Historical or Prophetic Events';
      break;
    case 'books of the bible':
      canonical = 'Books of the Bible';
      break;
    case 'bible teaching':
      canonical = 'Bible Teaching';
      break;
    case 'biblical symbols':
      canonical = 'Biblical Symbols';
      break;

    // Keep only new subcats that remain valid in the new taxonomy
    case 'alphabet':
      canonical = 'Alphabet';
      break;
    case 'numbers':
      canonical = 'Numbers';
      break;
    case 'personal pronouns':
      canonical = 'Personal Pronouns';
      break;
    case 'question words':
      canonical = 'Question Words';
      break;
  }

  if (canonical != null) {
    // Try to get translation from ARB files using the camelCase key
    try {
      final s = S.of(context)!;
      // Convert canonical name to camelCase key (e.g., "Activities & Hobbies" -> "activitiesAndHobbies")
      final camelKey = _toCamelCase(canonical);
      
      // Use reflection-like approach to get the translation
      switch (camelKey) {
        case 'activitiesAndHobbies': return s.activitiesAndHobbies;
        case 'adjectives': return s.adjectives;
        case 'administrationAndPublicServices': return s.administrationAndPublicServices;
        case 'businessAndManagement': return s.businessAndManagement;
        case 'cultureAndIdentity': return s.cultureAndIdentity;
        case 'educationAndAcademia': return s.educationAndAcademia;
        case 'familyAndRelationships': return s.familyAndRelationships;
        case 'foodAndDrinks': return s.foodAndDrinks;
        case 'geographyBangladesh': return s.geographyBangladesh;
        case 'geographyInternational': return s.geographyInternational;
        case 'grammarAndBasics': return s.grammarAndBasics;
        case 'health': return s.health;
        case 'house': return s.house;
        case 'mediaAndCommunication': return s.mediaAndCommunication;
        case 'natureAndEnvironment': return s.natureAndEnvironment;
        case 'nouns': return s.nouns;
        case 'politicsAndSociety': return s.politicsAndSociety;
        case 'professionsAndOccupations': return s.professionsAndOccupations;
        case 'religion': return s.religion;
        case 'technologyAndScience': return s.technologyAndScience;
        case 'timeAndDates': return s.timeAndDates;
        case 'transport': return s.transport;
        case 'verbs': return s.verbs;
        case 'jwOrganisation': return s.jwOrganisation;
        case 'biblicalContent': return s.biblicalContent;
        
        // Subcategories
        case 'outdoorAndSports': return s.outdoorAndSports;
        case 'artsAndCrafts': return s.artsAndCrafts;
        case 'musicAndDance': return s.musicAndDance;
        case 'games': return s.games;
        case 'homeAndHobbies': return s.homeAndHobbies;
        case 'qualities': return s.qualities;
        case 'flawsAndWeaknesses': return s.flawsAndWeaknesses;
        case 'emotions': return s.emotions;
        case 'condition': return s.condition;
        case 'citizenServicesAndIds': return s.citizenServicesAndIds;
        case 'publicServicesAndFacilities': return s.publicServicesAndFacilities;
        case 'governmentOfficesAndAuthorities': return s.governmentOfficesAndAuthorities;
        case 'documentsAndLaw': return s.documentsAndLaw;
        case 'planningAndOrganizing': return s.planningAndOrganizing;
        case 'moneyAndEconomy': return s.moneyAndEconomy;
        case 'dealsAndContracts': return s.dealsAndContracts;
        case 'moneyAndAccounts': return s.moneyAndAccounts;
        case 'operationsAndSupply': return s.operationsAndSupply;
        case 'marketingAndSales': return s.marketingAndSales;
        case 'peopleAndHr': return s.peopleAndHr;
        case 'languages': return s.languages;
        case 'clothesAndDress': return s.clothesAndDress;
        case 'foodAndCooking': return s.foodAndCooking;
        case 'traditionsAndFestivals': return s.traditionsAndFestivals;
        case 'artsAndHeritage': return s.artsAndHeritage;
        case 'schoolsAndColleges': return s.schoolsAndColleges;
        case 'subjects': return s.subjects;
        case 'examsAndGrades': return s.examsAndGrades;
        case 'classroomAndTools': return s.classroomAndTools;
        case 'researchAndPapers': return s.researchAndPapers;
        case 'familyMembers': return s.familyMembers;
        case 'marriageAndInLaws': return s.marriageAndInLaws;
        case 'relationshipsAndStatus': return s.relationshipsAndStatus;
        case 'ingredients': return s.ingredients;
        case 'dishes': return s.dishes;
        case 'drinks': return s.drinks;
        case 'cookingAndTools': return s.cookingAndTools;
        case 'eatingPlaces': return s.eatingPlaces;
        case 'citiesAndDistricts': return s.citiesAndDistricts;
        case 'towns': return s.towns;
        case 'neighborhoodsAndLocalities': return s.neighborhoodsAndLocalities;
        case 'institutionsAndFacilities': return s.institutionsAndFacilities;
        case 'countriesAndRegions': return s.countriesAndRegions;
        case 'citiesAndCapitals': return s.citiesAndCapitals;
        case 'natureLandAndWater': return s.natureLandAndWater;
        case 'landmarks': return s.landmarks;
        case 'orgsAndCodes': return s.orgsAndCodes;
        case 'body': return s.body;
        case 'illnessAndSymptoms': return s.illnessAndSymptoms;
        case 'careAndTreatment': return s.careAndTreatment;
        case 'medicineAndTools': return s.medicineAndTools;
        case 'fitnessAndDiet': return s.fitnessAndDiet;
        case 'rooms': return s.rooms;
        case 'furniture': return s.furniture;
        case 'appliances': return s.appliances;
        case 'toolsAndRepair': return s.toolsAndRepair;
        case 'householdItems': return s.householdItems;
        case 'alphabet': return s.alphabet;
        case 'numbers': return s.numbers;
        case 'personalPronoun': return s.personalPronoun;
        case 'questionWords': return s.questionWords;
        case 'newsAndTvRadio': return s.newsAndTvRadio;
        case 'onlineAndWeb': return s.onlineAndWeb;
        case 'socialMedia': return s.socialMedia;
        case 'messagingAndCalls': return s.messagingAndCalls;
        case 'mediaTypes': return s.mediaTypes;
        case 'devices': return s.devices;
        case 'weatherAndSeasons': return s.weatherAndSeasons;
        case 'animals': return s.animals;
        case 'plants': return s.plants;
        case 'placesAndHabitats': return s.placesAndHabitats;
        case 'earthAndDisasters': return s.earthAndDisasters;
        case 'people': return s.people;
        case 'objects': return s.objects;
        case 'abstractObjects': return s.abstractObjects;
        case 'socialBehaviour': return s.socialBehaviour;
        case 'habits': return s.habits;
        case 'politicalSystemAndElections': return s.politicalSystemAndElections;
        case 'ideologiesAndMovements': return s.ideologiesAndMovements;
        case 'conflictsAndWars': return s.conflictsAndWars;
        case 'governanceAndPolicyDebate': return s.governanceAndPolicyDebate;
        case 'socialIssuesAndCivilSociety': return s.socialIssuesAndCivilSociety;
        case 'publicServiceRoles': return s.publicServiceRoles;
        case 'businessRoles': return s.businessRoles;
        case 'educationAndKnowledgeRoles': return s.educationAndKnowledgeRoles;
        case 'generalProfessions': return s.generalProfessions;
        case 'technicalJobs': return s.technicalJobs;
        case 'beliefsAndPractices': return s.beliefsAndPractices;
        case 'religiousPeople': return s.religiousPeople;
        case 'religiousObjects': return s.religiousObjects;
        case 'religiousPlaces': return s.religiousPlaces;
        case 'festivals': return s.festivals;
        case 'concepts': return s.concepts;
        case 'communication': return s.communication;
        case 'cognition': return s.cognition;
        case 'emotionAndAttitude': return s.emotionAndAttitude;
        case 'perception': return s.perception;
        case 'actionAndManipulation': return s.actionAndManipulation;
        case 'movementAndPosture': return s.movementAndPosture;
        case 'stateAndChange': return s.stateAndChange;
        case 'devicesAndHardware': return s.devicesAndHardware;
        case 'softwareAndData': return s.softwareAndData;
        case 'internetAndNetworks': return s.internetAndNetworks;
        case 'engineeringAndMaking': return s.engineeringAndMaking;
        case 'newTechAndAi': return s.newTechAndAi;
        case 'calendar': return s.calendar;
        case 'dayAndTime': return s.dayAndTime;
        case 'schedules': return s.schedules;
        case 'frequencyAndDuration': return s.frequencyAndDuration;
        case 'vehicles': return s.vehicles;
        case 'places': return s.places;
        case 'travelAndTickets': return s.travelAndTickets;
        case 'roadAndTraffic': return s.roadAndTraffic;
        case 'responsibility': return s.responsibility;
        case 'publicationsAndMaterials': return s.publicationsAndMaterials;
        case 'meetingsAndAssemblies': return s.meetingsAndAssemblies;
        case 'manualAndBibleUse': return s.manualAndBibleUse;
        case 'serviceAndMinistry': return s.serviceAndMinistry;
        case 'locations': return s.locations;
        case 'bibleCharacters': return s.bibleCharacters;
        case 'historicalOrPropheticEvents': return s.historicalOrPropheticEvents;
        case 'booksOfTheBible': return s.booksOfTheBible;
        case 'bibleTeaching': return s.bibleTeaching;
        case 'biblicalSymbols': return s.biblicalSymbols;
        
        default:
          // If no translation found, return English canonical
          return canonical;
      }
    } catch (e) {
      // If any error, fallback to English
      return canonical;
    }
  }

  // Final fallback: return the original key as-is
  return legacyKey;
}

// Helper function to convert "Activities & Hobbies" to "activitiesAndHobbies"
String _toCamelCase(String text) {
  // First, replace "&" with "and" before removing special characters
  // This ensures "Cities & Districts" becomes "Cities and Districts" -> "citiesAndDistricts"
  final normalized = text
      .replaceAll(' & ', ' and ')
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^\w\s]'), '') // Remove remaining special characters
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();
  
  if (normalized.isEmpty) return text;
  
  // First word lowercase, rest with first letter uppercase
  final result = normalized[0].toLowerCase() + 
      normalized.skip(1).map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join('');
  
  return result;
}


