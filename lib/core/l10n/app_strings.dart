import 'package:flutter/material.dart';
import 'translations/en.dart';
import 'translations/pt.dart';
import 'translations/fr.dart';
import 'translations/am.dart';
import 'translations/sw.dart';

/// Central accessor for all user-facing strings.
///
/// Usage:
///   AppStrings.of(context).signIn
///   AppStrings.get(context, 'signIn')
///
/// The active language is driven by the [Locale] in the current [BuildContext].
/// Fall back to English for any missing key.
class AppStrings {
  final Locale locale;

  const AppStrings(this.locale);

  /// Obtain the AppStrings instance from the nearest [Localizations] ancestor.
  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        AppStrings(const Locale('en'));
  }

  /// Raw map lookup — returns English fallback for unknown keys.
  static String get(BuildContext context, String key) {
    return AppStrings.of(context)._t(key);
  }

  // ── Internal map lookup ───────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _maps = {
    'en': en,
    'pt': pt,
    'fr': fr,
    'am': am,
    'sw': sw,
  };

  String _t(String key) {
    final langCode = locale.languageCode;
    final map = _maps[langCode] ?? en;
    return map[key] ?? en[key] ?? key;
  }

  // ── General ───────────────────────────────────────────────────────────────
  String get appName => _t('appName');
  String get ok => _t('ok');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get close => _t('close');
  String get retry => _t('retry');
  String get loading => _t('loading');
  String get error => _t('error');
  String get success => _t('success');
  String get or => _t('or');
  String get sort => _t('sort');
  String get all => _t('all');
  String get yes => _t('yes');
  String get no => _t('no');
  String get back => _t('back');
  String get next => _t('next');
  String get done => _t('done');
  String get search => _t('search');
  String get copy => _t('copy');
  String get copiedToClipboard => _t('copiedToClipboard');
  String get notSet => _t('notSet');
  String get comingSoon => _t('comingSoon');

  // ── Offline Banner ────────────────────────────────────────────────────────
  String get offlineMessage => _t('offlineMessage');

  // ── Auth — Login ──────────────────────────────────────────────────────────
  String get welcomeBack => _t('welcomeBack');
  String get signInSubtitle => _t('signInSubtitle');
  String get username => _t('username');
  String get usernameHint => _t('usernameHint');
  String get password => _t('password');
  String get signIn => _t('signIn');
  String get forgotPassword => _t('forgotPassword');
  String get newUser => _t('newUser');
  String get createAccount => _t('createAccount');
  String get loginFailed => _t('loginFailed');
  String get enterUsername => _t('enterUsername');
  String get enterPassword => _t('enterPassword');
  String get copyright => _t('copyright');

  // ── Auth — Register ───────────────────────────────────────────────────────
  String get createAccountTitle => _t('createAccountTitle');
  String get joinCoach => _t('joinCoach');
  String get firstName => _t('firstName');
  String get lastName => _t('lastName');
  String get email => _t('email');
  String get emailOptional => _t('emailOptional');
  String get schoolName => _t('schoolName');
  String get schoolNameOptional => _t('schoolNameOptional');
  String get country => _t('country');
  String get register => _t('register');
  String get registrationFailed => _t('registrationFailed');
  String get enterFirstName => _t('enterFirstName');
  String get enterLastName => _t('enterLastName');
  String get enterEmail => _t('enterEmail');
  String get passwordMinLength => _t('passwordMinLength');

  // ── Auth — Forgot / Reset Password ────────────────────────────────────────
  String get forgotPasswordTitle => _t('forgotPasswordTitle');
  String get forgotPasswordSubtitle => _t('forgotPasswordSubtitle');
  String get sendResetLink => _t('sendResetLink');
  String get resetPassword => _t('resetPassword');
  String get newPassword => _t('newPassword');
  String get confirmNewPassword => _t('confirmNewPassword');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');

  // ── Onboarding ────────────────────────────────────────────────────────────
  String get onboardingWelcome => _t('onboardingWelcome');
  String get onboardingSubtitle => _t('onboardingSubtitle');
  String get onboardingContinue => _t('onboardingContinue');
  String get onboardingInfo => _t('onboardingInfo');
  String get enterSchoolName => _t('enterSchoolName');

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  String get navRecord => _t('navRecord');
  String get navMyLessons => _t('navMyLessons');
  String get navChats => _t('navChats');
  String get navProfile => _t('navProfile');

  // ── Home / Recording — Idle ───────────────────────────────────────────────
  String get tapToRecord => _t('tapToRecord');
  String get tapToRecordSub => _t('tapToRecordSub');
  String get tapToRecordButton => _t('tapToRecordButton');
  String get captureAudio => _t('captureAudio');
  String get importAudio => _t('importAudio');
  String get importAudioSub => _t('importAudioSub');

  // ── Home / Recording — Active ─────────────────────────────────────────────
  String get recording => _t('recording');
  String get recordingActive => _t('recordingActive');
  String get recordingPaused => _t('recordingPaused');
  String get pauseRecording => _t('pauseRecording');
  String get resumeRecording => _t('resumeRecording');
  String get stopRecording => _t('stopRecording');
  String get discardRecording => _t('discardRecording');
  String get discardRecordingMessage => _t('discardRecordingMessage');
  String get keep => _t('keep');
  String get discard => _t('discard');
  String get lockTooltip => _t('lockTooltip');
  String get unlockTooltip => _t('unlockTooltip');

  // ── Home / Recording — Review ─────────────────────────────────────────────
  String get reviewRecording => _t('reviewRecording');
  String get lessonTitle => _t('lessonTitle');
  String get subject => _t('subject');
  String get gradeLevel => _t('gradeLevel');
  String get saveAndAnalyze => _t('saveAndAnalyze');
  String get saveLater => _t('saveLater');
  String get enterLessonTitle => _t('enterLessonTitle');
  String get selectSubject => _t('selectSubject');
  String get uploadingLesson => _t('uploadingLesson');
  String get uploadingSubtitle => _t('uploadingSubtitle');
  String get lessonSaved => _t('lessonSaved');
  String get uploadingForAnalysis => _t('uploadingForAnalysis');
  String get failedToSave => _t('failedToSave');
  String get failedToSaveLesson => _t('failedToSaveLesson');
  String get noInternetTitle => _t('noInternetTitle');
  String get noInternetAnalysis => _t('noInternetAnalysis');
  String get saveForLater => _t('saveForLater');
  String get recordingSavedToDevice => _t('recordingSavedToDevice');
  String get couldNotSaveRecording => _t('couldNotSaveRecording');
  String get importedAudioCopied => _t('importedAudioCopied');

  // ── Subjects ──────────────────────────────────────────────────────────────
  String get subjectMath => _t('subjectMath');
  String get subjectScience => _t('subjectScience');
  String get subjectEnglish => _t('subjectEnglish');
  String get subjectHistory => _t('subjectHistory');
  String get subjectArt => _t('subjectArt');
  String get subjectOther => _t('subjectOther');

  // ── My Lessons ────────────────────────────────────────────────────────────
  String get myLessons => _t('myLessons');
  String get searchLessons => _t('searchLessons');
  String get noLessonsFound => _t('noLessonsFound');
  String get analyzed => _t('analyzed');
  String get notAnalyzed => _t('notAnalyzed');
  String get sortBy => _t('sortBy');
  String get sortAlphabeticalAZ => _t('sortAlphabeticalAZ');
  String get sortAlphabeticalZA => _t('sortAlphabeticalZA');
  String get sortDateNewest => _t('sortDateNewest');
  String get sortDateOldest => _t('sortDateOldest');
  String get deleteRecording => _t('deleteRecording');
  String get deleteRecordingMessage => _t('deleteRecordingMessage');
  String get recordingDeleted => _t('recordingDeleted');
  String get analysisReady => _t('analysisReady');
  String get analysisCouldNotComplete => _t('analysisCouldNotComplete');
  String get tapToSeeDetails => _t('tapToSeeDetails');
  String get fetchingAnalysis => _t('fetchingAnalysis');
  String get lessonBeingAnalyzed => _t('lessonBeingAnalyzed');
  String get noAnalysisFound => _t('noAnalysisFound');
  String get analysisInProgress => _t('analysisInProgress');
  String get uploadingDrafts => _t('uploadingDrafts');
  String get analysisNotStarted => _t('analysisNotStarted');
  String get analysisNotStartedMessage => _t('analysisNotStartedMessage');
  String get runAnalysis => _t('runAnalysis');
  String get analysisStarted => _t('analysisStarted');
  String get failedToStartAnalysis => _t('failedToStartAnalysis');

  // ── Analysis Screen ───────────────────────────────────────────────────────
  String get lessonAnalysis => _t('lessonAnalysis');
  String get analysis => _t('analysis');
  String get overallScore => _t('overallScore');
  String get keyTakeaways => _t('keyTakeaways');
  String get strengths => _t('strengths');
  String get areasForImprovement => _t('areasForImprovement');
  String get recommendations => _t('recommendations');
  String get teachFramework => _t('teachFramework');
  String get scienceOfLearning => _t('scienceOfLearning');
  String get transcript => _t('transcript');
  String get transcriptComingSoon => _t('transcriptComingSoon');
  String get talkToCoach => _t('talkToCoach');
  String get copyAllFeedback => _t('copyAllFeedback');
  String get analysisCopied => _t('analysisCopied');
  String get lessonAudio => _t('lessonAudio');
  String get untitledLesson => _t('untitledLesson');
  String get shortRecording => _t('shortRecording');
  String get limitedTeachingActivity => _t('limitedTeachingActivity');
  String get lowAudioQuality => _t('lowAudioQuality');
  String get analysisNote => _t('analysisNote');
  String get coachFeedback => _t('coachFeedback');
  String get pros => _t('pros');
  String get cons => _t('cons');

  // ── Analysis — Element Detail ─────────────────────────────────────────────
  String get evidence => _t('evidence');
  String get behaviorFilter => _t('behaviorFilter');
  String get askCoachAbout => _t('askCoachAbout');

  // ── Chat Screen ───────────────────────────────────────────────────────────
  String get aiCoach => _t('aiCoach');
  String get viewLessonAnalysis => _t('viewLessonAnalysis');
  String get askAnything => _t('askAnything');
  String get typeMessage => _t('typeMessage');
  String get deleteConversation => _t('deleteConversation');
  String get deleteConversationMessage => _t('deleteConversationMessage');
  String get deleteConversationAction => _t('deleteConversationAction');
  String get permanentlyRemoveChat => _t('permanentlyRemoveChat');
  String get copyLogs => _t('copyLogs');
  String get copyLogsSubtitle => _t('copyLogsSubtitle');
  String get logLinesCopied => _t('logLinesCopied');

  // ── Chat Suggestions ──────────────────────────────────────────────────────
  String get suggestionEngagement => _t('suggestionEngagement');
  String get suggestionFocusNext => _t('suggestionFocusNext');
  String get suggestionExample => _t('suggestionExample');
  String get suggestionDidWell => _t('suggestionDidWell');

  // ── Chat List Screen ──────────────────────────────────────────────────────
  String get coaching => _t('coaching');
  String get newChat => _t('newChat');
  String get noChatsYet => _t('noChatsYet');
  String get startConversation => _t('startConversation');
  String get selectLesson => _t('selectLesson');
  String get generalChat => _t('generalChat');
  String get generalChatSubtitle => _t('generalChatSubtitle');

  // ── Profile Screen ────────────────────────────────────────────────────────
  String get editProfile => _t('editProfile');
  String get school => _t('school');
  String get darkMode => _t('darkMode');
  String get changePassword => _t('changePassword');
  String get logOut => _t('logOut');
  String get logOutConfirm => _t('logOutConfirm');
  String get saveChanges => _t('saveChanges');
  String get nameUpdated => _t('nameUpdated');
  String get updateFailed => _t('updateFailed');
  String get language => _t('language');

  // ── Profile — Change Password ─────────────────────────────────────────────
  String get changePasswordTitle => _t('changePasswordTitle');
  String get changePasswordSubtitle => _t('changePasswordSubtitle');
  String get currentPassword => _t('currentPassword');
  String get updatePassword => _t('updatePassword');
  String get enterCurrentPassword => _t('enterCurrentPassword');
  String get enterNewPassword => _t('enterNewPassword');
  String get atLeast6Chars => _t('atLeast6Chars');
  String get newPasswordMustDiffer => _t('newPasswordMustDiffer');
  String get passwordChanged => _t('passwordChanged');
  String get failedToChangePassword => _t('failedToChangePassword');

  // ── Email Verification ────────────────────────────────────────────────────
  String get verifyEmail => _t('verifyEmail');
  String get verificationCode => _t('verificationCode');
  String get resendCode => _t('resendCode');
  String get emailVerified => _t('emailVerified');

  // ── Recording Screen ──────────────────────────────────────────────────────
  String get recordLesson => _t('recordLesson');

  // ── Local Draft Detail ────────────────────────────────────────────────────
  String get localDraft => _t('localDraft');
  String get savedLocally => _t('savedLocally');
  String get uploadAndAnalyze => _t('uploadAndAnalyze');

  // ── Language Names ────────────────────────────────────────────────────────
  String get langEnglish => _t('langEnglish');
  String get langPortuguese => _t('langPortuguese');
  String get langFrench => _t('langFrench');
  String get langAmharic => _t('langAmharic');
  String get langSwahili => _t('langSwahili');
}

// ── Localizations Delegate ────────────────────────────────────────────────────

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  static const List<String> _supported = ['en', 'pt', 'fr', 'am', 'sw'];

  @override
  bool isSupported(Locale locale) =>
      _supported.contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(AppStringsDelegate old) => false;
}
