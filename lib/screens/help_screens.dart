import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/guard_service.dart';
import '../theme.dart';

// Feedback
const String kAppVersion = '1.0.0';
const String kFeedbackEmail = 'delacruzjrome3@gmail.com';

// Names and roles from the Mindful Minute capstone document.
const List<(String, String)> kDevelopers = [
  ("J'rome A. De La Cruz", 'Lead Developer'),
  ('Dale M. Misajon', 'Project Manager'),
  ('Carl Luis L. Malan', 'Documentations'),
  ('Phenaeus Walter F. Gavilla', 'System Analyst'),
];

// ---------------------------------------------------------------- shared UI
Widget _heading(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(t,
          style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Pal.accent)),
    );

Widget _card(Widget child) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
      child: child,
    );

Widget _body(String t) =>
    Text(t, style: const TextStyle(color: Pal.muted, height: 1.45));

Widget _tile(BuildContext context, String q, String a) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration:
          BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [_body(a)],
        ),
      ),
    );

// ======================================================================= FAQ
const List<(String, List<(String, String)>)> _faqSections = [
  ('ABOUT THE APP', [
    ('What is Mindful Minute?',
        'Mindful Minute is an Android app that interrupts prolonged app use through '
            'for each. When you reach a limit, the app locks the screen into a short '
            'break made of one-minute activities, and then lets you carry on.'),
    ('Who made it, and why?',
        'It was built by J\'rome A. De la Cruz, Dale Misajon, Carl Malan, and Phenaeus Walter Gavilla '
            'a BSIT 3A students of the University of '
            'San Agustin (Iloilo City) as a capstone project for IT 311 Project Management.'
            'Studies of Filipino students report academic demands as the '
            'main source of stress (Bate et al., 2019) and significant digital stress, '
            'especially from social media (Giray et al., 2024). In short interviews with '
            'three University of San Agustin students, all described scrolling on even '
            'after realizing how long they had already been scrolling. Mindful Minute '
            'turns that moment into an intentional pause.'),
    ('Who is it for?',
        'Mainly university students, and the study is run with University of San '
            'Agustin students. Anyone with an Android phone can use it. There is no iOS '
            'or web version.'),
    ('Is it a medical or mental-health app?',
        'No. It is a supplementary, self-guided tool. It does not diagnose or treat '
            'stress or any mental health condition, and it does not replace counseling '
            'or professional care.'),
    ('Does it reduce stress or scrolling?',
        'We do not claim that. The related studies we reviewed do not test a '
            'one-minute activity or a prompt to stop scrolling, so that is exactly what '
            'is still unknown. Our study evaluates whether the app works correctly, '
            'whether students find it usable and engaging, whether they find it useful '
            'as a short break, and whether they find the screen lock acceptable. Any '
            'effect on stress or scrolling is left for future research.'),
    ('How is it different from Headspace, Calm or Insight Timer?',
        'Those apps are libraries of guided sessions, most of them behind a '
            'subscription, with sessions that typically start at about one to three '
            'minutes and go much longer. You have to open them yourself. Mindful Minute '
            'does one thing: it keeps every activity at about one minute and offers it '
            'at the moment your own app limit says you may otherwise keep scrolling. It '
            'has no subscription, no ads and no in-app purchases.'),
  ]),
  ('GETTING STARTED', [
    ('How do I set up my first break?',
        '1) Open Settings and allow the permissions. 2) On the Breaks tab tap +. '
            '3) Choose an app, set its daily limit (5 to 240 minutes) and pick your '
            'activities. 4) Tap Save. Use Preview to see the break without being locked.'),
    ('What activities are there?',
        'Breathing Exercise: a guided breathing circle for one minute.\n'
            'Minute Mini-Game: 15 different games for focus, memory and calm. One is '
            'picked at random each time.\n'
            'Wellness Reminders: calming animated scenes (30 variations) with music, '
            'quotes, research notes and tips on avoiding doomscrolling.'),
    ('Can I choose which activities I do?',
        'Yes. Every break lets you choose any combination. They are completed in the '
            'order you tap them, one minute each. The app never assigns or recommends '
            'activities for you.'),
  ]),
  ('PERMISSIONS', [
    ('Why does the app need so many permissions?',
        'A daily limit cannot be enforced without them. Android deliberately stops '
            'apps from measuring other apps, opening on top of other apps, or running '
            'quietly in the background. Each permission solves exactly one of those. '
            'See Settings > Why we need permissions for what each one does and does '
            'NOT do.'),
    ('Why Usage access?',
        'It is the only way Android lets an app learn how long you spent in another '
            'app. We only get the app name and time on screen. We cannot see messages, '
            'photos, passwords or anything you do inside an app. Android does not allow '
            'a normal pop-up for this one, so you switch it on in the phone settings, and '
            'without it no warnings can appear.'),
    ('Why Display over other apps?',
        'When you reach 100%, Android normally blocks an app from popping itself up '
            'while you are in another app. This permission lets the break open on top and '
            'return if you try to leave. We only draw one invisible 1-pixel dot.'),
    ('Why Accessibility? Is it spying on me?',
        'No. The Accessibility service only runs during a wellness break. It is told '
            'which app or window came to the front (so it can send you back), it closes '
            'the notification shade, and it keeps the music volume from being turned '
            'down. It is set up WITHOUT permission to read screen content, so it cannot '
            'read text, passwords or messages.'),
    ('Why Unrestricted battery?',
        'Phones stop background apps to save battery. Without this, Android could '
            'stop the monitor and your limit would not be enforced. It turns on '
            'automatically (you confirm a prompt) when you switch a break on, and the '
            'monitor stops completely when every break is off.'),
    ('Why Notifications?',
        'To warn you at 70%, 80% and 90%, and to show the small ongoing notification '
            'that Android requires for background monitoring. On Android 13 and later '
            'you must allow notifications.'),
    ('Can I turn permissions off?',
        'Yes, any time. Tap a permission switch in Settings: it opens the system page '
            'where you can switch it off. Breaks will not work properly without them. '
            'We never ask for your microphone, camera, location, contacts or files.'),
  ]),
  ('HOW IT WORKS', [
    ('How is my usage measured?',
        'Android records when each app comes to the front and when it leaves. '
            'Mindful Minute adds up that foreground time for today (ignoring time while '
            'the screen is off) and checks it every 15 seconds.'),
    ('What happens at 70%, 80%, 90% and 100%?',
        'Each of the first three shows a notification once per app per day. At 100%, '
            'calming music starts and Mindful Minute takes over the screen with "You\'ve '
            'reached your limit". Press Start Wellness Break to begin your activities.'),
    ('Why does it lock the phone? Is that too strict?',
        'Researchers testing softer on-screen reminders note that passive reminders '
            'are easy to ignore at the moment of temptation, while strict blocking can '
            'feel controlling and provoke pushback. We chose a firmer pause than a '
            'reminder, but with safeguards, and part of our study asks students whether '
            'they find it acceptable. We do not assume the firmer design is better.'),
    ('Can I escape a break?',
        'Not by Home, Recents, the power button or pulling down the status bar. '
            'Those lead back to the break. The only exit is finishing every activity. '
            'Safeguards: phone calls still come through, you can still power the phone '
            'off, and the lock ends on its own after ten minutes.'),
    ('When does my usage reset?',
        'Every day at midnight, and for an app right after you complete its break. A '
            'newly added (or switched-on) app always starts at 0.'),
    ('What happens to the music?',
        'The limit-screen song loops and cannot be turned off. It pauses when you '
            'start the activities and returns if you cancel back to that screen. Each '
            'activity has its own song. When you finish everything, the music stops.'),
    ('What do sessions and streak mean?',
        'Each completed one-minute activity counts as a session. Your streak is the '
            'number of days in a row with at least one completed session. Missing a '
            'day resets it to 0. History is grouped by day on the Progress tab.'),
    ('Why is my usage different from Digital Wellbeing?',
        'Phone brands count slightly differently (screen-off time, split-screen, '
            'picture-in-picture). Small differences are normal.'),
    ('Why is there a permanent notification?',
        'Android requires apps that monitor in the background to show one. It '
            'disappears when all your breaks are off.'),
  ]),
  ('DATA AND PRIVACY', [
    ('What data is stored on my phone?',
        'Your monitored apps and their daily limits, the activities you chose for '
            'each break, your completed sessions (date, time, total and streak), a '
            'record of which warnings were already shown today, and the screen-time '
            'figures read for your monitored apps. All of it is kept in local storage on '
            'your phone. There is no server and no database.'),
    ('Does the app need the internet?',
        'No. After installation it works fully offline. The only exception is '
            'sending feedback, which opens your own email app and only if you press Send.'),
    ('Does anyone else see my usage?',
        'No. The app has no administrator account, no server and no report page. '
            'University staff, the Guidance and Counseling Office and the developers do '
            'not receive any of your data from the app.'),
    ('How do I delete my data?',
        'Uninstall the app, or clear its storage in your phone settings '
            '(Apps > Mindful Minute > Storage > Clear data).'),
  ]),
  ('THE RESEARCH', [
    ('Is doomscrolling really harmful?',
        'Reviews of the research link doomscrolling with more anxiety, depression and '
            'distress and lower well-being. But most of that evidence is a snapshot in '
            'time rather than a trial, so it shows an association, not proof that '
            'scrolling causes harm. The interviewed students described scrolling in '
            'general, and we did not establish what content they viewed. So treat the '
            'research as context, not proof that your own scrolling is harmful.'),
    ('Is there evidence that wellness apps help students?',
        'Yes, with limits. A 2024 review of randomized trials in college students '
            '(47 studies reviewed, 19 trials analyzed for stress, 2,974 participants) '
            'associated mindfulness apps with reduced stress and improved emotional '
            'well-being (LaMontagne et al., 2024). But trials usually last weeks, and '
            'about a quarter of participants drop out of app trials (24.7% in one '
            'review of 70 trials; Linardon, 2023). That is why every Mindful Minute '
            'activity is short and your choice.'),
    ('Why one-minute activities?',
        'Students we interviewed preferred activities that are short, varied, freely '
            'chosen and not tedious. Research on mindfulness apps names keeping users '
            'engaged as the common weak point. Whether one minute is enough to matter is '
            'unproven, which is exactly what we are evaluating.'),
    ('Is Wellness Reminders medical advice?',
        'No. It is educational. If your mental health is suffering, please talk to a '
            'qualified professional or a local helpline.'),
    ('Where can I read the studies?',
        'Settings > The research behind it lists the studies with their full '
            'citations.'),
  ]),
  ('TROUBLESHOOTING', [
    ('Monitoring stopped after I closed the app',
        'Some phones (Infinix/XOS, Xiaomi, Oppo, Vivo, Huawei, Samsung with battery '
            'saving) kill background apps. Fix: 1) Settings > Unrestricted battery ON. '
            '2) In your phone settings allow Autostart for Mindful Minute. 3) In '
            'Recents, lock the app. 4) Set its battery usage to No restrictions.'),
    ('The break did not appear',
        'Check that all four permissions are on, that the break switch is on, and '
            'that notifications are allowed. Then see the answer above.'),
    ('I hear no music or the wrong music',
        'The limit screen uses your ALARM volume; activities use MEDIA volume. If you '
            'hear plain synthetic tones, the song files are missing from the build.'),
    ('The usage number looks wrong',
        'Turn that break off and on again to restart it from 0. If it is still wrong, '
            'send feedback with your phone model.'),
    ('How do I stop all monitoring?',
        'Switch every break off (or delete them) on the Breaks tab. The background '
            'monitor stops and its notification disappears.'),
  ]),
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final (title, items) in _faqSections) ...[
          _heading(title),
          for (final (q, a) in items) _tile(context, q, a),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FeedbackScreen())),
            child: const Text('Still stuck? Send us a message'),
          ),
        ),
      ]),
    );
  }
}

