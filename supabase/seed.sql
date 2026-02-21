-- ============================================================================
-- NeuroStack Test Data Seed
-- ============================================================================
-- Run with: supabase db reset (runs migrations + seed)
-- Or manually: psql -f seed.sql
-- ============================================================================

-- ============================================================================
-- PROTOCOLS
-- ============================================================================
-- Note: Letting the DB assign identity IDs to avoid PK collisions with
-- the seed migration (20260221200000_seed_protocols.sql) which inserts
-- 57 protocols before this seed runs.
-- ON CONFLICT DO NOTHING guards against name collisions with canonical
-- protocols (unique index on lower(name)).

INSERT INTO public.protocols (name, description, target, category, evidence_level, created_at, deleted_at)
VALUES
  -- Heat Therapy
  ('Sauna',
   'Traditional dry sauna bathing for cardiovascular and general health benefits.',
   '{"frequency": {"min_per_week": 3, "max_per_week": 4}, "durationSeconds": 1200, "intensity": "176-212°F (80-100°C)"}'::jsonb,
   'heatTherapy', 'singleRct', NOW(), NULL),

  ('Hot Bath',
   'Hot water immersion for passive heat therapy and recovery.',
   '{"frequency": {"min_per_week": 3, "max_per_week": 7}, "durationSeconds": 900, "intensity": "104°F (40°C)"}'::jsonb,
   'heatTherapy', 'observational', NOW(), NULL),

  -- Cold Exposure
  ('Cold Plunge',
   'Full-body cold water immersion for cold exposure benefits.',
   '{"frequency": {"min_per_week": 3, "max_per_week": 5}, "durationSeconds": 180, "intensity": "50-59°F (10-15°C)"}'::jsonb,
   'coldExposure', 'singleRct', NOW(), NULL),

  ('Cold Shower',
   'Ending a shower with cold water for sympathetic nervous system activation.',
   '{"frequency": {"min_per_week": 5, "max_per_week": 7}, "durationSeconds": 120, "intensity": "End with 30-60s cold"}'::jsonb,
   'coldExposure', 'observational', NOW(), NULL),

  -- Exercise
  ('HIIT',
   'High-intensity interval training for cardiovascular fitness and metabolic health.',
   '{"frequency": {"min_per_week": 2, "max_per_week": 3}, "durationSeconds": 1200, "intensity": "85-95% max HR"}'::jsonb,
   'exercise', 'multipleRcts', NOW(), NULL),

  ('Zone 2 Cardio',
   'Low-intensity steady-state cardio in the aerobic zone for endurance.',
   '{"frequency": {"min_per_week": 3, "max_per_week": 5}, "durationSeconds": 2700, "intensity": "60-70% max HR"}'::jsonb,
   'exercise', 'multipleRcts', NOW(), NULL),

  ('Resistance Training',
   'Progressive overload strength training for muscle and bone health.',
   '{"frequency": {"min_per_week": 3, "max_per_week": 4}, "durationSeconds": 3600, "intensity": "Progressive overload"}'::jsonb,
   'exercise', 'multipleRcts', NOW(), NULL),

  -- Supplements
  ('Creatine',
   'Daily creatine monohydrate supplementation for strength and cognition.',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "durationSeconds": 60, "intensity": "5g daily"}'::jsonb,
   'supplements', 'multipleRcts', NOW(), NULL),

  ('Omega-3',
   'Daily omega-3 fatty acid supplementation for systemic anti-inflammatory benefits.',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "durationSeconds": 60, "intensity": "2-3g EPA+DHA daily"}'::jsonb,
   'supplements', 'singleRct', NOW(), NULL),

  ('Vitamin D',
   'Daily vitamin D supplementation for bone health and immune function.',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "durationSeconds": 60, "intensity": "2000-5000 IU daily"}'::jsonb,
   'supplements', 'singleRct', NOW(), NULL),

  -- Sleep
  ('Sleep Hygiene',
   'Consistent sleep-wake schedule and environment optimization for restorative sleep.',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "durationSeconds": 28800, "intensity": "7-9 hours"}'::jsonb,
   'sleep', 'multipleRcts', NOW(), NULL),

  -- Mind
  ('Meditation',
   'Daily mindfulness meditation practice for stress reduction and focus.',
   '{"frequency": {"min_per_week": 5, "max_per_week": 7}, "durationSeconds": 600, "intensity": "10-20 minutes"}'::jsonb,
   'mind', 'singleRct', NOW(), NULL),

  -- Deactivated protocol (for testing soft delete behavior)
  ('Deprecated Protocol',
   'A deprecated test protocol for verifying soft-delete behavior.',
   '{"frequency": {"min_per_week": 1, "max_per_week": 1}, "durationSeconds": 300, "intensity": "N/A"}'::jsonb,
   'exercise', 'expertConsensus', NOW() - INTERVAL '30 days', NOW() - INTERVAL '7 days')
