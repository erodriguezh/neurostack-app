-- ============================================================================
-- NeuroStack Test Data Seed
-- ============================================================================
-- Run with: supabase db reset (runs migrations + seed)
-- Or manually: psql -f seed.sql
-- ============================================================================

-- ============================================================================
-- PROTOCOLS
-- ============================================================================
-- Note: Using OVERRIDING SYSTEM VALUE to set explicit IDs for consistent FK refs

INSERT INTO public.protocols (id, name, target, category, evidence_level, created_at, deleted_at)
OVERRIDING SYSTEM VALUE
VALUES
  -- Heat Therapy
  (1, 'Sauna',
   '{"frequency": {"min_per_week": 3, "max_per_week": 4}, "duration_seconds": 1200, "intensity": "176-212°F (80-100°C)"}'::jsonb,
   'heatTherapy', 'strong', NOW(), NULL),

  (2, 'Hot Bath',
   '{"frequency": {"min_per_week": 3, "max_per_week": 7}, "duration_seconds": 900, "intensity": "104°F (40°C)"}'::jsonb,
   'heatTherapy', 'moderate', NOW(), NULL),

  -- Cold Therapy
  (3, 'Cold Plunge',
   '{"frequency": {"min_per_week": 3, "max_per_week": 5}, "duration_seconds": 180, "intensity": "50-59°F (10-15°C)"}'::jsonb,
   'coldTherapy', 'strong', NOW(), NULL),

  (4, 'Cold Shower',
   '{"frequency": {"min_per_week": 5, "max_per_week": 7}, "duration_seconds": 120, "intensity": "End with 30-60s cold"}'::jsonb,
   'coldTherapy', 'moderate', NOW(), NULL),

  -- Exercise
  (5, 'HIIT',
   '{"frequency": {"min_per_week": 2, "max_per_week": 3}, "duration_seconds": 1200, "intensity": "85-95% max HR"}'::jsonb,
   'exercise', 'proven', NOW(), NULL),

  (6, 'Zone 2 Cardio',
   '{"frequency": {"min_per_week": 3, "max_per_week": 5}, "duration_seconds": 2700, "intensity": "60-70% max HR"}'::jsonb,
   'exercise', 'proven', NOW(), NULL),

  (7, 'Resistance Training',
   '{"frequency": {"min_per_week": 3, "max_per_week": 4}, "duration_seconds": 3600, "intensity": "Progressive overload"}'::jsonb,
   'exercise', 'proven', NOW(), NULL),

  -- Supplementation
  (8, 'Creatine',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "duration_seconds": 60, "intensity": "5g daily"}'::jsonb,
   'supplementation', 'proven', NOW(), NULL),

  (9, 'Omega-3',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "duration_seconds": 60, "intensity": "2-3g EPA+DHA daily"}'::jsonb,
   'supplementation', 'strong', NOW(), NULL),

  (10, 'Vitamin D',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "duration_seconds": 60, "intensity": "2000-5000 IU daily"}'::jsonb,
   'supplementation', 'strong', NOW(), NULL),

  -- Sleep
  (11, 'Sleep Hygiene',
   '{"frequency": {"min_per_week": 7, "max_per_week": 7}, "duration_seconds": 28800, "intensity": "7-9 hours"}'::jsonb,
   'sleep', 'proven', NOW(), NULL),

  -- Mindfulness
  (12, 'Meditation',
   '{"frequency": {"min_per_week": 5, "max_per_week": 7}, "duration_seconds": 600, "intensity": "10-20 minutes"}'::jsonb,
   'mindfulness', 'strong', NOW(), NULL),

  -- Deactivated protocol (for testing soft delete behavior)
  (13, 'Deprecated Protocol',
   '{"frequency": {"min_per_week": 1, "max_per_week": 1}, "duration_seconds": 300, "intensity": "N/A"}'::jsonb,
   'exercise', 'preliminary', NOW() - INTERVAL '30 days', NOW() - INTERVAL '7 days');

-- Reset the sequence to continue after our manual IDs
SELECT setval('public.protocols_id_seq', (SELECT MAX(id) FROM public.protocols));


-- ============================================================================
-- RESEARCH CITATIONS
-- ============================================================================

