import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  final _storage = const FlutterSecureStorage();
  
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final stored = await _storage.read(key: 'selected_language');
    if (stored != null) {
      state = stored;
    }
  }

  Future<void> setLanguage(String code) async {
    state = code;
    await _storage.write(key: 'selected_language', value: code);
  }
}

class LocalizationService {
  static final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'as', 'name': 'Assamese', 'native': 'অসমীয়া'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
    {'code': 'mni', 'name': 'Manipuri', 'native': 'মৈতৈলোন'},
    {'code': 'brx', 'name': 'Bodo', 'native': 'बर\''},
    {'code': 'mzo', 'name': 'Mizo', 'native': 'Mizo ṭawng'},
    {'code': 'kha', 'name': 'Khasi', 'native': 'Ka Ktien Khasi'},
    {'code': 'grt', 'name': 'Garo', 'native': 'A·chikku'},
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    // COMMON
    'mitracare': {
      'en': 'MitraCare', 'hi': 'मित्राकेयर', 'as': 'মিত্ৰাকেয়াৰ', 'bn': 'মিত্রাকেয়ার',
      'mni': 'মিত্রাকের', 'brx': 'मित्राकेयार', 'mzo': 'MitraCare', 'kha': 'MitraCare', 'grt': 'MitraCare'
    },
    'home': {
      'en': 'Home', 'hi': 'होम', 'as': 'ঘৰ', 'bn': 'হোম',
      'mni': 'য়ুম', 'brx': 'नख\'', 'mzo': 'In', 'kha': 'Iing', 'grt': 'Nok'
    },
    'help': {
      'en': 'Help', 'hi': 'मदद', 'as': 'সহায়', 'bn': 'সাহায্য',
      'mni': 'মতেং', 'brx': 'हेफाजाब', 'mzo': 'Tanpuina', 'kha': 'Jingyarap', 'grt': 'Dakchakan'
    },
    'cancel': {
      'en': 'Cancel', 'hi': 'रद्द करें', 'as': 'বাতিল কৰক', 'bn': 'বাতিল করুন',
      'mni': 'তোকউ', 'brx': 'बातिल खालाम', 'mzo': 'Tiahna', 'kha': 'Pynkynriah', 'grt': 'Watmbo'
    },
    'save': {
      'en': 'Save', 'hi': 'सहेजें', 'as': 'সংৰক্ষণ কৰক', 'bn': 'সংরক্ষণ করুন',
      'mni': 'থমউ', 'brx': 'दोन', 'mzo': 'Khawhna', 'kha': 'Pynneh', 'grt': 'Rikbo'
    },

    // GREETINGS
    'good_morning': {
      'en': 'Good Morning', 'hi': 'शुभ प्रभात', 'as': 'শুভ ৰাতিপুৱা', 'bn': 'শুভ সকাল',
      'mni': 'আয়ুক ফজর', 'brx': 'फुंबिलि', 'mzo': 'Zing chhibai', 'kha': 'Khublei mynstep', 'grt': 'Pringpat sok'
    },
    'good_afternoon': {
      'en': 'Good Afternoon', 'hi': 'शुभ दोपहर', 'as': 'শুভ দুপৰীয়া', 'bn': 'শুভ দুপুর',
      'mni': 'নুংথিল ফজর', 'brx': 'सानफाम', 'mzo': 'Chhun chhibai', 'kha': 'Khublei mynsngi', 'grt': 'Salaro sok'
    },
    'good_evening': {
      'en': 'Good Evening', 'hi': 'शुभ संध्या', 'as': 'শুভ আবেলি', 'bn': 'शुभ संध्या',
      'mni': 'নুমীদাং ফজর', 'brx': 'बेलाসে', 'mzo': 'Tlai chhibai', 'kha': 'Khublei jietjan', 'grt': 'Attam sok'
    },
    'default_name': {
      'en': 'Amma', 'hi': 'अम्मा', 'as': 'আই', 'bn': 'মা',
      'mni': 'ইমা', 'brx': 'आइ', 'mzo': 'Nu', 'kha': 'Mei', 'grt': 'Ma'
    },