// ============================================================== PERMISSIONS
// (name, android permission, why we need it, what we do NOT do)
const List<(String, String, String, String)> _perms = [
  ('Usage access', 'PACKAGE_USAGE_STATS',
      'The only way Android lets an app know how long you used another app. This is '
          'what makes daily limits possible. Android has no normal pop-up for it, so you '
          'switch it on in the phone settings. Without it no warnings can appear.',
      'We do not see messages, photos, passwords or anything inside an app. Only the app '
          'name and time on screen.'),
  ('Display over other apps', 'SYSTEM_ALERT_WINDOW',
      'Lets the wellness break open on top of whatever you are doing when you reach '
          '100%, and return if you try to leave. Android blocks this for normal apps.',
      'We only draw a 1-pixel invisible dot. We never draw over or capture other '
          "apps' content."),
  ('Accessibility service', 'BIND_ACCESSIBILITY_SERVICE',
      'During a break only: notices when another window comes to the front so the break '
          'can return instantly, closes the notification shade, and stops the break '
          'music being turned down with the volume keys.',
      'It is configured WITHOUT permission to read screen content, so it cannot read '
          'text, passwords or messages. It does nothing outside a break.'),
  ('Unrestricted battery', 'REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      'Stops Android from shutting down the background monitor to save power, so your '
          'limits keep being checked.',
      'It is requested only when you switch a break on, and the monitor stops fully '
          'when all breaks are off.'),
  ('Notifications', 'POST_NOTIFICATIONS (Android 13+)',
      'Shows the 70%, 80% and 90% warnings and the ongoing "watching your limits" '
          'notice.',
      'No marketing or promotional notifications. Ever.'),
  ('Full-screen notification', 'USE_FULL_SCREEN_INTENT',
      'A backup way to open the break screen at 100% if Android refuses to open the '
          'app directly.',
      'Used only at the moment you reach a limit.'),
  ('Background service', 'FOREGROUND_SERVICE (+ SPECIAL_USE)',
      'Runs the monitor while the app is closed. Android requires this type of '
          'service and its notification.',
      'It only measures time in the apps you chose to monitor.'),
  ('Run at startup', 'RECEIVE_BOOT_COMPLETED',
      'Restarts the monitor after you reboot your phone, if any break is switched on.',
      'Does nothing if all breaks are off.'),
  ('See installed apps', 'QUERY_ALL_PACKAGES',
      'Shows the list of apps on your phone so you can pick which ones to monitor.',
      'The list never leaves your phone.'),
];