INSERT INTO public.research_citations (protocol_id, authors, year, title, journal, doi, url)
VALUES
  -- Sauna (protocol_id: 1)
  (1, 'Laukkanen T, Khan H, Zaccardi F, Laukkanen JA',
   2015, 'Association Between Sauna Bathing and Fatal Cardiovascular and All-Cause Mortality Events',
   'JAMA Internal Medicine', '10.1001/jamainternmed.2015.0607',
   'https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2130724'),

  (1, 'Hussain J, Cohen M',
   2018, 'Clinical Effects of Regular Dry Sauna Bathing: A Systematic Review',
   'Evidence-Based Complementary and Alternative Medicine', '10.1155/2018/1857413',
   'https://www.hindawi.com/journals/ecam/2018/1857413/'),

  -- Hot Bath (protocol_id: 2)
  (2, 'Faulkner SH, Jackson S, Fatania G, Leicht CA',
   2017, 'The effect of passive heating on heat shock protein 70 and interleukin-6',
   'Temperature', '10.1080/23328940.2017.1288688',
   NULL),

  -- Cold Plunge (protocol_id: 3)
  (3, 'Srámek P, Simecková M, Janský L, Savlíková J, Vybíral S',
   2000, 'Human physiological responses to immersion into water of different temperatures',
   'European Journal of Applied Physiology', '10.1007/s004210050065',
   NULL),

  (3, 'Buijze GA, Sierevelt IN, van der Heijden BC, Dijkgraaf MG, Frings-Dresen MH',
   2016, 'The Effect of Cold Showering on Health and Work: A Randomized Controlled Trial',
   'PLOS ONE', '10.1371/journal.pone.0161749',
   'https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0161749'),

  -- Cold Shower (protocol_id: 4)
  (4, 'Buijze GA, Sierevelt IN, van der Heijden BC, Dijkgraaf MG, Frings-Dresen MH',
   2016, 'The Effect of Cold Showering on Health and Work: A Randomized Controlled Trial',
   'PLOS ONE', '10.1371/journal.pone.0161749',
   'https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0161749'),

  -- HIIT (protocol_id: 5)
  (5, 'Gibala MJ, Little JP, Macdonald MJ, Hawley JA',
   2012, 'Physiological adaptations to low-volume, high-intensity interval training in health and disease',
   'The Journal of Physiology', '10.1113/jphysiol.2011.224725',
   NULL),

  (5, 'Weston KS, Wisløff U, Coombes JS',
   2014, 'High-intensity interval training in patients with lifestyle-induced cardiometabolic disease',
   'British Journal of Sports Medicine', '10.1136/bjsports-2013-092576',
   NULL),

  -- Zone 2 Cardio (protocol_id: 6)
  (6, 'Seiler S',
   2010, 'What is best practice for training intensity and duration distribution in endurance athletes?',
   'International Journal of Sports Physiology and Performance', '10.1123/ijspp.5.3.276',
   NULL),

  -- Resistance Training (protocol_id: 7)
  (7, 'Schoenfeld BJ, Ogborn D, Krieger JW',
   2017, 'Dose-response relationship between weekly resistance training volume and increases in muscle mass',
   'Journal of Sports Sciences', '10.1080/02640414.2016.1210197',
   NULL),

  (7, 'Peterson MD, Rhea MR, Alvar BA',
   2004, 'Maximizing strength development in athletes: a meta-analysis',
   'Journal of Strength and Conditioning Research', '10.1519/1533-4287(2004)18<377:MSDIAM>2.0.CO;2',
   NULL),

  -- Creatine (protocol_id: 8)
  (8, 'Kreider RB, Kalman DS, Antonio J, et al.',
   2017, 'International Society of Sports Nutrition position stand: safety and efficacy of creatine supplementation',
   'Journal of the International Society of Sports Nutrition', '10.1186/s12970-017-0173-z',
   'https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0173-z'),

  (8, 'Rawson ES, Venezia AC',
   2011, 'Use of creatine in the elderly and evidence for effects on cognitive function in young and old',
   'Amino Acids', '10.1007/s00726-011-0855-9',
   NULL),

  -- Omega-3 (protocol_id: 9)
  (9, 'Calder PC',
   2018, 'Very long-chain n-3 fatty acids and human health: fact, fiction and the future',
   'Proceedings of the Nutrition Society', '10.1017/S0029665117003950',
   NULL),

  (9, 'Swanson D, Block R, Mousa SA',
   2012, 'Omega-3 fatty acids EPA and DHA: health benefits throughout life',
   'Advances in Nutrition', '10.3945/an.111.000893',
   NULL),

  -- Vitamin D (protocol_id: 10)
  (10, 'Holick MF',
   2007, 'Vitamin D deficiency',
   'New England Journal of Medicine', '10.1056/NEJMra070553',
   NULL),

  (10, 'Pludowski P, Holick MF, Grant WB, et al.',
   2018, 'Vitamin D supplementation guidelines',
   'Journal of Steroid Biochemistry and Molecular Biology', '10.1016/j.jsbmb.2017.01.021',
   NULL),

  -- Sleep Hygiene (protocol_id: 11)
  (11, 'Walker M',
   2017, 'Why We Sleep: Unlocking the Power of Sleep and Dreams',
   'Scribner', NULL, NULL),

  (11, 'Hirshkowitz M, Whiton K, Albert SM, et al.',
   2015, 'National Sleep Foundation sleep time duration recommendations',
   'Sleep Health', '10.1016/j.sleh.2014.12.010',
   NULL),

  -- Meditation (protocol_id: 12)
  (12, 'Goyal M, Singh S, Sibinga EM, et al.',
   2014, 'Meditation Programs for Psychological Stress and Well-being',
   'JAMA Internal Medicine', '10.1001/jamainternmed.2013.13018',
   'https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/1809754'),

  (12, 'Tang YY, Hölzel BK, Posner MI',
   2015, 'The neuroscience of mindfulness meditation',
   'Nature Reviews Neuroscience', '10.1038/nrn3916',
   NULL),

  -- Deprecated Protocol (protocol_id: 13) - for testing deactivated with sessions
  (13, 'Test Author',
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