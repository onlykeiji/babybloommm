/// Which onboarding path the signed-in user took.
///
/// Used to tailor shared navigation (the bottom nav's "Cycle"/"Journey" tab)
/// to the user's actual context, without needing a full state-management
/// setup for this prototype.
enum AppMode { familyPlanning, pregnancy, babyCare }

class AppSession {
  AppSession._();

  static AppMode mode = AppMode.familyPlanning;
}