    // HOME SCREEN
    'here_to_help': {
      'en': "I'm here to help you.",
      'hi': 'मैं यहाँ आपकी मदद के लिए हूँ।',
      'as': 'মই আপোনাক সহায় কৰিবলৈ ইয়াত আছো।',
      'bn': 'আমি এখানে আপনাকে সাহায্য করতে আছি।',
      'mni': 'ঐহাক নখোয়বু মতেং পাংনবা অমত্তা লৈরে।',
      'brx': 'आं नोंथां खौ हेफाजाब होनो थाखाय बेयाव दं।',
      'mzo': 'Tanpui tur che in ka awm e.',
      'kha': 'Nga don hangne ban yarap ia phi.',
      'grt': 'Ang nang·na dakchaktokna iaon don·a.'
    },
    'how_can_i_help': {
      'en': 'How can I help you today?',
      'hi': 'आज मैं आपकी क्या मदद कर सकता हूँ?',
      'as': 'আজি মই আপোনাক কেনেকৈ সহায় কৰিব পাৰো?',
      'bn': 'আজ আমি আপনাকে কীভাবে সাহায্য করতে পারি?',
      'mni': 'ঙসি ঐহাক্না করম্না মতেং পাংগদগে?',
      'brx': 'आं दिनै नोंथां खौ माबोरै हेफाजाब होनो हागौ?',
      'mzo': 'Vawiinah engtin nge ka tanpui theih che?',
      'kha': 'Kumno nga lah ban yarap ia phi mynta ka sngi?',
      'grt': 'Ia salo ang nang·na dakchakaniko dakna man·gen?'
    },
    'medicine_time': {
      'en': 'Medicine Time', 'hi': 'दवाई का समय', 'as': 'দৰবৰ সময়', 'bn': 'ওষুধের সময়',
      'mni': 'হিদাক থকপগী মতম', 'brx': 'मुलि लিরনায় সম', 'mzo': 'Damdawi ei hun', 'kha': 'Por dih dawai', 'grt': 'Sam eina somoy'
    },
    'time_for_medicine': {
      'en': "It's time for your medicine.",
      'hi': 'आपकी दवाई का समय हो गया है।',
      'as': 'আপোনাৰ দৰব খোৱাৰ সময় হৈছে।',
      'bn': 'আপনার ওষুধ খাওয়ার সময় হয়েছে।',
      'mni': 'নহাক্কী হিদাক থকপগী মতম ওইরে।',
      'brx': 'नोंथांनि मुलि लिरनाय সম जाबाय।',
      'mzo': 'I damdawi ei a hun tawh e.',
      'kha': 'La dei ka por ban dih dawai.',
      'grt': 'Nang·ni sam eina somoy ong·aha.'
    },
    'take_now': {
      'en': 'TAKE NOW', 'hi': 'अभी लें', 'as': 'এতিয়াই খাওক', 'bn': 'এখনই নিন',
      'mni': 'হৌজিক থকউ', 'brx': 'दानो ला', 'mzo': 'EI RAW', 'kha': 'DIH MYNTA', 'grt': 'IANO EE'
    },
    'tap_take_now': {
      'en': 'Tap TAKE NOW after you take your medicine.',
      'hi': 'दवाई लेने के बाद "अभी लें" पर टैप करें।',
      'as': "দৰব খোৱাৰ পিছত 'এতিয়াই খাওক' টিপক।",
      'bn': "ওষুধ খাওয়ার পর 'এখনই নিন' এ টিপুন।",
      'mni': "হিদাক থকপগী মতুংদা 'হৌজিক থকউ' টিপউ।",
      'brx': "मुलि जानायনি उनाव 'दानो ला' आव थु।",
      'mzo': "Damdawi i ei zawh ah 'EI RAW' hi hmet ang che.",
      'kha': "Thiat ia ka 'DIH MYNTA' ynda la dih dawai.",
      'grt': "Sam eimani ja·man 'IANO EE' ko neng·e uibo."
    },
    'all_medicines_taken': {
      'en': 'All medicines taken! 🎉', 'hi': 'सभी दवाइयाँ ले ली गई हैं! 🎉', 'as': 'সকলো দৰব খোৱা হ’ল! 🎉', 'bn': 'সব ওষুধ খাওয়া হয়েছে! 🎉',
      'mni': 'হিদাক পুম্নমক থকখ্রে! 🎉', 'brx': 'गासै मुलिया जाबाय! 🎉', 'mzo': 'Damdawi zawng zawng ei zawh tawh a ni! 🎉', 'kha': 'La dih dawai baroh! 🎉', 'grt': 'Pili samrangko cha·aha! 🎉'
    },
    'great_job': {
      'en': 'Great job! All caught up.', 'hi': 'बहुत बढ़िया! सब पूरा हो गया।', 'as': 'বৰ ধুনীয়া! সকলো শেষ হ’ল।', 'bn': 'খুব ভালো! সব সম্পন্ন হয়েছে।',
      'mni': 'য়াম্না ফৈ! পুম্নমক লোইখ্রে।', 'brx': 'जोबोद मोजां! गासैयाबो जोबबाय।', 'mzo': 'Hna tha tak! A zo ta.', 'kha': 'Kaba bha palat! Baroh la pynkut.', 'grt': 'Dakchong·aha! Pilan matchotaha.'
    },

    // CATEGORIES
    'play_game': {
      'en': 'Play Game', 'hi': 'खेल खेलें', 'as': 'খেল খেলক', 'bn': 'খেলা খেলুন',
      'mni': 'শান্নবা শানবা', 'brx': 'गेला गेले', 'mzo': 'Infiamna', 'kha': 'Mynhaka ialehkai', 'grt': 'Kal·a'
    },
    'play_game_sub': {
      'en': 'Fun brain games', 'hi': 'मस्तिष्क के मजेदार खेल', 'as': 'মগজুৰ আমোদজনক খেল', 'bn': 'মস্তিষ্কের মজাদার খেলা',
      'mni': 'লুকোন্দগী শান্নবা', 'brx': 'मोजां गेलेनायफोर', 'mzo': 'Rilru tichaktu', 'kha': 'Ialehkai pyrkhat', 'grt': 'Tan·sining kal·ani'
    },
    'recall_memory': {
      'en': 'Recall Memory', 'hi': 'यादें ताज़ा करें', 'as': 'স্মৃতি মনত পেলাওক', 'bn': 'স্মৃতিচারণ করুন',
      'mni': 'নিংসিংবা শিংথাবা', 'brx': 'गोसोखां गोसो', 'mzo': 'Hriatna hloh loh nan', 'kha': 'Kynmaw', 'grt': 'Gisik ra·taianian'
    },
    'recall_memory_sub': {
      'en': 'Train memory skills', 'hi': 'याददाश्त का अभ्यास करें', 'as': 'স্মৃতিশক্তি বৃদ্ধি কৰক', 'bn': 'স্মৃতিশক্তি বাড়ান',
      'mni': 'নিংসিংবা হেনগৎহনবা', 'brx': 'गोसोखांनाय रोंगौथि', 'mzo': 'Hriatna tihchakna', 'kha': 'Pynkhlain jingkynmaw', 'grt': 'Gisik ra·gipa bil'
    },
    'my_day_label': {
      'en': 'My Day', 'hi': 'मेरा दिन', 'as': 'মোৰ দিনটো', 'bn': 'আমার দিন',
      'mni': 'ঐহাক্কী নুমিৎ', 'brx': 'आंनि दिन', 'mzo': 'Ka Ni', 'kha': 'Ka Sngi Jong Nga', 'grt': 'Ang·ni Sal'
    },
    'my_day_sub': {
      'en': 'Your daily plan', 'hi': 'आपकी दैनिक योजना', 'as': 'আপোনাৰ দৈনিক কৰ্মসূচী', 'bn': 'আপনার দৈনন্দিন পরিকল্পনা',
      'mni': 'নুমিৎ খুদিংগী থৌরাং', 'brx': 'सोंनाय खान्थिफোর', 'mzo': 'Nitin ruahmanna', 'kha': 'Pynkhreh baroh sngi', 'grt': 'Salo dakgnigipa chol'
    },
    'reminders_label': {
      'en': 'Reminders', 'hi': 'याद दिलाना', 'as': 'স্মাৰকসমূহ', 'bn': 'রিমাইন্ডার',
      'mni': 'নিংসিংহনবা', 'brx': 'गोसोखां होनाय', 'mzo': 'Hriattirna', 'kha': 'Jingpynkynmaw', 'grt': 'Gisik ra·atgiparang'
    },
    'reminders_sub': {
      'en': 'Meds, water & more', 'hi': 'दवा, पानी और अन्य', 'as': 'দৰব, পানী আৰু অন্যান্য', 'bn': 'ওষুধ, জল এবং আরও কিছু',
      'mni': 'হিদাক, ঈশিং অমসুং অতৈ', 'brx': 'मुलि, दै आरो गुबुन', 'mzo': 'Damdawi, tui, adang te', 'kha': 'Dawai, um bad kiwei', 'grt': 'Sam, chi aro gipinrang'
    },

