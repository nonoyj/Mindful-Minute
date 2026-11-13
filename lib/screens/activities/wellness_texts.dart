/// Texts for "Wellness Reminders": 50 in total.
///   12 Bible verses (KJV, public domain), 10 quotes, 10 research notes,
///   12 tips, 6 small self-care reminders.
///
/// Research notes are short plain-language summaries. Please double-check
/// the cited papers yourself before publishing the app.
class WellnessText {
  final String kind;
  final String text;
  const WellnessText(this.kind, this.text);
}

const _verses = [
  'Be still, and know that I am God. (Psalm 46:10, KJV)',
  'Turn away mine eyes from beholding vanity; and quicken thou me in thy way. (Psalm 119:37, KJV)',
  'Whatsoever things are true, whatsoever things are lovely, whatsoever things are of good report... think on these things. (Philippians 4:8, KJV)',
  'See then that ye walk circumspectly, not as fools, but as wise, redeeming the time. (Ephesians 5:15-16, KJV)',
  'So teach us to number our days, that we may apply our hearts unto wisdom. (Psalm 90:12, KJV)',
  'Set your affection on things above, not on things on the earth. (Colossians 3:2, KJV)',
  'Let thine eyes look right on, and let thine eyelids look straight before thee. (Proverbs 4:25, KJV)',
  'Take therefore no thought for the morrow: for the morrow shall take thought for the things of itself. Sufficient unto the day is the evil thereof. (Matthew 6:34, KJV)',
  'Thou wilt keep him in perfect peace, whose mind is stayed on thee: because he trusteth in thee. (Isaiah 26:3, KJV)',
  'And let us not be weary in well doing: for in due season we shall reap, if we faint not. (Galatians 6:9, KJV)',
  'All things are lawful unto me, but all things are not expedient: I will not be brought under the power of any. (1 Corinthians 6:12, KJV)',
  'Come unto me, all ye that labour and are heavy laden, and I will give you rest. (Matthew 11:28, KJV)',
];

const _quotes = [
  'Start before you feel ready. Momentum is built by moving.',
  'Five minutes of effort beats an hour of dreading it.',
  'The scroll will still be there later. Your goals will not wait forever.',
  'Pick one task. Only one. Begin it now.',
  'Your attention is your life, spent one moment at a time.',
  'The urge to avoid is not an order. It is just a feeling.',
  "You can't scroll your way to the life you want.",
  'You are allowed to put the phone down.',
  "Boredom is not an emergency. It's where ideas begin.",
  'Look up. The real world is still here.',
];

const _research = [
  'Our brains give extra weight to negative information, a pattern called negativity bias. Bad-news feeds exploit it. (Rozin & Royzman, 2001)',
  "In an experiment, a short negative news bulletin raised anxiety and sadness and made people's own worries feel bigger. (Johnston & Davey, 1997)",
  'Limiting social media to about 30 minutes a day reduced loneliness and depression over three weeks. (Hunt et al., 2018)',
  'Passive scrolling, watching others without interacting, is linked with lower well-being than active, connected use. (Verduyn et al., 2015)',
  'Reading on a light-emitting screen before bed delayed melatonin release and made mornings harder. (Chang et al., 2015)',
  'Procrastination is largely an emotion-regulation problem: we avoid tasks to escape bad feelings. (Sirois & Pychyl, 2013)',
  'Forgiving yourself for procrastinating made students less likely to procrastinate on the next exam. (Wohl et al., 2010)',
  "'If-then' plans, like 'If I feel the urge to scroll, then I will stand up', make follow-through noticeably more likely. (Gollwitzer & Sheeran, 2006)",
  'Slow breathing, around six breaths a minute, can raise heart-rate variability, a marker of calm. (Zaccaro et al., 2018)',
  'Short micro-breaks can restore energy and attention. (Albulescu et al., 2022)',
];

const _tips = [
  'Put your phone in another room while you work. Out of sight is easier than willpower.',
  'Set a news window: check headlines once or twice a day, then stop.',
  'Turn off non-essential notifications. Every buzz is an invitation to scroll.',
  'Move social apps off your home screen, or log out after each use. Add friction.',
  'Charge your phone outside the bedroom and use a real alarm clock.',
  'Before you open an app, ask: what am I here for? If you have no answer, put it down.',
  'Replace the habit: when you reach for the phone, take three slow breaths first.',
  'Unfollow accounts that leave you anxious, angry or drained. Curate your feed.',
  'Use the 10-minute rule: when the urge hits, wait ten minutes. Most urges fade.',
  "When you catch yourself doomscrolling, say 'I'm doomscrolling' out loud. Naming it breaks the trance.",
  'If the news weighs on you, choose one small action, like donating, volunteering or writing a note, instead of more scrolling.',
  'Create a wind-down routine: no screens for the last 30 to 60 minutes before sleep.',
];

const _reminders = [
  'Drink a glass of water.',
  'Roll your shoulders back, slowly, three times.',
  'Look at something far away for 20 seconds.',
  'Unclench your jaw and relax your hands.',
  'Take one deep breath in through your nose, out through your mouth.',
  "Think of one thing you're grateful for today.",
];

final List<WellnessText> kWellnessTexts = [
  for (final t in _verses) WellnessText('Verse', t),
  for (final t in _quotes) WellnessText('Quote', t),
  for (final t in _research) WellnessText('Research', t),
  for (final t in _tips) WellnessText('Try this', t),
  for (final t in _reminders) WellnessText('Reminder', t),
];