class PermissionsInfoScreen extends StatelessWidget {
  const PermissionsInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Why we need permissions')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _body('Android protects you by default: apps cannot watch other apps, open on '
            'top of them, or run silently in the background. To enforce a daily limit '
            'Mindful Minute needs the permissions below. Here is exactly what each does, '
            'and what it does not.'),
        const SizedBox(height: 8),
        for (final (name, code, why, not) in _perms)
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(code, style: const TextStyle(fontSize: 11, color: Pal.muted)),
            const SizedBox(height: 10),
            const Text('WHY WE NEED IT',
                style: TextStyle(fontSize: 11, color: Pal.accent, letterSpacing: 1)),
            const SizedBox(height: 2),
            _body(why),
            const SizedBox(height: 10),
            const Text('WHAT WE DO NOT DO',
                style: TextStyle(fontSize: 11, color: Pal.accent, letterSpacing: 1)),
            const SizedBox(height: 2),
            _body(not),
          ])),
        _card(const Text(
          'Never requested: microphone, camera, location, contacts, files, SMS or '
          'internet access. Everything stays on your phone.',
          style: TextStyle(height: 1.45),
        )),
      ]),
    );
  }
}

// ================================================================== RESEARCH
// (finding, citation). PART 1 comes from the Mindful Minute capstone document.
const List<(String, List<(String, String)>)> _studyResearch = [
  ('STUDENT STRESS IN THE PHILIPPINES', [
    ('A survey of 501 undergraduates from six Philippine state universities found '
        'that academic stressors were the main contributor to distress.',
        'G. P. Bate, M. B. Go, and S. P. Velos, "Top stressors among Filipino '
        'undergraduate students: A multicenter-interdisciplinary study," Recoletos '
        'Multidisciplinary Research Journal, vol. 7, no. 2, pp. 89-101, 2019, doi: '
        '10.32871/rmrj1907.02.07.'),
    ('A survey of 384 Filipino college students reported significant digital '
        'stress, particularly from social media, with a positive correlation between '
        'digital device engagement and digital stress.',
        'L. Giray, J. Nemeno, J. Braganaza, S. M. Lucero, and R. Bacarra, "A survey on '
        'digital device engagement, digital stress, and coping strategies among college '
        'students in the Philippines," International Journal of Adolescence and Youth, '
        'vol. 29, no. 1, 2024, doi: 10.1080/02673843.2024.2371413.'),
    ('Among 124 third-year students in Davao City, results suggested that stress '
        'influenced academic performance (a descriptive-correlational study).',
        'L. J. C. Simbulas et al., "Level of stress of academic performance of selected '
        'college students of the University of the Immaculate Conception," ARETE, '
        'vol. 5, no. 1, 2017.'),
    ('Filipino users who found a mental health app available and accessible saw it '
        'as beneficial, which supported continued use. The paper also cites a survey '
        'in which only 22% of 359 Filipino college students had ever sought '
        'professional help.',
        'N. Yuduang et al., "Utilizing structural equation modeling-artificial neural '
        'network hybrid approach in determining factors affecting perceived usability '
        'of mobile mental health application in the Philippines," International '
        'Journal of Environmental Research and Public Health, vol. 19, no. 11, Art. '
        'no. 6732, 2022, doi: 10.3390/ijerph19116732.'),
  ]),
  ('MINDFULNESS APPS AND STUDENTS', [
    ('In a randomized trial of 109 Arizona State University undergraduates, an '
        '8-week Calm program lowered stress and raised mindfulness and '
        'self-compassion versus a wait-list group, and the effects held at follow-up. '
        'Participants used the app about 38 minutes a week.',
        'J. Huberty, J. Green, C. Glissmann, L. Larkey, M. Puzia, and C. Lee, "Efficacy '
        'of the mindfulness meditation mobile app Calm to reduce stress among college '
        'students: Randomized controlled trial," JMIR mHealth and uHealth, vol. 7, '
        'no. 6, Art. no. e14273, 2019, doi: 10.2196/14273.'),
    ('A review of randomized trials in college students (47 studies reviewed, 19 '
        'trials analyzed for stress, 2,974 participants) associated mindfulness apps '
        'with reduced stress and improved emotional well-being.',
        'L. G. LaMontagne et al., "Acceptability, usage, and efficacy of mindfulness '
        'apps for college student mental health: A systematic review and meta-analysis '
        'of RCTs," Journal of Affective Disorders, vol. 367, pp. 951-971, 2024, doi: '
        '10.1016/j.jad.2024.09.014.'),
    ('Across 28 trials lasting 7 to 56 days, 19 (68%) reported a positive effect on at '
        'least one aspect of well-being. Most effects were small, the risk of bias was '
        'mostly high, and the authors said the results cannot be generalized widely.',
        'K. Schwartz, F. M. Ganster, and U. S. Tran, "Mindfulness-based mobile apps and '
        'their impact on well-being in nonclinical populations: Systematic review of '
        'randomized controlled trials," Journal of Medical Internet Research, vol. 25, '
        'Art. no. e44638, 2023, doi: 10.2196/44638.'),
    ('Pooling 70 randomized trials, about a quarter of participants (24.7%) dropped '
        'out of mindfulness app trials, and sustained engagement was named as an '
        'important concern.',
        'J. Linardon, "Rates of attrition and engagement in randomized controlled '
        'trials of mindfulness apps: Systematic review and meta-analysis," Behaviour '
        'Research and Therapy, vol. 170, Art. no. 104421, 2023, doi: '
        '10.1016/j.brat.2023.104421.'),
    ('A review of mindfulness programs for university students reported program '
        'durations of 8 weeks to 3 months.',
        'A. M. Gonzalez-Martin, A. Aibar-Almazan, Y. Rivas-Campo, Y. '
        'Castellote-Caballero, and M. C. Carcelen-Fraile, "Mindfulness to improve the '
        'mental health of university students. A systematic review and '
        'meta-analysis," Frontiers in Public Health, vol. 11, Art. no. 1284632, 2023, '
        'doi: 10.3389/fpubh.2023.1284632.'),
  ]),
  ('SCREEN USE, NATURE AND LOCAL APPS', [
    ('Pooling 39 studies with 1,549 participants, mindfulness-based programs were '
        'associated with reductions in problematic internet use, and within-group '
        'analyses also showed reductions in screen time. This links mindfulness to '
        'screen use but does not show that a one-minute prompt can interrupt '
        'scrolling.',
        'J. C. Fendel, A. Vogt, A. Brandtner, and S. Schmidt, "Mindfulness programs for '
        'problematic usage of the internet: A systematic review and meta-analysis," '
        'Journal of Behavioral Addictions, vol. 13, no. 2, pp. 327-353, 2024, doi: '
        '10.1556/2006.2024.00024.'),
    ('A meta-analysis and systematic review of how digital nature and actual nature '
        'affect stress reduction. It is the research behind the calming nature scenes '
        'in Wellness Reminders.',
        'L. Fan and M. R. Baharum, "The effects of digital nature and actual nature on '
        'stress reduction: A meta-analysis and systematic review," Internet '
        'Interventions, 2024, doi: 10.1016/j.invent.2024.100772.'),
    ('In a two-week randomized trial, users of both the Philippine-made Lusog-Isip '
        'app and a workbook improved in psychological well-being and cognitive '
        'reappraisal, and app users scored higher on emotional release.',
        'M. R. Hechanova-Alampay et al., "The development and pilot evaluation of a '
        'mental health mobile app in the Philippines," Mental Health and Social '
        'Inclusion, 2022, doi: 10.1108/MHSI-04-2022-0024.'),
  ]),
  ('ALSO REVIEWED (TITLES ONLY)', [
    ('Mindfulness and academic performance of college and university students: a '
        'systematic review.',
        'I. Tzelepi et al., in GeNeDis 2022, Springer, 2023, pp. 207-215, doi: '
        '10.1007/978-3-031-31986-0_20.'),
    ('Online and traditional mindfulness-based interventions for stress in university '
        'students: a systematic review and meta-analysis.',
        'Y. Wang et al., Frontiers in Psychology, vol. 17, Art. no. 1755245, 2026, doi: '
        '10.3389/fpsyg.2026.1755245.'),
    ('What factors are related to engagement with digital mental health interventions? '
        'A meta-analysis of 117 trials.',
        'N. H. Zainal et al., Health Psychology Review, vol. 20, no. 1, pp. 151-171, '
        '2026, doi: 10.1080/17437199.2025.2547610.'),
    ('Effectiveness of digital health interventions on stress, anxiety, and '
        'depression in university students: a systematic review and meta-analysis.',
        'X. Zhan et al., Journal of Visualized Experiments, 2026, doi: 10.3791/69949.'),
  ]),
];