    // PLAY GAME SCREEN
    'choose_activity': {
      'en': 'Choose something to do today:', 'hi': 'आज करने के लिए कुछ चुनें:', 'as': 'আজি কৰিবলৈ কিবা বাছক:', 'bn': 'আজ করার জন্য কিছু নির্বাচন করুন:',
      'mni': 'ঙসি করমবা শান্নগে খলউ:', 'brx': 'दिनै मावनाय सायख:', 'mzo': 'Vawiina tih tur thlang rawh:', 'kha': 'Jied ia kaba de leh mynta:', 'grt': 'Salo dakgnigipako jiedbo:'
    },
    'recent_activity': {
      'en': 'Recent Activity', 'hi': 'हालिया गतिविधि', 'as': 'শেহতীয়া কাৰ্য্যকলাপ', 'bn': 'সাম্প্রতিক ক্রিয়াকলাপ',
      'mni': 'হৌখ্রবা থবক', 'brx': 'दानो खालामनाय मावनाय', 'mzo': 'Thiltih thar te', 'kha': 'Jingialehkai khadduh', 'grt': 'Gital daka'
    },
    'memory_recall_section': {
      'en': 'Memory & Recall', 'hi': 'स्मृति और स्मरण', 'as': 'স্মৃতি আৰু স্মৃতিশক্তি', 'bn': 'স্মৃতি ও স্মরণশক্তি',
      'mni': 'নিংসিংবা অমসুং লুহাংবা', 'brx': 'गोसोखां होनाय', 'mzo': 'Hriatna lam', 'kha': 'Jingkynmaw', 'grt': 'Gisik ra·ani'
    },
    'attention_focus': {
      'en': 'Attention & Focus', 'hi': 'ध्यान और एकाग्रता', 'as': 'মনোযোগ আৰু একাগ্ৰতা', 'bn': 'মনোযোগ ও একাগ্রতা',
      'mni': 'মিৎয়েং অমসুং পুক্নিং থমবা', 'brx': 'गोसो होनाय', 'mzo': 'Ngaihtuahna pekna', 'kha': 'Jingpynleit jingmut', 'grt': 'Gisik on·ani'
    },
    'play_btn': {
      'en': 'PLAY', 'hi': 'खेलें', 'as': 'খেলক', 'bn': 'খেলুন',
      'mni': 'শান্নউ', 'brx': 'गेले', 'mzo': 'KHEL RAWH', 'kha': 'IALEHKAI', 'grt': 'KAL·BO'
    },
    'activity_history': {
      'en': 'Activity History', 'hi': 'गतिविधि इतिहास', 'as': 'কাৰ্য্যকলাপৰ ইতিহাস', 'bn': 'ক্রিয়াকলাপের ইতিহাস',
      'mni': 'শান্নখিবগী পুৱারী', 'brx': 'मावनाय जारमिन', 'mzo': 'Mizia chanchin', 'kha': 'Jingialehkai baroh', 'grt': 'Itihas kal·a'
    },
    'completed': {
      'en': 'Completed', 'hi': 'पूरा हुआ', 'as': 'সম্পূৰ্ণ হ’ল', 'bn': 'সম্পন্ন',
      'mni': 'লোইখ্রে', 'brx': 'जोबबाय', 'mzo': 'Zawh tawh', 'kha': 'La pynkut', 'grt': 'Matchotaha'
    },
    'score': {
      'en': 'Score', 'hi': 'अंक', 'as': 'স্কোৰ', 'bn': 'স্কোর',
      'mni': 'পয়েন্ট', 'brx': 'नम्बर', 'mzo': 'Mark/Pawn', 'kha': 'Khusnam', 'grt': 'Score'
    },
    'points': {
      'en': 'pts', 'hi': 'अंक', 'as': 'পইণ্ট', 'bn': 'পয়েন্ট',
      'mni': 'পয়েন্ট', 'brx': 'नम्बर', 'mzo': 'pts', 'kha': 'points', 'grt': 'points'
    },