ON CONFLICT ((lower(name))) DO NOTHING;


-- ============================================================================
-- RESEARCH CITATIONS
-- ============================================================================

INSERT INTO public.research_citations (protocol_id, authors, year, title, journal, doi, url)
VALUES
  -- Sauna
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Sauna')),
   'Laukkanen T, Khan H, Zaccardi F, Laukkanen JA',
   2015, 'Association Between Sauna Bathing and Fatal Cardiovascular and All-Cause Mortality Events',
   'JAMA Internal Medicine', '10.1001/jamainternmed.2015.0607',
   'https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2130724'),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Sauna')),
   'Hussain J, Cohen M',
   2018, 'Clinical Effects of Regular Dry Sauna Bathing: A Systematic Review',
   'Evidence-Based Complementary and Alternative Medicine', '10.1155/2018/1857413',
   'https://www.hindawi.com/journals/ecam/2018/1857413/'),

  -- Hot Bath
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Hot Bath')),
   'Faulkner SH, Jackson S, Fatania G, Leicht CA',
   2017, 'The effect of passive heating on heat shock protein 70 and interleukin-6',
   'Temperature', '10.1080/23328940.2017.1288688',
   NULL),

  -- Cold Plunge
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Cold Plunge')),
   'Srámek P, Simecková M, Janský L, Savlíková J, Vybíral S',
   2000, 'Human physiological responses to immersion into water of different temperatures',
   'European Journal of Applied Physiology', '10.1007/s004210050065',
   NULL),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Cold Plunge')),
   'Buijze GA, Sierevelt IN, van der Heijden BC, Dijkgraaf MG, Frings-Dresen MH',
   2016, 'The Effect of Cold Showering on Health and Work: A Randomized Controlled Trial',
   'PLOS ONE', '10.1371/journal.pone.0161749',
   'https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0161749'),

  -- Cold Shower
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Cold Shower')),
   'Buijze GA, Sierevelt IN, van der Heijden BC, Dijkgraaf MG, Frings-Dresen MH',
   2016, 'The Effect of Cold Showering on Health and Work: A Randomized Controlled Trial',
   'PLOS ONE', '10.1371/journal.pone.0161749',
   'https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0161749'),

  -- HIIT
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('HIIT')),
   'Gibala MJ, Little JP, Macdonald MJ, Hawley JA',
   2012, 'Physiological adaptations to low-volume, high-intensity interval training in health and disease',
   'The Journal of Physiology', '10.1113/jphysiol.2011.224725',
   NULL),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('HIIT')),
   'Weston KS, Wisloff U, Coombes JS',
   2014, 'High-intensity interval training in patients with lifestyle-induced cardiometabolic disease',
   'British Journal of Sports Medicine', '10.1136/bjsports-2013-092576',
   NULL),

  -- Zone 2 Cardio
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Zone 2 Cardio')),
   'Seiler S',
   2010, 'What is best practice for training intensity and duration distribution in endurance athletes?',
   'International Journal of Sports Physiology and Performance', '10.1123/ijspp.5.3.276',
   NULL),

  -- Resistance Training
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Resistance Training')),
   'Schoenfeld BJ, Ogborn D, Krieger JW',
   2017, 'Dose-response relationship between weekly resistance training volume and increases in muscle mass',
   'Journal of Sports Sciences', '10.1080/02640414.2016.1210197',
   NULL),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Resistance Training')),
   'Peterson MD, Rhea MR, Alvar BA',
   2004, 'Maximizing strength development in athletes: a meta-analysis',
   'Journal of Strength and Conditioning Research', '10.1519/1533-4287(2004)18<377:MSDIAM>2.0.CO;2',
   NULL),

  -- Creatine
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Creatine')),
   'Kreider RB, Kalman DS, Antonio J, et al.',
   2017, 'International Society of Sports Nutrition position stand: safety and efficacy of creatine supplementation',
   'Journal of the International Society of Sports Nutrition', '10.1186/s12970-017-0173-z',
   'https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0173-z'),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Creatine')),
   'Rawson ES, Venezia AC',
   2011, 'Use of creatine in the elderly and evidence for effects on cognitive function in young and old',
   'Amino Acids', '10.1007/s00726-011-0855-9',
   NULL),

  -- Omega-3
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Omega-3')),
   'Calder PC',
   2018, 'Very long-chain n-3 fatty acids and human health: fact, fiction and the future',
   'Proceedings of the Nutrition Society', '10.1017/S0029665117003950',
   NULL),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Omega-3')),
   'Swanson D, Block R, Mousa SA',
   2012, 'Omega-3 fatty acids EPA and DHA: health benefits throughout life',
   'Advances in Nutrition', '10.3945/an.111.000893',
   NULL),

  -- Vitamin D
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Vitamin D')),
   'Holick MF',
   2007, 'Vitamin D deficiency',
   'New England Journal of Medicine', '10.1056/NEJMra070553',
   NULL),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Vitamin D')),
   'Pludowski P, Holick MF, Grant WB, et al.',
   2018, 'Vitamin D supplementation guidelines',
   'Journal of Steroid Biochemistry and Molecular Biology', '10.1016/j.jsbmb.2017.01.021',
   NULL),

  -- Sleep Hygiene
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Sleep Hygiene')),
   'Walker M',
   2017, 'Why We Sleep: Unlocking the Power of Sleep and Dreams',
   'Scribner', NULL, NULL),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Sleep Hygiene')),
   'Hirshkowitz M, Whiton K, Albert SM, et al.',
   2015, 'National Sleep Foundation sleep time duration recommendations',
   'Sleep Health', '10.1016/j.sleh.2014.12.010',
   NULL),

  -- Meditation
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Meditation')),
   'Goyal M, Singh S, Sibinga EM, et al.',
   2014, 'Meditation Programs for Psychological Stress and Well-being',
   'JAMA Internal Medicine', '10.1001/jamainternmed.2013.13018',
   'https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/1809754'),

  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Meditation')),
   'Tang YY, Holzel BK, Posner MI',
   2015, 'The neuroscience of mindfulness meditation',
   'Nature Reviews Neuroscience', '10.1038/nrn3916',
   NULL),

  -- Deprecated Protocol - for testing deactivated with sessions
  ((SELECT id FROM public.protocols WHERE lower(name) = lower('Deprecated Protocol')),
   'Test Author',
   2020, 'Test Citation for Deprecated Protocol',
   'Test Journal', NULL, NULL);


-- ============================================================================
-- VERIFICATION QUERIES (can be removed after testing)
-- ============================================================================
-- SELECT COUNT(*) as protocol_count FROM public.protocols;
-- SELECT COUNT(*) as citation_count FROM public.research_citations;
-- SELECT p.name, COUNT(c.id) as citations
--   FROM public.protocols p
--   LEFT JOIN public.research_citations c ON c.protocol_id = p.id
--   GROUP BY p.id, p.name
--   ORDER BY p.id;