// PART 2: studies quoted inside the Wellness Reminders texts.
const List<(String, String)> _reminderResearch = [
  ('Negativity bias: negative information carries more weight than positive.',
      'Rozin & Royzman (2001). Personality and Social Psychology Review.'),
  ('A short negative news bulletin raised anxiety and sadness.',
      'Johnston & Davey (1997). British Journal of Psychology.'),
  ('Repeated media exposure after the Boston Marathon bombing predicted acute stress.',
      "Holman, Garfin & Silver (2014). PNAS."),
  ('Doomscrolling was associated with worse mental-health symptoms during COVID-19.',
      'Price et al. (2022). Psychological Trauma: Theory, Research, Practice, and Policy.'),
  ('Limiting social media to about 30 minutes a day reduced loneliness and depression.',
      'Hunt, Marx, Lipson & Young (2018). Journal of Social and Clinical Psychology.'),
  ('Passive scrolling is linked with lower well-being.',
      'Verduyn et al. (2015). Journal of Experimental Psychology: General.'),
  ('Comparing yourself with idealised posts lowers self-esteem.',
      'Vogel et al. (2014). Psychology of Popular Media Culture.'),
  ('Interruptions raise stress and returning to a task takes long.',
      'Mark, Gudith & Klocke (2008). CHI Conference.'),
  ('Heavy media multitaskers did worse on some attention tasks.',
      'Ophir, Nass & Wagner (2009). PNAS.'),
  ('Light-emitting screens before bed delayed melatonin.',
      'Chang, Aeschbach, Duffy & Czeisler (2015). PNAS.'),
  ('Bedtime procrastination is common and linked to poorer sleep.',
      'Kroese et al. (2014). Frontiers in Psychology.'),
  ('Procrastination is largely short-term mood regulation.',
      'Sirois & Pychyl (2013). Social and Personality Psychology Compass.'),
  ('Procrastinators had less stress early but more stress and illness later.',
      'Tice & Baumeister (1997). Psychological Science.'),
  ('Self-forgiveness reduced later procrastination.',
      'Wohl, Pychyl & Bennett (2010). Personality and Individual Differences.'),
  ('"If-then" plans make follow-through more likely.',
      'Gollwitzer & Sheeran (2006). Advances in Experimental Social Psychology.'),
  ('Slow breathing can raise heart-rate variability.',
      'Zaccaro et al. (2018). Frontiers in Human Neuroscience.'),
  ('20 to 30 minutes in nature lowered cortisol.',
      'Hunter, Gillespie & Chen (2019). Frontiers in Psychology.'),
  ('Micro-breaks restore energy and performance.',
      'Albulescu et al. (2022). PLoS ONE.'),
  ('Walking boosted creative thinking.',
      'Oppezzo & Schwartz (2014). Journal of Experimental Psychology: LMC.'),
  ('Writing a plan reduced intrusive thoughts about unfinished tasks.',
      'Masicampo & Baumeister (2011). Journal of Personality and Social Psychology.'),
  ('Noting three good things a day improved happiness.',
      'Seligman et al. (2005). American Psychologist.'),
  ('Strong social relationships are linked with better health and longer life.',
      'Holt-Lunstad, Smith & Layton (2010). PLoS Medicine.'),
];

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The research behind it')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _card(_body(
            'Mindful Minute is built on research about student stress, digital stress, '
            'doomscrolling and mindfulness apps:\n\n'
            '• Filipino students report academic and digital stress, so the app targets '
            'the moment they would otherwise keep scrolling.\n'
            '• Mindfulness apps are associated with lower stress in college students, '
            'but trials are long and about a quarter of people drop out, so every '
            'activity here is short and your choice.\n'
            '• Mindfulness programs are linked with less problematic internet use, '
            'which is why a short guided break is offered at your own limit.\n'
            '• Digital nature is studied for stress reduction, which is why Wellness '
            'Reminders shows calming nature scenes.')),
        _heading('WHAT THE RESEARCH DOES NOT SHOW'),
        _card(_body(
            'In the sources our study reviewed, none tests a one-minute activity or a '
            'prompt to stop scrolling, none ties a student-set app limit to a guided '
            'break inside the app, and none tests a screen lock with Filipino university '
            'students. That is the gap Mindful Minute addresses. Whether it helps is '
            'what our study asks, not something we claim.')),
        for (final (theme, items) in _studyResearch) ...[
          _heading(theme),
          for (final (finding, cite) in items)
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(finding, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 8),
              Text(cite,
                  style: const TextStyle(
                      fontSize: 12, color: Pal.muted, fontStyle: FontStyle.italic)),
            ])),
        ],
        _heading('USED IN THE WELLNESS REMINDERS TEXTS'),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration:
              BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Additional studies quoted in the reminders',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Tap to expand', style: TextStyle(fontSize: 12)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (finding, cite) in _reminderResearch)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(finding, style: const TextStyle(height: 1.35)),
                      Text(cite,
                          style: const TextStyle(
                              fontSize: 12, color: Pal.muted, fontStyle: FontStyle.italic)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
        _heading('A FAIR NOTE'),
        _card(_body(
            'Most of these studies show associations, not guaranteed cause and effect, '
            'and effects differ from person to person. Summaries are in plain language, '
            'so please read the original papers for the full details. Mindful Minute '
            'itself has not been clinically tested and is not a medical or '
            'mental-health service.')),
      ]),
    );
  }
}

