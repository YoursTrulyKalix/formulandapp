// lib/core/data/f1_data.dart
// 2026 F1 grid + hardcoded 2026 race calendar (22 rounds after Bahrain/Saudi cancelled)

import 'package:flutter/material.dart';

// ── Driver Model ──────────────────────────────────────────────────────────────
class F1Driver {
  final String code, name, number, team, teamColor, nationality, bio,
      championships, wins, poles, podiums, fastestLaps, firstSeason;

  const F1Driver({
    required this.code, required this.name, required this.number,
    required this.team, required this.teamColor, required this.nationality,
    required this.bio, required this.championships, required this.wins,
    required this.poles, required this.podiums, required this.fastestLaps,
    required this.firstSeason,
  });
}

// ── Race Model ────────────────────────────────────────────────────────────────
class F1Race {
  final int round;
  final String raceName, circuit, country, flagEmoji;
  final DateTime raceDate;
  final bool isSprint;
  final bool isLive;
  final bool isUpcoming;
  final bool isCompleted;

  const F1Race({
    required this.round, required this.raceName, required this.circuit,
    required this.country, required this.flagEmoji, required this.raceDate,
    this.isSprint = false,
    required this.isLive, required this.isUpcoming, required this.isCompleted,
  });
}

// ── F1 Data Service ───────────────────────────────────────────────────────────
class F1DataService {
  static final F1DataService instance = F1DataService._internal();
  F1DataService._internal();

  // ── 2026 Full Calendar (22 rounds — Bahrain & Saudi cancelled) ─────────────
  static List<F1Race> get calendar {
    final now = DateTime.now();

    F1Race race(int round, String name, String circuit, String country,
        String flag, DateTime date, {bool sprint = false}) {
      final raceEnd = date.add(const Duration(hours: 2));
      return F1Race(
        round: round, raceName: name, circuit: circuit,
        country: country, flagEmoji: flag, raceDate: date,
        isSprint: sprint,
        isLive: now.isAfter(date) && now.isBefore(raceEnd),
        isUpcoming: date.isAfter(now),
        isCompleted: now.isAfter(raceEnd),
      );
    }

    return [
      race(1,  'Australian Grand Prix',          'Albert Park Circuit',           'Australia',     '🇦🇺', DateTime(2026, 3, 8,  6, 0)),
      race(2,  'Chinese Grand Prix',             'Shanghai International Circuit','China',          '🇨🇳', DateTime(2026, 3, 15, 7, 0),  sprint: true),
      race(3,  'Japanese Grand Prix',            'Suzuka Circuit',                'Japan',          '🇯🇵', DateTime(2026, 3, 29, 6, 0)),
      race(4,  'Miami Grand Prix',               'Miami International Autodrome', 'United States',  '🇺🇸', DateTime(2026, 5, 3,  20, 0), sprint: true),
      race(5,  'Canadian Grand Prix',            'Circuit Gilles Villeneuve',     'Canada',         '🇨🇦', DateTime(2026, 5, 24, 19, 0), sprint: true),
      race(6,  'Barcelona-Catalunya Grand Prix', 'Circuit de Barcelona-Catalunya','Spain',           '🇪🇸', DateTime(2026, 6, 7,  13, 0)),
      race(7,  'Monaco Grand Prix',              'Circuit de Monaco',             'Monaco',         '🇲🇨', DateTime(2026, 6, 28, 13, 0)),
      race(8,  'Austrian Grand Prix',            'Red Bull Ring',                 'Austria',        '🇦🇹', DateTime(2026, 7, 5,  13, 0)),
      race(9,  'British Grand Prix',             'Silverstone Circuit',           'Great Britain',  '🇬🇧', DateTime(2026, 7, 19, 14, 0), sprint: true),
      race(10, 'Belgian Grand Prix',             'Circuit de Spa-Francorchamps', 'Belgium',        '🇧🇪', DateTime(2026, 8, 2,  13, 0)),
      race(11, 'Dutch Grand Prix',               'Circuit Zandvoort',             'Netherlands',    '🇳🇱', DateTime(2026, 8, 30, 13, 0), sprint: true),
      race(12, 'Italian Grand Prix',             'Autodromo Nazionale Monza',    'Italy',          '🇮🇹', DateTime(2026, 9, 6,  13, 0)),
      race(13, 'Madrid Grand Prix',              'Madring Street Circuit',        'Spain',          '🇪🇸', DateTime(2026, 9, 20, 13, 0)),
      race(14, 'Azerbaijan Grand Prix',          'Baku City Circuit',             'Azerbaijan',     '🇦🇿', DateTime(2026, 9, 27, 11, 0)),
      race(15, 'Singapore Grand Prix',           'Marina Bay Street Circuit',     'Singapore',      '🇸🇬', DateTime(2026, 10, 4, 12, 0), sprint: true),
      race(16, 'United States Grand Prix',       'Circuit of the Americas',       'United States',  '🇺🇸', DateTime(2026, 10, 18, 19, 0)),
      race(17, 'Mexico City Grand Prix',         'Autodromo Hermanos Rodriguez',  'Mexico',         '🇲🇽', DateTime(2026, 10, 25, 20, 0)),
      race(18, 'São Paulo Grand Prix',           'Autodromo Jose Carlos Pace',    'Brazil',         '🇧🇷', DateTime(2026, 11, 8,  17, 0)),
      race(19, 'Las Vegas Grand Prix',           'Las Vegas Strip Circuit',       'United States',  '🇺🇸', DateTime(2026, 11, 21, 6, 0)),
      race(20, 'Qatar Grand Prix',               'Lusail International Circuit',  'Qatar',          '🇶🇦', DateTime(2026, 11, 29, 15, 0)),
      race(21, 'Japanese Grand Prix',            'Suzuka Circuit',                'Japan',          '🇯🇵', DateTime(2026, 12, 5,  5, 0)),  // placeholder if calendar shifts
      race(22, 'Abu Dhabi Grand Prix',           'Yas Marina Circuit',            'UAE',            '🇦🇪', DateTime(2026, 12, 6,  13, 0)),
    ];
  }

