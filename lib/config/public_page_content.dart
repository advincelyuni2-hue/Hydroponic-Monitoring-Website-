/// Editable copy and local image paths for the public pages.
///
/// Leave asset paths null to show the styled placeholders. To replace one,
/// put an image directly in assets/images/ (already declared in pubspec.yaml)
/// and set its path here, for example 'assets/images/hydroponic_plants.jpg'.
/// Register any new asset subdirectories in pubspec.yaml before using them.
class PublicPageContent {
  PublicPageContent._();

  static const brandName = 'HydroPulse';
  static const brandLogoLabel = 'HydroPulse logo placeholder';
  // REPLACE IMAGE HERE: HydroPulse brand logo
  static const String? brandLogoAsset = 'assets/images/thesislogo.png';

  // EDIT TEXT HERE: Login heading
  static const loginHeading = 'Welcome back';
  static const loginDescription =
      'Log in to view your reservoir readings and alerts.';
  static const loginHeroHeading = 'Precision\nhydroponics, ';
  static const loginHeroHighlight = 'in sync.';
  static const loginHeroDescription =
      'Monitor pH, EC and temperature, see forecasts for the next 4 to 12 '
      'hours, and act on clear recommendations.';
  static const loginBenefits = [
    'Live pH, EC and temperature readings',
    'Forecasts for the next 4 to 12 hours',
    'Clear, actionable recommendations',
  ];
  // EDIT HERE: Partner office information
  static const loginPartnership =
      '';

  // REPLACE IMAGE HERE: Hydroponic plants photo
  static const String? loginPlantsAsset = 'assets/images/loginphoto.png';
  static const loginPlantsLabel = '[Photo: our hydroponic plants]';