    // RECALL MEMORY SCREEN
    'recall_daily_events': {
      'en': 'Recall Daily Events', 'hi': 'दैनिक घटनाओं को याद करें', 'as': 'দৈনিক ঘটনাবোৰ মনত পেলাওক', 'bn': 'দৈনিক ঘটনাগুলি স্মরণ করুন',
      'mni': 'নুমিৎ খুদিংগী থৌদোক নিংসিংবা', 'brx': 'सानफ्रामनि जाथायफोरखौ गोसोखां', 'mzo': 'Nitin thilthleng hriatna', 'kha': 'Kynmaw ia ki kam baroh sngi', 'grt': 'Santi dakgiparanggisik ra·ani'
    },
    'recall_daily_events_sub': {
      'en': 'Recall what you did today', 'hi': 'याद करें कि आपने आज क्या किया', 'as': 'আজি আপুনি কি কৰিলে মনত পেলাওক', 'bn': 'আজ আপনি কী করেছেন তা স্মরণ করুন',
      'mni': 'ঙসি নহাক করম্না শানখিবগে নিংসিংবা', 'brx': 'दिनै मा खालामदोंमोन गोसोखां', 'mzo': 'Vawiina i thiltih te ngaihtuah let rawh', 'kha': 'Kynmaw ia kaba phi la leh mynta ka sngi', 'grt': 'Salo nang·ni dakgipa kamranggisik ra·bo'
    },
    'name_that_object': {
      'en': 'Name That Object', 'hi': 'वस्तु का नाम बताएं', 'as': 'বস্তু চিনাক্ত কৰক', 'bn': 'বস্তুটি সনাক্ত করুন',
      'mni': 'পোৎশক অদুগী মিং কোউ', 'brx': 'मुवाफोरनि मुं लिर', 'mzo': 'Thil hming sawina', 'kha': 'Jer ia u mar', 'grt': 'Ua Bostuko mingbo'
    },
    'name_that_object_sub': {
      'en': 'Identify everyday household items', 'hi': 'रोजमर्रा की घरेलू वस्तुओं की पहचान करें', 'as': 'দৈনিক ঘৰুৱা বস্তুবোৰ চিনাক্ত কৰক', 'bn': 'দৈনন্দিন গৃহস্থালীর জিনিসপত্র চিহ্নিত করুন',
      'mni': 'য়ুমদা শীজিন্নবা পোৎশিং চিন্নিবা', 'brx': 'नख\'आव बाहायনায় মুवाफोर सिनायनाय', 'mzo': 'Ina thil hman thin te sawi rawh', 'kha': 'Kynmaw ia ki tiar ha iing', 'grt': 'Noko jakkalgipa bosturangko uibo'
    },
    'sequence_memory': {
      'en': 'Sequence Memory', 'hi': 'क्रम स्मृति', 'as': 'ক্ৰম স্মৃতিশক্তি', 'bn': 'সিকোয়েন্স मेमरी',
      'mni': 'মথং মথং নিংসিংবা', 'brx': 'फारिलाइ गोसोखां', 'mzo': 'Indawt zela hriatna', 'kha': 'Kynmaw ia kaba wan bud', 'grt': 'Sanggipa gisik ra·ani'
    },
    'sequence_memory_sub': {
      'en': 'Repeat a pattern of lights or sounds', 'hi': 'रोशनी या आवाज़ के पैटर्न को दोहराएं', 'as': 'পোহৰ বা শব্দৰ আৰ্হি পুনৰাবৃত্তি কৰক', 'bn': 'আলো বা শব্দের একটি প্যাটার্ন পুনরাবৃত্তি করুন',
      'mni': 'মঙাল নত্রগা মখোলগী চৎনবী হঞ্জিনবা', 'brx': 'रोशनाइ एबा सोदोबनि फारिखौ खालामफिन', 'mzo': 'Ri leh a ri dan zui rawh', 'kha': 'Kyntiew ia ka rukom thaba lane sawa', 'grt': 'Seng·ani aro gam·aniko daktaibo'
    },
    'word_recall': {
      'en': 'Word Recall', 'hi': 'शब्द स्मरण', 'as': 'শব্দ মনত পেলোৱা', 'bn': 'শব্দ স্মরণ',
      'mni': 'ৱাহৈ নিংসিংবা', 'brx': 'सोदोब गोसोखां', 'mzo': 'Thumal hriatna', 'kha': 'Kynmaw kyntien', 'grt': 'Kattaranggisik ra·ani'
    },
    'word_recall_sub': {
      'en': 'Memorize and repeat a list of words', 'hi': 'शब्दों की सूची याद रखें और दोहराएं', 'as': 'শব্দৰ তালিকা মনত ৰাখক আৰু পুনৰাবৃত্তি কৰক', 'bn': 'শব্দের একটি তালিকা মুখস্থ করুন এবং পুনরাবৃত্তি করুন',
      'mni': 'ৱাহৈশিং নিংসিংদুনা হঞ্জিনবা', 'brx': 'सोदोबफोरखौ गोसोआव दोन आरो खालामफिन', 'mzo': 'Thumal lo vawngin sawi chhuak leh rawh', 'kha': 'Kynmaw bad kyntiew ia ki kyntien', 'grt': 'Kattarangko gisik ra·e daktaibo'
    },

    // MY DAY SCREEN
    'your_tasks_today': {
      'en': 'Your Tasks for Today', 'hi': 'आज के आपके कार्य', 'as': 'আপোনাৰ আজিৰ কামসমূহ', 'bn': 'আজকের আপনার কাজ',
      'mni': 'ঙসি নহাক্কী থবকশিং', 'brx': 'दिनै नोंथांनि मावनो गोनां मावनायफोर', 'mzo': 'Vawiina i hna te', 'kha': 'Kam jong phi mynta ka sngi', 'grt': 'Nang·ni salo dakgnigipa kamrang'
    },
    'snooze': {
      'en': 'SNOOZE', 'hi': 'अलार्म बढ़ाएं', 'as': 'পাছত কৰিব', 'bn': 'স্নুজ',
      'mni': 'তুংদা থমউ', 'brx': 'सम बढ़ाओ', 'mzo': 'TUAILOH', 'kha': 'SANGE SHIBIT', 'grt': 'RU·UTATBO'
    },
    'skip': {
      'en': 'SKIP', 'hi': 'छोड़ें', 'as': 'वाद দিয়ক', 'bn': 'বাদ দিন',
      'mni': 'হান্থউ', 'brx': 'नागार', 'mzo': 'KHEL', 'kha': 'RYNGKOH', 'grt': 'WAT DAKBO'
    },
    'pending': {
      'en': 'Pending', 'hi': 'लंबित', 'as': 'বাকি থকা', 'bn': 'বাকি আছে',
      'mni': 'লৈহৌরিবা', 'brx': 'नेनाय दं', 'mzo': 'La ti loh', 'kha': 'Sah', 'grt': 'Dongkuenga'
    },
    'skipped': {
      'en': 'Skipped', 'hi': 'छोड़ दिया', 'as': 'বাদ দিয়া হ’ল', 'bn': 'বাদ দেওয়া হয়েছে',
      'mni': 'হান্থখ্রে', 'brx': 'नागारबाय', 'mzo': 'Khel tawh', 'kha': 'La ryngkoh', 'grt': 'Wat dakahaba'
    },
    'snoozed': {
      'en': 'Snoozed', 'hi': 'बढ़ा दिया', 'as': 'পাছলৈ থোৱা হ’ল', 'bn': 'স্নুজ করা হয়েছে',
      'mni': 'তুংদা থমখ্রে', 'brx': 'सम बढ़ाबाय', 'mzo': 'Tuailoh tawh', 'kha': 'La sange shibit', 'grt': 'Ru·utatahaba'
    },