  // ── Get live race ──────────────────────────────────────────────────────────
  F1Race? getLiveRace() {
    try { return calendar.firstWhere((r) => r.isLive); } catch (_) { return null; }
  }

  // ── Get next upcoming race ─────────────────────────────────────────────────
  F1Race? getNextRace() {
    try { return calendar.firstWhere((r) => r.isUpcoming); } catch (_) { return null; }
  }

  // ── Get current or next race (used by banner) ──────────────────────────────
  F1Race? getCurrentOrNext() => getLiveRace() ?? getNextRace();

  // ── 2026 Grid — all 22 drivers ─────────────────────────────────────────────
  static const List<F1Driver> drivers = [
    // McLaren
    F1Driver(code:'NOR', name:'Lando Norris',      number:'4',  team:'McLaren',       teamColor:'#FF8000', nationality:'🇬🇧 British',         bio:'2025 World Champion and McLaren\'s heartbeat. Norris ended McLaren\'s 26-year wait for the Drivers\' Championship in a dramatic 2025 season. Lightning fast, endlessly entertaining, and now the benchmark every driver measures themselves against.',                                                                                                                                championships:'1', wins:'10', poles:'12', podiums:'40', fastestLaps:'13', firstSeason:'2019'),
    F1Driver(code:'PIA', name:'Oscar Piastri',     number:'81', team:'McLaren',       teamColor:'#FF8000', nationality:'🇦🇺 Australian',        bio:'The quiet assassin who led the 2025 championship for most of the season. Piastri is devastatingly fast and ice-cold under pressure. In 2026 he arrives with a point to prove and machinery good enough to win it all.',                                                                                                                                              championships:'0', wins:'5',  poles:'6',  podiums:'22', fastestLaps:'6',  firstSeason:'2023'),
    // Ferrari
    F1Driver(code:'LEC', name:'Charles Leclerc',   number:'16', team:'Ferrari',       teamColor:'#E8002D', nationality:'🇲🇨 Monégasque',        bio:'Ferrari\'s talisman and the idol of the Tifosi. His Monaco win in 2024 was one of the most emotional victories in modern F1. Locked in until 2029, entering the new regulations era with Hamilton at his side.',                                                                                                                                             championships:'0', wins:'9',  poles:'26', podiums:'52', fastestLaps:'9',  firstSeason:'2018'),
    F1Driver(code:'HAM', name:'Lewis Hamilton',    number:'44', team:'Ferrari',       teamColor:'#E8002D', nationality:'🇬🇧 British',           bio:'The most decorated driver in F1 history. Seven World Championships, 103 wins, 104 poles. In his second Ferrari season, Hamilton is finding his rhythm in red. The dream of an eighth title at Ferrari would be the greatest sporting story ever told.',                                                                                                          championships:'7', wins:'103',poles:'104',podiums:'197',fastestLaps:'67', firstSeason:'2007'),
    // Mercedes
    F1Driver(code:'RUS', name:'George Russell',    number:'63', team:'Mercedes',      teamColor:'#27F4D2', nationality:'🇬🇧 British',           bio:'Bookies\' favourite heading into 2026. Russell is the complete package — relentlessly fast in qualifying, increasingly dangerous in races, and technically brilliant. With Mercedes believed to have nailed the new regulations, this could finally be George\'s title year.',                                                                                     championships:'0', wins:'3',  poles:'7',  podiums:'24', fastestLaps:'9',  firstSeason:'2019'),
    F1Driver(code:'ANT', name:'Kimi Antonelli',    number:'12', team:'Mercedes',      teamColor:'#27F4D2', nationality:'🇮🇹 Italian',           bio:'The most exciting young talent since Verstappen. Three podiums in his rookie 2025 season. His driving style draws inevitable comparisons to a young Senna. In 2026, year two, the pressure is on to convert pace into wins.',                                                                                                                                championships:'0', wins:'0',  poles:'2',  podiums:'3',  fastestLaps:'1',  firstSeason:'2025'),
    // Red Bull
    F1Driver(code:'VER', name:'Max Verstappen',    number:'1',  team:'Red Bull',      teamColor:'#3671C6', nationality:'🇳🇱 Dutch',            bio:'Four-time World Champion. Verstappen\'s dominance was checked in 2025 but he remains the single most dangerous driver on the grid. Locked in until 2028, facing his biggest challenge yet in the new 2026 regulations cycle.',                                                                                                                              championships:'4', wins:'63', poles:'41', podiums:'112',fastestLaps:'31', firstSeason:'2015'),
    F1Driver(code:'HAD', name:'Isack Hadjar',      number:'6',  team:'Red Bull',      teamColor:'#3671C6', nationality:'🇫🇷 French-Algerian',   bio:'Red Bull\'s next great hope steps up to the senior team. Hadjar dominated F2 in 2024 with maturity that belied his age. Partnering Verstappen is the ultimate test — Red Bull believe he is ready.',                                                                                                                                                    championships:'0', wins:'0',  poles:'1',  podiums:'2',  fastestLaps:'1',  firstSeason:'2025'),
    // Williams
    F1Driver(code:'SAI', name:'Carlos Sainz',      number:'55', team:'Williams',      teamColor:'#64C4FF', nationality:'🇪🇸 Spanish',           bio:'One of the most complete drivers on the grid. Won in Australia 2024 days after an appendix operation. At Williams with a mission to drag the historic team back to the front.',                                                                                                                                                                           championships:'0', wins:'4',  poles:'5',  podiums:'24', fastestLaps:'5',  firstSeason:'2015'),
    F1Driver(code:'ALB', name:'Alexander Albon',   number:'23', team:'Williams',      teamColor:'#64C4FF', nationality:'🇹🇭 Thai-British',       bio:'The comeback king entering his fifth season with Williams. Albon has been the bedrock of Williams\' revival, consistently extracting points from machinery that shouldn\'t deliver them. A pillar of the paddock.',                                                                                                                                       championships:'0', wins:'0',  poles:'0',  podiums:'2',  fastestLaps:'0',  firstSeason:'2019'),
    // Aston Martin
    F1Driver(code:'ALO', name:'Fernando Alonso',   number:'14', team:'Aston Martin',  teamColor:'#229971', nationality:'🇪🇸 Spanish',           bio:'At 44, Alonso enters what may be his final season with renewed hope. Adrian Newey has arrived, Honda power is new, regulations have reset. If ever there was a moment for a third championship — this is it. El Plan has never been more alive.',                                                                                                         championships:'2', wins:'32', poles:'22', podiums:'106',fastestLaps:'23', firstSeason:'2001'),
    F1Driver(code:'STR', name:'Lance Stroll',      number:'18', team:'Aston Martin',  teamColor:'#229971', nationality:'🇨🇦 Canadian',          bio:'Entering his 10th F1 season. His pole in Baku remains a reminder of his ceiling. With Newey\'s car underneath him in 2026, Stroll could have his best season yet.',                                                                                                                                                                                   championships:'0', wins:'0',  poles:'1',  podiums:'3',  fastestLaps:'0',  firstSeason:'2017'),
    // Alpine
    F1Driver(code:'GAS', name:'Pierre Gasly',      number:'10', team:'Alpine',        teamColor:'#FF87BC', nationality:'🇫🇷 French',            bio:'Alpine\'s team leader and France\'s greatest active F1 hope. His journey from being dropped by Red Bull to winning at Monza 2020 is one of the most remarkable in modern F1.',                                                                                                                                                                         championships:'0', wins:'1',  poles:'0',  podiums:'4',  fastestLaps:'3',  firstSeason:'2017'),
    F1Driver(code:'COL', name:'Franco Colapinto',  number:'43', team:'Alpine',        teamColor:'#FF87BC', nationality:'🇦🇷 Argentine',          bio:'Argentina\'s first F1 driver in decades. Burst onto the scene as a Williams substitute in 2024 with spectacular pace. Passionate, raw, and fearless — South America has a new hero.',                                                                                                                                                                championships:'0', wins:'0',  poles:'0',  podiums:'0',  fastestLaps:'0',  firstSeason:'2024'),
    // Haas
    F1Driver(code:'BEA', name:'Oliver Bearman',    number:'87', team:'Haas',          teamColor:'#B6BABD', nationality:'🇬🇧 British',           bio:'Britain\'s next superstar in his sophomore season. First grabbed attention with a stunning points finish as a Ferrari substitute in Saudi 2024 aged 18. Cool-headed, technically gifted, already on Ferrari\'s radar.',                                                                                                                                  championships:'0', wins:'0',  poles:'0',  podiums:'0',  fastestLaps:'0',  firstSeason:'2025'),
    F1Driver(code:'OCO', name:'Esteban Ocon',      number:'31', team:'Haas',          teamColor:'#B6BABD', nationality:'🇫🇷 French',            bio:'2021 Hungarian GP winner. Ocon has spent his career fighting in the midfield with everything he has. Joins Haas with experience and renewed motivation. On his day, capable of results that embarrass much bigger operations.',                                                                                                                         championships:'0', wins:'1',  poles:'0',  podiums:'3',  fastestLaps:'2',  firstSeason:'2016'),
    // Racing Bulls
    F1Driver(code:'LAW', name:'Liam Lawson',       number:'30', team:'Racing Bulls',  teamColor:'#6692FF', nationality:'🇳🇿 New Zealander',     bio:'New Zealand\'s finest current motorsport export. Racing Bulls\' undisputed lead driver in 2026. Technical, precise, and physically imposing — the Kiwi racer has enormous potential still to unlock.',                                                                                                                                                  championships:'0', wins:'0',  poles:'0',  podiums:'0',  fastestLaps:'0',  firstSeason:'2024'),
    F1Driver(code:'LIN', name:'Arvid Lindblad',    number:'8',  team:'Racing Bulls',  teamColor:'#6692FF', nationality:'🇬🇧 British-Swedish',   bio:'The only true rookie on the 2026 grid and Red Bull\'s most prized junior talent. Dominated junior categories with calmness and intelligence. At 18 he steps into F1 with the path to the senior Red Bull seat running directly through his performances.',                                                                                               championships:'0', wins:'0',  poles:'0',  podiums:'0',  fastestLaps:'0',  firstSeason:'2026'),
    // Audi
    F1Driver(code:'HUL', name:'Nico Hülkenberg',   number:'27', team:'Audi',          teamColor:'#C0D800', nationality:'🇩🇪 German',            bio:'The cornerstone of Audi\'s F1 project. Over 220 starts, technically brilliant feedback. At 38 he leads Germany\'s greatest motorsport return since Mercedes in 2010.',                                                                                                                                                                              championships:'0', wins:'0',  poles:'1',  podiums:'0',  fastestLaps:'9',  firstSeason:'2010'),
    F1Driver(code:'BOR', name:'Gabriel Bortoleto', number:'5',  team:'Audi',          teamColor:'#C0D800', nationality:'🇧🇷 Brazilian',          bio:'Brazil\'s newest F1 star and 2024 F2 champion. Enters 2026 as a key part of Audi\'s multi-year plan to reach the front of the grid.',                                                                                                                                                                                                           championships:'0', wins:'0',  poles:'1',  podiums:'2',  fastestLaps:'0',  firstSeason:'2025'),
    // Cadillac
    F1Driver(code:'PER', name:'Sergio Pérez',      number:'11', team:'Cadillac',      teamColor:'#960000', nationality:'🇲🇽 Mexican',           bio:'Mexico\'s greatest racing hero returns to F1. Dropped by Red Bull at end of 2024, Pérez refused to walk away and accepted the Cadillac challenge. His race-management skills and 260+ starts make him the perfect anchor. Checo is back.',                                                                                                           championships:'0', wins:'6',  poles:'3',  podiums:'35', fastestLaps:'10', firstSeason:'2011'),
    F1Driver(code:'BOT', name:'Valtteri Bottas',   number:'77', team:'Cadillac',      teamColor:'#960000', nationality:'🇫🇮 Finnish',           bio:'Over 220 race starts and championship-fighting experience at Mercedes. The ideal co-pilot for an operation finding its feet. Calm, meticulous, and underrated — Bottas remains one of the cleanest racers on the grid.',                                                                                                                              championships:'0', wins:'10', poles:'20', podiums:'67', fastestLaps:'19', firstSeason:'2013'),
  ];

  static F1Driver? getDriver(String code) {
    try { return drivers.firstWhere((d) => d.code == code); } catch (_) { return null; }
  }

  static List<F1Driver> getTeamDrivers(String team) =>
      drivers.where((d) => d.team == team).toList();
}