import 'help_article_service.dart';

/// Help categories, in the order they appear on the Help screen.
const List<String> kHelpCategories = [
  'Getting started',
  'Dashboard',
  'Forecasts',
  'History logs',
  'Reports',
  'Notifications',
  'Settings',
  'Admin settings',
];

/// Built-in guides. They are shown when no articles are saved in Supabase.
/// An admin can save them to the database (Help > Save built-in guides) and
/// then edit, delete or add to them.
const List<HelpArticle> kDefaultHelpArticles = [
  // ---------------------------------------------------------------------
  // Getting started
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'Getting started',
    title: 'Find your way around the app',
    body:
        '1. Tap the green menu button at the top left to open the side menu.\n'
        '2. Pick Dashboard, Forecasts, History logs or Reports to see your hydroponic data.\n'
        '3. Settings and Help are at the bottom of the menu. Admins also see Admin settings.\n'
        '4. The bell at the top right shows your alerts. A red number means there are new alerts.\n'
        '5. Tap your name or the profile circle at the top right to open Settings.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Getting started',
    title: 'Check alerts from the bell',
    body:
        '1. On a computer, click the bell to see the latest alerts in a small list. On a phone, the bell opens the Notifications screen.\n'
        '2. Click an alert to record the fix you made. The form opens with the reading already filled in.\n'
        '3. Click View all notifications to open the full Notifications screen.\n'
        '4. On the Notifications screen, the Active tab shows alerts that still need attention and the Resolved tab shows finished ones.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Getting started',
    title: 'What are pH, EC and temperature?',
    body: 'pH shows how acidic or alkaline the nutrient solution is. '
        'EC (electrical conductivity, shown in mS/cm) shows how strong the nutrient mix is. '
        'Temperature is the temperature of the solution. '
        'Plants grow best when all three stay inside their ideal ranges.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Getting started',
    title: 'What can employees and admins do?',
    body:
        'Everyone who is signed in can view the dashboard, forecasts, history logs, reports and alerts, and can send an alert to an admin. '
        'Only admins can edit or delete history logs, change the ideal pH and EC ranges, manage users and add help articles.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Getting started',
    title: "Why don't I see Admin settings in the menu?",
    body: 'Admin settings only appears for admin accounts. '
        'Ask an admin to change your role in Admin settings if you need access.',
  ),

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'Dashboard',
    title: 'Read the Realtime Parameter Status cards',
    body: '1. Open Dashboard from the side menu.\n'
        '2. Find the Realtime Parameter Status panel. It has one card each for pH, EC and Temperature.\n'
        '3. Each card shows the latest reading, a status badge (Stable, Warning or Critical), the ideal range and when the reading was last updated.\n'
        '4. The green Live dot means the panel is showing the most recent stored readings. If the numbers look old, open the Dashboard again.\n'
        '5. Stable means the reading is inside its ideal range. Warning or Critical means it needs your attention.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Dashboard',
    title: 'Use the Latest Insight card',
    body:
        '1. Find the Latest Insight card on the Dashboard. It summarizes what the forecast expects for pH and EC.\n'
        '2. The status shows whether things look Stable, Warning or Critical. The text underneath explains why.\n'
        '3. Contributing factors lists the temperature and the other parameter that influence the forecast.\n'
        '4. The predicted pH and EC values show where the readings are expected to go.\n'
        '5. Tap View insight details to open the Forecasts screen for the chart and the suggested fix.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Dashboard',
    title: 'Send an alert to an admin',
    body:
        '1. In the Latest Insight card, tap Alert Admin (the megaphone button).\n'
        '2. Describe what you see, for example "pH reading looks wrong on tank 2".\n'
        '3. Tap Send alert. You will see "Alert sent to an administrator."\n'
        '4. The alert appears in the admin\'s bell and on their Notifications screen.\n'
        '5. Tap Cancel if you want to close the box without sending.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Dashboard',
    title: 'Use the Forecast Overview chart',
    body: '1. Scroll to Forecast Overview on the Dashboard.\n'
        '2. Choose Both, pH or EC to pick which lines the chart draws.\n'
        '3. Choose 4h, 8h or 12h to set how many hours back and ahead the chart shows.\n'
        '4. Solid lines are measured readings. Dashed lines are predictions. The dashed vertical line marks now.\n'
        '5. The label at the top compares the current and forecast values. Hover or tap a point to see its exact value.\n'
        '6. Tap View forecast details to open the full Forecasting dashboard.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Dashboard',
    title: 'What do Stable, Warning and Critical mean?',
    body: 'Stable means the reading is inside its ideal range. '
        'Warning means it is close to a limit or is expected to leave the range soon. '
        'Critical means it is outside the ideal range and needs action. '
        'The same colors and words are used on the Dashboard, History logs and Notifications.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Dashboard',
    title: 'Where do the ideal ranges come from?',
    body:
        'An admin sets the ideal pH and EC ranges in Admin settings (pH / EC Parameter Configuration). '
        'Once saved, the same ranges are used for the status cards, charts, alerts and reports. '
        'Temperature uses a safe range that is built into the app.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Dashboard',
    title: 'Why is the Latest Insight card missing?',
    body: 'The card only appears when forecast data is available. '
        'If you see an error with a Retry button, tap Retry. '
        'If nothing appears, check again after new sensor readings come in.',
  ),

  // ---------------------------------------------------------------------
  // Forecasts
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'Forecasts',
    title: 'Read the forecast chart',
    body: '1. Open Forecasts from the side menu.\n'
        '2. Pick pH Forecast, EC Forecast or Both with the tabs above the chart.\n'
        '3. Pick 4h, 8h or 12h at the top right of the chart to change the time window.\n'
        '4. Left of the dashed vertical line are the readings so far (green for pH, teal for EC). Right of it is what the model predicts, drawn as a yellow dashed line.\n'
        '5. The label at the top compares the current and forecast values. The legend and the Generated time are below the chart.\n'
        '6. Hover or tap a point to see its exact value.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Forecasts',
    title: 'Apply or dismiss a suggested fix',
    body:
        '1. In the Prediction Insights card, read the status badge and the explanation.\n'
        '2. Check Contributing factors and the Suggested fix list.\n'
        '3. After you have done the fix on your system, tap Apply fix, then Yes in the "Apply Corrective Fix?" box. The app shows "Fix logged successfully".\n'
        '4. If the suggestion does not apply, tap Dismiss, then Yes in the "Dismiss Corrective Fix?" box. It is saved to the dismissed action logs.\n'
        '5. On the Both tab, use the pH / EC switch at the top of the card to choose which insight you are reading.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Forecasts',
    title: 'Report an issue from the Forecasts screen',
    body: '1. Find the Report an issue card.\n'
        '2. Tap Alert admin.\n'
        '3. Describe the reading or error you noticed.\n'
        '4. Tap Send alert. An admin will see it in their notifications.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Forecasts',
    title: 'How does the forecast work?',
    body:
        'A machine-learning model uses the latest pH, EC and temperature readings to estimate where pH and EC will be over the next 4, 8 or 12 hours. '
        'If the forecasting service cannot be reached, the app shows a simple estimated trend instead, so treat the chart as a guide and confirm with your sensors.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Forecasts',
    title: 'Does Apply fix control my equipment?',
    body:
        'No. Apply fix only records that you carried out the suggested action, so your history and future insights stay accurate. '
        'You still need to adjust the solution yourself.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Forecasts',
    title: 'What happens after I apply or dismiss a fix?',
    body:
        'The action is saved to the logs and noted in the insight. The status still follows the latest reading and forecast: it stays Warning or Critical until the values return to the stable range.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Forecasts',
    title: 'Why do the suggested amounts change?',
    body:
        'Suggested doses, for example the mL of pH-down solution, depend on how far the predicted value is from the middle of the ideal range. '
        'Add the solution gradually and check the sensor reading afterwards.',
  ),

  // ---------------------------------------------------------------------
  // History logs
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'History logs',
    title: 'Browse logs by day, week or month',
    body: '1. Open History logs from the side menu.\n'
        '2. Choose a tab: Sensor logs, Calibration logs or Intervention logs.\n'
        '3. Tap Daily, Weekly or Monthly. A calendar opens so you can pick the date, week or month.\n'
        '4. The date button next to them shows what you chose. Tap it to pick a different period.\n'
        '5. Daily shows 10-minute averages, Weekly shows 8-hour averages and Monthly shows daily averages.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'History logs',
    title: 'Understand the color indicators',
    body: '1. Tap See legend above the table.\n'
        '2. The Indicator Legend explains High Critical Breach, Low Critical Breach and Stable / In Range.\n'
        '3. In the table, each reading has an icon and a color. Under it you can see the ideal range, for example "Ideal: 5.5 - 6.5".\n'
        '4. Hover over an icon to see a short description.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'History logs',
    title: 'Edit or delete log records (admins only)',
    body:
        '1. To edit one record, tap the pencil (Edit log entry) at the end of the row, change Average pH, Average EC or Average Temp, then tap Save changes to log.\n'
        '2. To delete one record, tap the trash can (Delete log entry), then confirm Delete.\n'
        '3. To delete several records, tap Select, tick the rows (or the box at the top for all), tap Delete, then confirm Delete All.\n'
        '4. Tap Cancel to leave selection mode without deleting.\n'
        '5. Editing and deleting is available on a computer. Employees can view logs but not change them.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'History logs',
    title: 'Who can edit or delete logs?',
    body:
        'Only admins. Employees can view logs, filter by date and open the legend, but the edit and delete buttons are hidden for them.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'History logs',
    title: 'What do the average columns mean?',
    body:
        'Each row is an average of the readings in that time slot: 10 minutes for Daily, 8 hours for Weekly and one day for Monthly. '
        'Switching between Daily, Weekly and Monthly changes how much detail you see.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'History logs',
    title: 'Why are Calibration logs or Intervention logs empty?',
    body: 'These tabs fill up as calibration records and fixes are saved. '
        'If a table is empty, nothing has been recorded for it yet.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'History logs',
    title: 'Why do some values have a warning color?',
    body:
        'A colored value is outside its ideal range. Tap See legend to see what each color and icon means.',
  ),

  // ---------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'Reports',
    title: 'Read the summary cards',
    body: '1. Open Reports from the side menu.\n'
        '2. Telemetry Last Updated shows the time of the latest sensor reading.\n'
        '3. AVG PH, AVG EC and AVG TEMP show the average over the last 30 days. A badge tells you if it is In range or Out of range.\n'
        '4. Critical Alerts counts the critical alerts from the last 30 days.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Reports',
    title: 'Explore Historical Telemetry Trends',
    body: '1. Choose pH or EC at the top right of the chart.\n'
        '2. Choose 7d, 30d or 90d to set how far back the chart goes.\n'
        '3. The green line shows the daily readings. The red dashed lines mark the minimum and maximum of the ideal range.\n'
        '4. Points outside the range are marked. Hover over them for details.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Reports',
    title: 'Check the Frequency Distribution',
    body: '1. Pick pH, EC or Temp.\n'
        '2. The chart shows how much of the time the readings were Optimal (In Target), in the Warning Zone or in the Critical Bounds.\n'
        '3. A high Optimal share means the system stayed in its ideal range most of the time.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Reports',
    title: 'Review the Forecast Model Evaluation',
    body: '1. Choose Both, pH or EC.\n'
        '2. The chart draws the measured readings and the model\'s predictions together.\n'
        '3. The closer the two lines are, the better the forecast matched what really happened.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Reports',
    title: 'Check sensor calibration',
    body: '1. Find the Sensor Calibration card.\n'
        '2. Each sensor has a health bar. It goes down as the days since the last calibration go up.\n'
        '3. The text under the bar says "Calibrated today", "Last cal: 12d ago" or "No calibration recorded".\n'
        '4. Calibrate again when a sensor shows Due soon or Overdue.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Reports',
    title: 'Create a PDF report',
    body:
        '1. On the Reports screen, find the Generate PDF Report card and tap Export PDF. The Generate report screen opens.\n'
        '2. In Report Configuration, tick what you want to include: Sensor history logs, Calibration history logs, pH optimization results, EC optimization results and All analytics and graphs.\n'
        '3. The Document Preview on the left updates to show the real PDF pages.\n'
        '4. Tap Export PDF to download the file. Tap Cancel to go back without exporting.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Reports',
    title: 'What does Out of range mean?',
    body:
        'The average is outside the ideal range that an admin saved in Admin settings. '
        'It does not mean the system is failing right now. Open the trend chart and History logs to see when it happened.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Reports',
    title: 'Which period do the report cards cover?',
    body:
        'The summary cards cover the last 30 days. The trend chart covers 7, 30 or 90 days, depending on what you pick.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Reports',
    title: 'Why is a section missing from my PDF?',
    body: 'The PDF only contains the items you ticked in Report Configuration. '
        'Tick the missing item, wait for the preview to update, then export again.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Reports',
    title: 'What is the Critical Alert Frequency chart?',
    body:
        'It counts critical alerts by type, for example pH drift or EC spike, so you can see which problem happens most often.',
  ),

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'Notifications',
    title: 'Review and resolve alerts',
    body:
        '1. Open Notifications from the bell. On a computer you can also choose View all notifications.\n'
        '2. The Active tab lists alerts that need attention. The Resolved tab lists finished ones.\n'
        '3. Each card shows its level (Information, Warning Alert or Critical Alert), the message, the current status and reading, the ideal range and a recommendation.\n'
        '4. When the problem is handled, tick the box on the card to mark it resolved, or open the card to record the fix.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Notifications',
    title: 'Record a fix',
    body:
        '1. Tap an alert card. The Record a fix form opens with the parameter, the current value and the recommendation filled in.\n'
        '2. Check the Timestamp, Parameter and Current value.\n'
        '3. Choose the Type of action (for example pH Up, pH Down, Add Nutrient or Add Water) and enter the amount in mL.\n'
        '4. Describe what you did in Notes / Intervention Details.\n'
        '5. Tap Record fix. The alert moves to Resolved and your action is saved to the history.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Notifications',
    title: 'Where do alerts come from?',
    body:
        'The app creates an alert when pH, EC or temperature goes outside its configured range. '
        'People can also send alerts with the Alert Admin and Alert admin buttons.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Notifications',
    title: 'Why does an alert say Information?',
    body:
        'Alerts that are not about an out-of-range reading, such as a message sent with Alert admin, are labeled Information. '
        'Out-of-range readings show as Warning Alert or Critical Alert.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Notifications',
    title: 'Why is there nothing in the list?',
    body:
        'The screen shows "No active notifications found" when everything is resolved. '
        'Switch to the Resolved tab to see past alerts.',
  ),

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'Settings',
    title: 'Update your profile',
    body:
        '1. Tap your name or profile circle at the top right, or choose Settings in the side menu.\n'
        '2. Under Profile Management, change your Full name.\n'
        '3. Tap Save profile.\n'
        '4. Your email address is shown partly hidden and cannot be typed over. Use Change email to update it.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Settings',
    title: 'Change your email or password',
    body:
        '1. In Settings, under Profile Management, tap Change email or Change password.\n'
        '2. Enter your current password. This confirms it is really you.\n'
        '3. For a new password, enter it twice (at least 8 characters). Tick Show passwords to check what you typed.\n'
        '4. For a new email, enter the new address. We send a confirmation link, and the change finishes after you open it.\n'
        '5. Accounts that sign in with Google do not have these buttons. Manage your email and password in your Google account.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Settings',
    title: 'Change notifications, units and dark mode',
    body: '1. In Settings, find the Preferences card.\n'
        '2. Turn Notifications on or off to receive or stop alerts about sensor readings.\n'
        '3. Choose Metric or Imperial under Measurement Units to show temperature in °C or °F.\n'
        '4. Turn on Light/Dark Mode to switch between the light and dark themes.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Settings',
    title: 'Log out',
    body: '1. In Settings, scroll to the Log out card.\n'
        '2. Tap Log out.\n'
        '3. Confirm in the "Log out?" box. You return to the login screen.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Settings',
    title: 'I forgot my password. What do I do?',
    body: 'On the login screen, tap Forgot password and enter your email. '
        'We send a verification code to your inbox. Enter the code with a new password to finish. '
        'If the email does not arrive, check your spam folder and use Resend code.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Settings',
    title: 'Can I use the same email for two accounts?',
    body:
        'No. Each email address can have one account. If you already have an account, log in instead of signing up again.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Settings',
    title: 'What does Remember me do?',
    body: 'When ticked on the login screen, you stay signed in on this device. '
        'When it is not ticked, you sign in again the next time you open the app.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Settings',
    title: 'What changes when I choose Imperial?',
    body:
        'Temperature is shown in °F instead of °C. pH and EC have no imperial version, so they stay the same.',
  ),

  // ---------------------------------------------------------------------
  // Admin settings
  // ---------------------------------------------------------------------
  HelpArticle(
    type: 'tutorial',
    category: 'Admin settings',
    title: 'Set the ideal pH and EC ranges',
    body: '1. Open Admin settings from the side menu.\n'
        '2. In pH / EC Parameter Configuration, drag the two handles of the pH Setpoint Range and the EC Setpoint Range. The Ideal label updates as you drag.\n'
        '3. Tap Save configuration. You will see "Parameter configuration saved."\n'
        '4. Tap Revert to go back to the last saved values.\n'
        '5. The saved ranges are used for the status cards, charts, alerts, forecasts and reports the next time each screen loads.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Admin settings',
    title: 'Manage users',
    body: '1. In Admin settings, scroll to User Management.\n'
        '2. Use the role menu to make someone an Admin or an Employee.\n'
        '3. Use the switch to activate or deactivate an account. A deactivated user cannot log in.\n'
        '4. Tap the trash can to delete an account, then confirm.\n'
        '5. Emails are partly hidden for privacy.',
  ),
  HelpArticle(
    type: 'tutorial',
    category: 'Admin settings',
    title: 'Add or edit help articles',
    body:
        '1. Open Help from the side menu. Admins see an Add article button at the top.\n'
        '2. Tap Add article and choose the Section (Tutorial or FAQ) and the Category.\n'
        '3. Enter a Title and the Content. For a tutorial, put each step on its own line, like "1. Open Reports".\n'
        '4. Tap Save article.\n'
        '5. To change or remove an article, open it and tap Edit or Delete.\n'
        '6. The first time you add an article, the built-in guides are saved to the database too, so you can edit them.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Admin settings',
    title: 'Why can I not deactivate or delete my own account?',
    body: 'This stops an admin from locking themselves out. '
        'Your own role menu, switch and delete button are turned off. Another admin can change them for you.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Admin settings',
    title: 'What happens to a deactivated user?',
    body:
        'They cannot log in until an admin turns the switch back on. Their past logs and fixes stay in the history.',
  ),
  HelpArticle(
    type: 'faq',
    category: 'Admin settings',
    title: 'Who can add help articles?',
    body:
        'Only admins. Employees can read every article but do not see the Add article, Edit or Delete buttons.',
  ),
];