    // DYNAMIC BACKEND KEYS
    'find_the_match': {
      'en': 'Find the Match', 'hi': 'मिलान खोजें', 'as': 'মিল বাছক', 'bn': 'মিল খুঁজুন',
      'mni': 'চান্নবা খলউ', 'brx': 'मोजां गेलेनाय सायख', 'mzo': 'A mi thlang rawh', 'kha': 'Shem ia kaba pyniasyriem', 'grt': 'Meligipa jiedbo'
    },
    'remember_pictures': {
      'en': 'Remember Pictures', 'hi': 'चित्र याद रखें', 'as': 'ছবি মনত ৰাখক', 'bn': 'ছবি মনে রাখুন',
      'mni': 'লাই নিংসিংবা', 'brx': 'सावगारि गोसोखां', 'mzo': 'Thlalak hriatna', 'kha': 'Kynmaw ia ki dur', 'grt': 'Noksarangko gisik ra·bo'
    },
    'spot_the_difference': {
      'en': 'Spot the Difference', 'hi': 'अंतर पहचानें', 'as': 'প্ৰভেদ বিচাৰক', 'bn': 'পার্থক্য খুঁজুন',
      'mni': 'খেন্নবা খলউ', 'brx': 'फराखथि सायख', 'mzo': 'Danglamna zawnna', 'kha': 'Shem ia kaba iapher', 'grt': 'Dingtanganiko neng·bo'
    },
    'sort_and_arrange': {
      'en': 'Sort and Arrange', 'hi': 'क्रमबद्ध करें', 'as': 'সজাওক আৰু মিলাওক', 'bn': 'সাজিয়ে গুছিয়ে রাখুন',
      'mni': 'মথং মথং শেমউ', 'brx': 'फारिलाइ दोन', 'mzo': 'Rem/Siam tha rawh', 'kha': 'Rukom bad pynbiang', 'grt': 'Sanggipa donbo'
    },
    'take_morning_med': {
      'en': 'Take Morning Medicine', 'hi': 'सुबह की दवा लें', 'as': 'ৰাতিপুৱাৰ দৰব খাওক', 'bn': 'সকালের ওষুধ নিন',
      'mni': 'অয়ুক্কী হিদাক থকউ', 'brx': 'फुंनि मुलि ला', 'mzo': 'Zing damdawi ei rawh', 'kha': 'Dih dawai mynstep', 'grt': 'Pringni sam cha·bo'
    },
    'morning_med': {
      'en': 'Morning Medicine', 'hi': 'सुबह की दवा', 'as': 'ৰাতিপুৱাৰ দৰব', 'bn': 'সকালের ওষুধ',
      'mni': 'অয়ুক্কী হিদাক', 'brx': 'फुंनि मुलि', 'mzo': 'Zing damdawi', 'kha': 'Dawai mynstep', 'grt': 'Pringni sam'
    },
    'evening_med': {
      'en': 'Evening Medicine', 'hi': 'शाम की दवा', 'as': 'সন্ধিয়াৰ দৰব', 'bn': 'সন্ধ্যার ওষুধ',
      'mni': 'নুমীদাং হিদাক', 'brx': 'बेलासे मुलि', 'mzo': 'Tlai damdawi', 'kha': 'Dawai jietjan', 'grt': 'Attamni sam'
    },
    'drink_water_task': {
      'en': 'Drink Water', 'hi': 'पानी पीयें', 'as': 'পানী খাওক', 'bn': 'জল পান করুন',
      'mni': 'ঈশিং থকউ', 'brx': 'दै लो', 'mzo': 'Tui in rawh', 'kha': 'Dih um', 'grt': 'Chi ringbo'
    },
    'memory_game_task': {
      'en': 'Memory Game', 'hi': 'दिमागी खेल', 'as': 'স্মৃতিশক্তিৰ খেল', 'bn': 'স্মৃতিশক্তির খেলা',
      'mni': 'নিংসিংবা শান্নবা', 'brx': 'गोसोखां खेला', 'mzo': 'Hriatna game', 'kha': 'Ialehkai pyrkhat', 'grt': 'Gisik ra·ani kal·a'
    },
    'lunch_time_task': {
      'en': 'Lunch Time', 'hi': 'दोपहर का भोजन', 'as': 'দুপৰীয়াৰ আহাৰ', 'bn': 'দুপুরের খাবার',
      'mni': 'নুংথিলগী চাক চাবা', 'brx': 'सानफामनि जानाय', 'mzo': 'Chhun chaw ei', 'kha': 'Por bam sngi', 'grt': 'Salaroni cha·ani'
    },
    'doctor_appt_task': {
      'en': 'Doctor Appointment', 'hi': 'डॉक्टर से मिलना', 'as': 'চিকিৎসকৰ সাক্ষাৎ', 'bn': 'ডাক্তারের অ্যাপয়েন্টমেন্ট',
      'mni': 'দা ক্তর উন্নবা মতম', 'brx': 'डक्टर लोगोजानाय', 'mzo': 'Doctor inbiakna', 'kha': 'Bthah ia u doctor', 'grt': 'Doctorona ringani'
    },
'morning_med_desc': {
      'en': "It's time for your morning medicine.", 'hi': 'आपकी सुबह की दवाई का समय हो गया है।', 'as': 'আপোনাৰ ৰাতিপুৱাৰ দৰব খোৱাৰ সময় হৈছে।', 'bn': 'আপনার সকালের ওষুধ খাওয়ার সময় হয়েছে।',
      'mni': 'নহাক্কী অয়ুক্কী হিদাক থকপগী মতম ওইরে।', 'brx': 'नोंथांनि फुंनि मुलि लिरनाय सम जाबाय।', 'mzo': 'I zing damdawi ei a hun tawh e.', 'kha': 'La dei ka por dih dawai mynstep.', 'grt': 'Pringni sam ringani somoy ong·aha.'
    },
    'drink_water_desc': {
      'en': 'Drink a glass of water to stay hydrated.', 'hi': 'स्वस्थ रहने के लिए एक गिलास पानी पीयें।', 'as': 'পানী খাই শৰীৰটো সুস্থ ৰাখক।', 'bn': 'শরীর সতেজ রাখতে এক গ্লাস জল পান করুন।',
      'mni': 'ঈশিং গ্লাস অমা থকউ।', 'brx': 'दै ग्लाससे लो मोजां थानो।', 'mzo': 'Tui no khat in la stay healthy rawh.', 'kha': 'Dih khyndiat um ban khlain ka met.', 'grt': 'A·chik cha·gipa chi ringbo.'
    },
    'memory_game_desc': {
      'en': 'Play a cognitive exercise to keep your brain active.', 'hi': 'मस्तिष्क को सक्रिय रखने के लिए खेलें।', 'as': 'মগজু সক্ৰিয় ৰাখিবলৈ খেল খেলক।', 'bn': 'মস্তিষ্ক সচল রাখতে কগনিটিভ খেলা খেলুন।',
      'mni': 'লুকোন্দগী শান্নদুনা লৈউ।', 'brx': 'गोसोखांनाय खेला गेले गोसो मोजां थानो।', 'mzo': 'Rilru tihchak nan in fiam rawh.', 'kha': 'Ialehkai ban pynkhlain jingmut.', 'grt': 'Tan·sining bilakna kal·bo.'
    },
    'lunch_desc': {
      'en': 'Enjoy a balanced healthy lunch.', 'hi': 'संतुलित और स्वस्थ दोपहर का भोजन करें।', 'as': 'দুপৰীয়াৰ সুষম আহাৰ গ্ৰহণ কৰক।', 'bn': 'সুষম ও পুষ্টিকর দুপুরের খাবার খান।',
      'mni': 'নুংথিলগী সুষম চাক চাউ।', 'brx': 'सानफामनि मोजां जानाय जा।', 'mzo': 'Chhun chaw tui tak ei rawh.', 'kha': 'Bam ja sngi kaba pynbha ka met.', 'grt': 'Suh-sokgipa salaroni cha·aniko cha·bo.'
    },
    'doctor_appt_desc': {
      'en': 'Standard checkup at health center.', 'hi': 'स्वास्थ्य केंद्र पर सामान्य जाँच।', 'as': 'স্বাস্থ্য কেন্দ্ৰত নিয়মীয়া পৰীক্ষা।', 'bn': 'স্বাস্থ্যকেন্দ্রে নিয়মিত পরীক্ষা-নিরীক্ষা।',
      'mni': 'হসপিটালদা লোক চৎপা।', 'brx': 'डक्टरनि सावनाय नख\'आव।', 'mzo': 'Damdawi in a checkup nei rawh.', 'kha': 'Sumar doctor ha iing sumar.', 'grt': 'Sawa checkup dakbo.'
    },
    'evening_med_desc': {
      'en': 'Take your evening medicine.', 'hi': 'अपनी शाम की दवाई लें।', 'as': 'আপোনাৰ সন্ধিয়াৰ দৰব খাওক।', 'bn': 'আপনার সন্ধ্যার ওষুধ নিন।',
      'mni': 'নহাক্কী নুমীদাং হিদাক থকউ।', 'brx': 'नोंथांनि बेलासे मुलि ला।', 'mzo': 'I tlai damdawi ei rawh.', 'kha': 'Dih dawai jietjan.', 'grt': 'Nang·ni attamni sam ringbo.'
    },
    'bihu_drum_rhythm': {
      'en': 'Bihu Drum Rhythm', 'hi': 'बिहू ढोल ताल', 'as': 'বিহু ঢোলৰ তাল', 'bn': 'বিহু ঢাকের তাল',
      'mni': 'বিহু পুংগী খোঞ্জেল', 'brx': 'बिहु ड्रम ताल', 'mzo': 'Bihu Drum Rhythm', 'kha': 'Bihu Drum Rhythm', 'grt': 'Bihu Drum Rhythm'
    },
    'bihu_drum_rhythm_desc': {
      'en': 'Match the Bihu rhythm sequence', 'hi': 'बिहू ताल अनुक्रम का मिलान करें', 'as': 'বিহু তালৰ ক্ৰম মিলাওক', 'bn': 'বিহু তাল অনুক্রম মেলান',
      'mni': 'বিহু খোঞ্জেল শেমদুনা মিলাইউ', 'brx': 'बिहु ड्रम ताल मिलाय', 'mzo': 'Bihu drum riatna', 'kha': 'Kyntiew sur Bihu', 'grt': 'Bihu drum dakatani'
    },
    'sort_harvest': {
      'en': 'Sort the Harvest', 'hi': 'फसल का वर्गीकरण', 'as': 'ফচল শ্ৰেণীবিভাজন', 'bn': 'ফসল শ্রেণীবদ্ধকরণ',
      'mni': 'লৌথোক লৈথোকখাইবা', 'brx': 'फसल खौ सायखनाय', 'mzo': 'Hlo thlawh heu', 'kha': 'Khia ia ki jingthung', 'grt': 'Gittaggalan'
    },
    'sort_harvest_desc': {
      'en': 'Sort Assam tea and chillies', 'hi': 'असम चाय और मिर्च को छांटें', 'as': 'অসমৰ চাহ আৰু জলকীয়া বাচি উলিওৱা', 'bn': 'আসাম চা এবং লঙ্কা আলাদা করুন',
      'mni': 'অসাম চা অমসুং মোমোরি খাইদোকউ', 'brx': 'असाम साह आरो मुस्रि सायख', 'mzo': 'Chai hnah leh hmarcha thliah', 'kha': 'Pyniasoh sla sha bad sohmyngken', 'grt': 'Assam cha aro jalikrangko gittaggalbo'
    },
    'northeast_word_search': {
      'en': 'Northeast Word Search', 'hi': 'पूर्वोत्तर शब्द पहेली', 'as': 'উত্তৰ-পূবৰ শব্দ অনুসন্ধান', 'bn': 'উত্তর-পূর্বের শব্দ সন্ধান',
      'mni': 'উত্তৰ-পূবগী ৱাহৈ থিবা', 'brx': 'पूर्वोत्तर सोदोब सायখनाय', 'mzo': 'Northeast Word Search', 'kha': 'Northeast Word Search', 'grt': 'Northeast Word Search'
    },
    'northeast_word_search_desc': {
      'en': 'Unscramble Northeast heritage words', 'hi': 'पूर्वोत्तर विरासत शब्दों को सुलझाएं', 'as': 'উত্তৰ-পূবৰ ঐতিহ্যবাহী শব্দ মিলাওক', 'bn': 'উত্তর-পূর্ব ঐতিহ্যবাহী শব্দ সাজান',
      'mni': 'উত্তৰ-পূবগী লোনশিন লৈথোকউ', 'brx': 'पूर्वोत्तर गोसोखां सोदोबफोर', 'mzo': 'Northeast thumal zawnna', 'kha': 'Pynbeit ktien Northeast', 'grt': 'Northeast kattarangko tik dakbo'
    },

