class AppConstants {
  static const String appName = 'BugCash';
  static const String appVersion = '1.0.0';
  
  static const String usersCollection = 'users';
  static const String missionsCollection = 'missions';
  static const String submissionsCollection = 'submissions';
  static const String pointsHistoryCollection = 'points_history';
  static const String withdrawalsCollection = 'withdrawals';
  
  static const int missionDurationDays = 14;
  static const int dailyTestMinutes = 20;
  static const int dailyPoints = 5000;
  static const int bugBonusPoints = 2000;
  static const int minWithdrawPoints = 10000;
  
  static const String sharedDriveFolder = 'YOUR_DRIVE_FOLDER_ID';
  
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp driveUrlRegex = RegExp(
    r'https://drive\.google\.com/.*',
  );
}