// ==================================================================== ABOUT
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _tech(String title, List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Pal.accent, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final i in items)
              Chip(
                label: Text(i, style: const TextStyle(fontSize: 12)),
                backgroundColor: Pal.card2,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SizedBox(height: 8),
        const Center(child: Icon(Icons.self_improvement, size: 72, color: Pal.accent)),
        const SizedBox(height: 12),
        const Center(
          child: Text('Mindful Minute',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        ),
        const Center(
          child: Text('Version $kAppVersion', style: TextStyle(color: Pal.muted)),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'An Android application that interrupts prolonged app use\nthrough guided wellness breaks',
            textAlign: TextAlign.center,
            style: TextStyle(color: Pal.muted),
          ),
        ),

        _heading('OUR MISSION'),
        _card(_body(
            'Endless feeds are designed to keep you scrolling. Mindful Minute gives you '
            'a gentle but firm pause: set a limit for the apps that pull you in, and '
            'when you reach it, take one mindful minute before deciding what to do '
            'next.')),

        _heading('THE STORY BEHIND IT'),
        _card(_body(
            'University students juggle coursework, exams, deadlines and organizations, '
            'and Filipino undergraduates name academic demands as their main source of '
            'stress. Their devices add digital stress, especially from social media. '
            'In short interviews with University of San Agustin students, they said '
            'they take breaks informally (music, games, drawing, sleeping, exercise) '
            'and that scrolling can take over the break. They wanted activities that '
            'are short, varied, freely chosen and not tedious.\n\n'
            'Mindful Minute is our response: your own app limit triggers a short, '
            'structured break made of the activities you chose.')),

        _heading('WHAT YOU GET'),
        _card(_body(
            '• A dashboard of per-app daily limits (5 to 240 minutes) with live usage\n'
            '• Warnings at 70%, 80%, 90% and 100%\n'
            '• A locked wellness break when you hit 100%\n'
            '• Breathing exercise with a 60-second guide\n'
            '• 15 mini-games for focus, memory and calm\n'
            '• Wellness Reminders: 30 calming animated scenes, music, 100+ quotes, '
            'research notes and tips\n'
            '• Progress tracking: sessions, daily streak and history by day\n'
            '• Works offline. No accounts, no ads, no subscriptions')),

        _heading('HOW IT WORKS'),
        _card(_body(
            '1. You choose apps, limits and activities.\n'
            '2. A background monitor checks your time in those apps every 15 seconds, '
            'even when this app is closed.\n'
            '3. You are warned as you approach the limit.\n'
            '4. At 100% the break takes over until you finish your activities.\n'
            '5. Your limit resets and you carry on, free.')),

        _heading('BUILT-IN SAFEGUARDS'),
        _card(_body(
            'A screen lock is a firm kind of interruption, so we added safeguards: '
            'incoming calls still come through, you can still power the phone off, the '
            'lock ends on its own after ten minutes, and you can preview any break '
            'before turning it on. You stay in control: you pick the apps, the limits '
            'and the activities, and the app never assigns activities for you.')),

        _heading('HOW IT IS DIFFERENT'),
        _card(_body(
            'Popular wellness apps such as Headspace, Calm, Insight Timer and Oak are '
            'libraries of guided sessions, and several keep most content behind a '
            'subscription. Lusog-Isip is a Philippine mental-health app with screening, '
            'workbooks and referrals. Mindful Minute is deliberately narrower: one-minute '
            'breaks, offered at the moment your own app limit is reached, delivered '
            'inside the same app, with no subscription.')),

        _heading('BUILT WITH'),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _tech('APP FRAMEWORK', ['Flutter', 'Dart', 'Material 3 (custom dark theme)']),
          _tech('NATIVE ANDROID', [
            'Kotlin',
            'Foreground Service',
            'AccessibilityService',
            'BroadcastReceiver',
            'WindowManager overlay',
            'AlarmManager',
            'NotificationManager',
            'AudioTrack & MediaPlayer',
          ]),
          _tech('ANDROID APIS', [
            'UsageStatsManager / UsageEvents',
            'PackageManager',
            'SharedPreferences (local storage)',
          ]),
          _tech('FLUTTER PACKAGES', [
            'usage_stats',
            'installed_apps',
            'shared_preferences',
            'audioplayers',
            'flutter_local_notifications',
          ]),
          _tech('DESIGN', [
            'CustomPainter animations',
            '30 scene variants',
            'Procedural audio fallback',
          ]),
          _tech('TOOLS & METHOD', [
            'Android Studio',
            'Git & GitHub',
            'Agile / Scrum',
          ]),
        ])),

        _heading('HOW WE BUILT AND TEST IT'),
        _card(_body(
            'Development follows Agile/Scrum: four two-week sprints, each ending in a '
            'working increment that is tested on real Android phones. After the sprints, '
            'the prototype is evaluated by student users and IT experts on '
            'functionality, usability, user engagement and perceived usefulness as a '
            'short break. The study does not test whether the app reduces stress or '
            'scrolling.')),

        _heading('THE SCIENCE'),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _body('Built on published research about student stress, doomscrolling and '
              'mindfulness apps.'),
          TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ResearchScreen())),
            child: const Text('Read the research and references'),
          ),
        ])),

        _heading('PROJECT TEAM'),
        _card(Column(children: [
          for (final (name, role) in kDevelopers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Pal.accent,
                foregroundColor: Colors.black,
                child: Text(name.substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              title: Text(name),
              subtitle: Text(role),
            ),
        ])),

        _heading('ACADEMIC PROJECT'),
        _card(_body(
            'Developed in partial fulfillment of the requirements in IT 311 Project '
            'Management.\n\n'
            'University of San Agustin, Iloilo City, Philippines\n'
            'College of Liberal Arts, Sciences, and Education\n'
            'Bachelor of Science in Information Technology\n\n'
            'Instructor: Rovilyn S. Osalla, MIT\n'
            'S.Y. 2026-2027')),

        _heading('PRIVACY'),
        _card(_body(
            'Everything stays on your phone. No accounts, no ads, no analytics, and the '
            'app does not use the internet. There is no server, so nobody (including '
            'the developers and the university) receives your usage data. If you use '
            'the feedback form, your message is sent by your own email app, only when '
            'you press Send.')),

        _heading('IMPORTANT'),
        _card(_body(
            'Mindful Minute is a supplementary self-guided tool. It does not diagnose '
            'or treat stress or any mental health condition and does not replace '
            'counseling, psychological assessment or professional care. If you are '
            'struggling, please contact a qualified professional or a local helpline.')),

        const SizedBox(height: 4),
        _link(context, Icons.help_outline, 'FAQ', const FaqScreen()),
        _link(context, Icons.verified_user_outlined, 'Why we need permissions',
            const PermissionsInfoScreen()),
        _link(context, Icons.feedback_outlined, 'Send feedback', const FeedbackScreen()),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration:
              BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.description_outlined, color: Pal.accent),
            title: const Text('Open-source licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Mindful Minute',
              applicationVersion: kAppVersion,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Made with care for calmer screens.',
              style: TextStyle(color: Pal.muted, fontSize: 12)),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _link(BuildContext context, IconData icon, String title, Widget page) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration:
            BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: Icon(icon, color: Pal.accent),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
        ),
      );
}