    // REMINDERS SCREEN
    'filter_all': {
      'en': 'All', 'hi': 'सभी', 'as': 'সকলো', 'bn': 'সব',
      'mni': 'পুম্নমক', 'brx': 'गासै', 'mzo': 'Zawng zawng', 'kha': 'Baroh', 'grt': 'Pilak'
    },
    'filter_meds': {
      'en': 'Medicines', 'hi': 'दवाइयाँ', 'as': 'দৰবসমূহ', 'bn': 'ওষুধ',
      'mni': 'হিদাক', 'brx': 'मुली', 'mzo': 'Damdawi te', 'kha': 'Ki Dawai', 'grt': 'Samrang'
    },
    'filter_water': {
      'en': 'Water', 'hi': 'पानी', 'as': 'পানী', 'bn': 'জল',
      'mni': 'ঈশিং', 'brx': 'दै', 'mzo': 'Tui', 'kha': 'Um', 'grt': 'Chi'
    },
    'filter_acts': {
      'en': 'Activities', 'hi': 'गतिविधियाँ', 'as': 'কাৰ্য্যকলাপ', 'bn': 'ক্রিয়াকলাপ',
      'mni': 'থবকশিং', 'brx': 'मावनायफोर', 'mzo': 'Thiltih te', 'kha': 'Ki Jingtrei', 'grt': 'Kamrang'
    },
    'add_reminder': {
      'en': 'ADD REMINDER', 'hi': 'नया अनुस्मारक जोड़ें', 'as': 'স্মাৰক যোগ কৰক', 'bn': 'রিমাইন্ডার যোগ করুন',
      'mni': 'নিংসিংহনবা হাপউ', 'brx': 'गोसोखां होनाय दाजाब', 'mzo': 'HRIATTIRNA DAH RAWH', 'kha': 'PYNDAP JINGPYNKYNMAW', 'grt': 'Gisik ra·atgipa on·bo'
    },
    'add_new_reminder': {
      'en': 'Add New Reminder', 'hi': 'नया अनुस्मारक जोड़ें', 'as': 'নতুন স্মাৰক যোগ কৰক', 'bn': 'নতুন রিমাইন্ডার যোগ করুন',
      'mni': 'অৌবা নিংসিংহনবা হাপউ', 'brx': 'गोदान गोसोखां होनाय दाजाब', 'mzo': 'Hriattirna thar siamna', 'kha': 'Pynkynmaw bathymmai', 'grt': 'Gital gisik ra·atgipa dakbo'
    },
    'reminder_title': {
      'en': 'Reminder Title', 'hi': 'अनुस्मारक शीर्षक', 'as': 'স্মাৰকৰ শীৰ্ষক', 'bn': 'রিমাইন্ডার শিরোনাম',
      'mni': 'নিংসিংহনবগী মিং', 'brx': 'गोसोखां होनाय मुं', 'mzo': 'A chanchin tawi', 'kha': 'Kyrteng Jingpynkynmaw', 'grt': 'Gisik ra·atgipani title'
    },
    'select_time': {
      'en': 'Select Time', 'hi': 'समय चुनें', 'as': 'समय বাছক', 'bn': 'समय निर्वाचन করুন',
      'mni': 'মতম খলউ', 'brx': 'सम सायख', 'mzo': 'A hun thlang rawh', 'kha': 'Jied Por', 'grt': 'Somoyko jiedbo'
    },
    'select_type': {
      'en': 'Select Type', 'hi': 'प्रकार चुनें', 'as': 'প্ৰকাৰ বাছক', 'bn': 'ধরন निर्वाचन করুন',
      'mni': 'মখল খলউ', 'brx': 'रोख सायख', 'mzo': 'A chi thlang rawh', 'kha': 'Jied rukom', 'grt': 'Malko jiedbo'
    },