  static const emailLabel = 'Email';
  static const emailHint = 'you@example.com';
  static const passwordLabel = 'Password';
  static const passwordHint = 'Enter your password';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';
  static const rememberMe = 'Remember me';
  static const forgotPassword = 'Forgot password?';
  static const loginButton = 'Log in';
  static const googleLoginButton = 'Log in with Google';
  static const alternativeLogin = 'or';
  static const signupPrompt = "Don't have an account?";
  static const signupLink = 'Sign up';
  static const backToAbout = 'Back to About';
  static const aboutLink = 'About Us';
  static const navigationMenu = 'Navigate sections';
  static const landingNavigation = [
    (id: 'why', label: 'Why'),
    (id: 'how', label: 'How it works'),
    (id: 'features', label: 'Features'),
    (id: 'experiment', label: 'Experiment'),
    (id: 'partnership', label: 'Partnership'),
    (id: 'research', label: 'Research'),
  ];
  // EDIT TEXT HERE: Landing hero and study description.
  static const landingBadge =
      'A thesis study with the San Pedro Agriculture Office';
  static const landingDescription =
      'HydroPulse is a decision support system that watches pH, EC and '
      'temperature, forecasts the next 4, 8, and 12 hours, and tells growers '
      'what to do about it.';
  static const seeHowItWorks = 'See how it works';
  static const heroFacts = [
    '3 parameters monitored',
    '4 • 8 • 12h forecasts',
    'Live alerts',
  ];
  // REPLACE IMAGE HERE: Dashboard and alert screenshots.
  // REPLACE IMAGE HERE: Dashboard and alert screenshots.
  static const String? dashboardScreenshotAsset = "assets/images/dashboard.png";
  static const String? alertScreenshotAsset = "assets/images/notif.png";
  static const String? extraScreenshotAsset1 = "assets/images/historylogs.png";
  static const String? extraScreenshotAsset2 = "assets/images/forecasting.png";
  static const dashboardScreenshotLabel = 'Dashboard screenshot';
  static const alertScreenshotLabel = 'Alert details screenshot';
  static const extraScreenshotLabel1 = 'Forecasting graph screenshot';
  static const extraScreenshotLabel2 = 'Hist';
  static const whyEyebrow = 'WHY THIS STUDY';
  static const whyHeading = 'The challenge of manual hydroponic monitoring';
  static const whyDescription =
      'At the San Pedro City Agriculture Office, hydroponic conditions are monitored through periodic manual measurements of pH and EC. This approach can delay the detection of nutrient imbalances and relies heavily on personnel availability. HydroPulse addresses these challenges through continuous monitoring, predictive analytics, and rule-based recommendations to support timely and informed decisions.';
  // REPLACE IMAGE HERE: Farm / greenhouse photo.
  static const String? farmAsset = "assets/images/greenhouse.png";
  static const farmLabel = 'Farm / greenhouse photo';
  static const howEyebrow = 'HOW IT WORKS';
  static const howHeading = 'From sensor reading to a clear next step';
  static const steps = [
    (
      title: 'Sense',
      description:
          'Sensors in the reservoir read pH, EC and temperature continuously.'
    ),
    (
      title: 'Forecast',
      description:
          'A forecasting model predicts pH and EC 4, 8 and 12 hours ahead.'
    ),
    (
      title: 'Act',
      description:
          'Alerts come with a recommendation, and every fix is logged for review.'
    ),
  ];
  static const featuresEyebrow = 'FEATURES';
  static const featuresHeading = 'What growers get';
  static const features = [
    (title: 'Live monitoring', description: 'Track real-time pH, EC, and temperature readings through a centralized dashboard.'),
    (title: 'Forecasts', description: 'Anticipate pH and EC changes with machine learning predictions 4, 8, and 12 hours ahead.'),
    (title: 'Alerts and advice', description: 'Receive timely alerts and recommended actions when hydroponic conditions require attention.'),
    (title: 'History and logs', description: 'Review historical sensor trends, calibration records, and logged interventions for better monitoring.'),
  ];
  static const experimentEyebrow = 'THE EXPERIMENT';
  static const experimentHeading = 'Tested on real plants';
  static const experimentDescription =
      "HydroPulse was developed for hydroponic lettuce cultivation at the San Pedro City Agriculture Office, utilizing Kratky and Nutrient Film Technique (NFT) systems. The study involves a 30-day monitoring and evaluation period comparing manually managed and system-assisted experimental setups to assess the system's predictive capabilities and operational effectiveness.";
  // REPLACE IMAGE HERE: Experiment photographs, in reference order.
  static const String? experimentMainAsset = "assets/images/loginphoto.png";
  static const experimentMainLabel = '[Photo: full hydroponic setup]';
  static const List<({String label, String? assetPath})> experimentPhotos = [
    (label: '[Photo: plants, week 1]', assetPath: "assets/images/pstart.png"),
    (label: '[Photo: reservoir and sensors]', assetPath: "assets/images/pcali.png"),
    (label: '[Photo: plant growth, later weeks]', assetPath: "assets/images/pday7.png"),
    (label: '[Photo: harvest]', assetPath: null),
  ];
  // EDIT HERE: Partner office information.
  static const partnerEyebrow = 'OUR CLIENT';
  static const partnerHeading = 'Built with the San Pedro Agriculture Office';
  static const partnerDescription =
      'The San Pedro City Agriculture Office serves as the research partner and implementation site for HydroPulse. Through interviews, operational insights, and access to its hydroponic facilities, the office helped identify existing monitoring challenges and provided the practical setting for system development and evaluation.';
  static const partnerQuote = '[endorsement from the office.]';
  static const partnerName = 'San Pedro Agriculture Office';
  static const partnerContact = '[Address] · [Phone] · [Email]';
  static const partnerLogoLabel = 'LOGO';
  static const String? partnerLogoAsset = "assets/images/sanpedrologo.jpg";
  static const researchEyebrow = 'THE RESEARCH';
  static const researchHeading = 'About the study';
  static const studyDetails = [
    (label: 'Study title', value: 'Smart Decision Support System for Precision Hydroponics: Real-Time pH and EC Optimization Using Predictive Analytics'),
    (label: 'Researchers', value: 'Celynne Angelica T. Advincula, Althea Marie Calpe, John Ezriel DL. Uri'),
    (label: 'Adviser', value: 'Jonalyn G. Ebron'),
    (label: 'Institution', value: 'Mapúa Malayan Colleges Laguna — Bachelor of Science in Computer Science'),
  ];
 
  static const portraitLabel = '[Photo]';
  static const copyright =
      '© 2026 HydroPulse — Smart Decision Support System for Precision '
      'Hydroponics. All rights reserved.';
}