// ============================================================ FEEDBACK FORM
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  String _type = 'Bug report';
  bool _includeDevice = true;
  bool _sending = false;

  static const _types = ['Bug report', 'Suggestion', 'Question', 'Other'];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Pal.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final buf = StringBuffer()
      ..writeln('Type: $_type')
      ..writeln('Name: ${_name.text.trim().isEmpty ? '(not given)' : _name.text.trim()}')
      ..writeln('Reply email: ${_email.text.trim().isEmpty ? '(not given)' : _email.text.trim()}')
      ..writeln()
      ..writeln(_message.text.trim());
    if (_includeDevice) {
      buf
        ..writeln()
        ..writeln('--- Device info ---')
        ..writeln('App version: $kAppVersion')
        ..writeln('Device: ${await GuardService.deviceInfo()}');
    }
    final subject = 'Mindful Minute feedback: $_type';
    final ok = await GuardService.sendEmail(kFeedbackEmail, subject, buf.toString());

    if (!mounted) return;
    setState(() => _sending = false);
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: buf.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No email app found. Your message was copied so you can paste it.'),
        duration: Duration(seconds: 6),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send feedback')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
            'Found a bug or have an idea? Tell us. This opens your email app with '
            'your message ready to send.',
            style: TextStyle(color: Pal.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: _dec('What is this about?'),
            items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _name, decoration: _dec('Your name (optional)')),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Your email, if you want a reply (optional)'),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                  ? null
                  : 'Enter a valid email or leave it empty';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _message,
            minLines: 5,
            maxLines: 10,
            decoration: _dec('Your message', hint: 'What happened? What did you expect?'),
            validator: (v) => (v ?? '').trim().length < 10
                ? 'Please write at least a short sentence (10+ characters)'
                : null,
          ),
          CheckboxListTile(
            value: _includeDevice,
            onChanged: (v) => setState(() => _includeDevice = v ?? true),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Pal.accent,
            title: const Text('Include app version and phone model'),
            subtitle: const Text('Helps us fix bugs. No personal data.',
                style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _sending ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Pal.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: Text(_sending ? 'Opening email...' : 'Send'),
          ),
        ]),
      ),
    );
  }
}