    // HELP SCREEN
    'here_for_you': {
      'en': 'We are here for you', 'hi': 'हम यहाँ आपके लिए हैं', 'as': 'আমি আপোনাৰ বাবে ইয়াত আছো', 'bn': 'আমরা এখানে আপনার জন্য আছি',
      'mni': 'ঐখোয় নহাক্কীদমক লৈরে', 'brx': 'जों बेयाव नोंथांनि थाखाय दं', 'mzo': 'I tan kan awm e', 'kha': 'Ngi don hangne bad phi', 'grt': 'Chinga nang·na iaon donga'
    },
    'tap_below': {
      'en': 'Tap below to talk or call.', 'hi': 'बात करने या कॉल करने के लिए नीचे टैप करें।', 'as': 'কথা পাতিবলৈ বা কল কৰিবলৈ তলত টিপক।', 'bn': 'কথা বলতে বা কল করতে নিচে টিপুন।',
      'mni': 'ৱা ফংনবা নত্রগা ফোন তৌনবা মখাদা টিপউ।', 'brx': 'रायलायने एबा कल खालामनो गाहायाव थु।', 'mzo': 'Be tawng turin a hnuai lam hi hmet rawh.', 'kha': 'Thiat ha trai ban kren lane phone.', 'grt': 'Aganchina ba ringchina ka·mao neng·bo.'
    },
    'call_caregiver': {
      'en': 'Call My Caregiver', 'hi': 'देखपालकर्ता को कॉल करें', 'as': 'যত্ন লওঁতাজনক কল কৰক', 'bn': 'কেয়ারগিভারকে কল করুন',
      'mni': 'ঐহাক্কী য়েনশিনবীবু ফোন তৌবা', 'brx': 'सावनायगिरिखौ कल खालाम', 'mzo': 'Caregiver call rawh', 'kha': 'Kren ia u nongsumar', 'grt': 'Caregiverna ringbo'
    },
    'talk_caregiver': {
      'en': 'Talk to your caregiver', 'hi': 'अपने देखभालकर्ता से बात करें', 'as': 'আপোনাৰ যত্ন লওঁতাজনৰ সৈতে কথা পাতক', 'bn': 'আপনার কেয়ারগিভারের সাথে কথা বলুন',
      'mni': 'য়েনশিনবীবু ৱা তাউ', 'brx': 'सावनायगिरिजों रायलाय', 'mzo': 'I caregiver be khan tawng rawh', 'kha': 'Kren ia u nongbsah jong phi', 'grt': 'Nang·ni caregiverna aganbo'
    },
    'voice_help': {
      'en': 'Voice Help', 'hi': 'आवाज़ से मदद', 'as': 'মাতৰ সহায়', 'bn': 'কন্ঠস্বর সাহায্য',
      'mni': 'খোঞ্জেল মতেং', 'brx': 'सोदोब हेफाजाब', 'mzo': 'Tawngna tanpuina', 'kha': 'Jingyarap ryngkat jingkren', 'grt': 'Ku·rang dakchakan'
    },
    'tell_need': {
      'en': 'Tell us what you need', 'hi': 'हमें बताएं कि आपको क्या चाहिए', 'as': 'আপোনাক কি প্ৰয়োজন আমাক কওক', 'bn': 'আপনার কী প্রয়োজন আমাদের জানান',
      'mni': 'নহাক্কী করমবা মতেং পামগে ঐখোয়দা হংউ', 'brx': 'नोंथाङा मा लुबैदों जोंनो बुं', 'mzo': 'I mamawh sawi rawh', 'kha': 'Iathuh ia nga ia kaba phi donkam', 'grt': 'Nang·ni nanganiko aganbo'
    },
    'emergency_warning': {
      'en': 'If this is an emergency, please ask someone nearby or call local emergency services.',
      'hi': 'यदि यह कोई आपातकालीन स्थिति है, तो कृपया पास के किसी व्यक्ति से कहें या स्थानीय आपातकालीन सेवाओं को कॉल करें।',
      'as': 'যদি জৰুৰীকালীন অৱস্থা হয়, তেন্তে ওচৰৰ কাৰোবাৰ সহায় লওক বা জৰুৰীকালীন সেৱাক কল কৰক।',
      'bn': 'যদি এটি জরুরি অবস্থা হয়, তবে অনুগ্রহ করে কাছের কারও সাহায্য নিন বা স্থানীয় জরুরি পরিষেবায় কল করুন।',
      'mni': 'অকন্নবা থৌদোক ওইরবদি, অকনবা মতেং লাউ নত্রগা ইমারজেন্সি সেৱা কোল তৌউ।',
      'brx': 'जुदि बेयो जोबोद गोनां सम जायो, अननानै साखाथिनि सुबुंफोरखौ बुं एबा कल खालाम।',
      'mzo': 'Hmanhmawhthlak a nih chuan, mi dang kha tanpuina dil vat la, emergency call rawh.',
      'kha': 'Lada don jingmynsaw lane ba khia, iarap ia uba don hajan lane khot emergency.',
      'grt': 'Ia obostha nang·na neng·nikani ong·ode, sepanggipa mandena aganbo ba emergency rang·san ringbo.'
    },
    'calling': {
      'en': 'Calling', 'hi': 'कॉल किया जा रहा है', 'as': 'কল কৰা হৈছে', 'bn': 'কল করা হচ্ছে',
      'mni': 'ফোন তৌরি', 'brx': 'कल खालामगासिनो', 'mzo': 'Call mek a ni', 'kha': 'Khot...', 'grt': 'Ringenga'
    },

    // VOICE ASSISTANT SHEET
    'im_listening': {
      'en': "I'm listening...", 'hi': 'मैं सुन रहा हूँ...', 'as': 'মই শুনি আছো...', 'bn': 'আমি শুনছি...',
      'mni': 'ঐহাক তাগনি...', 'brx': 'आं खोनासं गासिनो...', 'mzo': 'Ka ngaithla reng e...', 'kha': 'Nga sngap...', 'grt': 'Ang knienga...'
    },
    'listening': {
      'en': 'Listening...', 'hi': 'सुन रहा हूँ...', 'as': 'শুনি आছো...', 'bn': 'শুনছি...',
      'mni': 'তাগনি...', 'brx': 'खोनासं...', 'mzo': 'Ngaithla...', 'kha': 'Sngap...', 'grt': 'Knienga...'
    },
    'voice_instruction': {
      'en': 'Say "I need help" or "water"', 'hi': '"मुझे मदद चाहिए" या "पानी" कहें', 'as': '"মোক সহায় লাগে" বা "পানী" কওক', 'bn': '"আমার সাহায্য চাই" বা "জল" বলুন',
      'mni': '"ঐহাক মতেং পাম্মী" নত্রগা "ঈশিং" হাইয়ু', 'brx': '"आं हेफाजाब लुबैदों" एबा "दै" बुं', 'mzo': '"Tui" emaw "Tanpuina ka mamawh" ti rawh', 'kha': 'Kren "Nga donkam jingyarap" lane "um"', 'grt': '"Dakchakan nanga" ba "chi" aganbo'
    },
    'talk_btn': {
      'en': 'Talk', 'hi': 'बोलें', 'as': 'কওক', 'bn': 'বলুন',
      'mni': 'ৱাহৈ হাইয়ু', 'brx': 'बुं', 'mzo': 'TAWNG MEH', 'kha': 'KREN', 'grt': 'AGANBO'
    },
    'close_btn': {
      'en': 'Close', 'hi': 'बंद करें', 'as': 'बंद करें', 'bn': 'বন্ধ করুন',
      'mni': 'থিংউ', 'brx': 'बन्द खालाम', 'mzo': 'KHAWHP RAW', 'kha': 'KHANG', 'grt': 'CHIPBO'
    },
  };

  static String translate(String key, String languageCode) {
    if (!_localizedValues.containsKey(key)) return key;
    final translations = _localizedValues[key]!;
    return translations[languageCode] ?? translations['en'] ?? key;
  }

  static String translateDynamic(String? text, String langCode) {
    if (text == null || text.isEmpty) return "";
    final cleanText = text.trim();
    
    // Map text to translation keys
    if (cleanText == "Find the Match") return translate('find_the_match', langCode);
    if (cleanText == "Remember Pictures") return translate('remember_pictures', langCode);
    if (cleanText == "Spot the Difference") return translate('spot_the_difference', langCode);
    if (cleanText == "Sort and Arrange") return translate('sort_and_arrange', langCode);
    if (cleanText == "Name That Object") return translate('name_that_object', langCode);
    if (cleanText == "Recall Daily Events") return translate('recall_daily_events', langCode);
    
    if (cleanText == "Take Morning Medicine") return translate('take_morning_med', langCode);
    if (cleanText == "Morning Medicine") return translate('morning_med', langCode);
    if (cleanText == "Evening Medicine") return translate('evening_med', langCode);
    if (cleanText == "Drink Water") return translate('drink_water_task', langCode);
    if (cleanText == "Memory Game") return translate('memory_game_task', langCode);
    if (cleanText == "Lunch Time") return translate('lunch_time_task', langCode);
    if (cleanText == "Doctor Appointment") return translate('doctor_appt_task', langCode);
    
    // Descriptions:
    if (cleanText.contains("morning medicine")) return translate('morning_med_desc', langCode);
    if (cleanText.contains("stay hydrated") || cleanText.contains("glass of water")) return translate('drink_water_desc', langCode);
    if (cleanText.contains("keep your brain active") || cleanText.contains("cognitive exercise")) return translate('memory_game_desc', langCode);
    if (cleanText.contains("balanced healthy lunch")) return translate('lunch_desc', langCode);
    if (cleanText.contains("Standard checkup")) return translate('doctor_appt_desc', langCode);
    if (cleanText.contains("Take your medicine")) return translate('evening_med_desc', langCode);

    return cleanText;
  }
}
