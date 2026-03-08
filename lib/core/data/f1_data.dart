// lib/core/data/f1_data.dart
// Complete 2026 F1 grid — all 22 drivers, 11 teams + race schedule via Ergast API

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Driver Model ──────────────────────────────────────────────────────────────

class F1Driver {
  final String code;
  final String name;
  final String number;
  final String team;
  final String teamColor;
  final String nationality;
  final String bio;
  final String championships;
  final String wins;
  final String poles;
  final String podiums;
  final String fastestLaps;
  final String firstSeason;

  const F1Driver({
    required this.code,
    required this.name,
    required this.number,
    required this.team,
    required this.teamColor,
    required this.nationality,
    required this.bio,
    required this.championships,
    required this.wins,
    required this.poles,
    required this.podiums,
    required this.fastestLaps,
    required this.firstSeason,
  });
}

// ── Race Model ────────────────────────────────────────────────────────────────

class F1Race {
  final String raceName;
  final String circuit;
  final String country;
  final DateTime raceDate;
  final int? currentLap;
  final int? totalLaps;
  final bool isLive;
  final bool isUpcoming;

  const F1Race({
    required this.raceName,
    required this.circuit,
    required this.country,
    required this.raceDate,
    this.currentLap,
    this.totalLaps,
    required this.isLive,
    required this.isUpcoming,
  });
}

// ── F1 Data Service ───────────────────────────────────────────────────────────

class F1DataService {
  static final F1DataService instance = F1DataService._internal();
  F1DataService._internal();

  // ── Complete 2026 F1 Grid — All 22 Drivers, 11 Teams ─────────────────────
  static const List<F1Driver> drivers = [

    // ── McLAREN-MERCEDES (Reigning Champions) ─────────────────────────────────
    F1Driver(
      code: 'NOR', name: 'Lando Norris', number: '4',
      team: 'McLaren', teamColor: '#FF8000',
      nationality: '🇬🇧 British',
      bio: '2025 World Champion and McLaren\'s heartbeat. Norris finally conquered his title demons in a dramatic 2025 season, ending a 26-year wait for McLaren in the Drivers\' Championship. Lightning fast, endlessly entertaining off track, and now the benchmark every driver measures themselves against. Entering his eighth season with his only F1 team.',
      championships: '1', wins: '10', poles: '12', podiums: '40', fastestLaps: '13', firstSeason: '2019',
    ),
    F1Driver(
      code: 'PIA', name: 'Oscar Piastri', number: '81',
      team: 'McLaren', teamColor: '#FF8000',
      nationality: '🇦🇺 Australian',
      bio: 'The quiet assassin who led the 2025 championship for most of the season before finishing third. Piastri is devastatingly fast and ice-cold under pressure — many believe he is the better technical driver of the McLaren duo. In 2026 he arrives with a point to prove and machinery good enough to win it all.',
      championships: '0', wins: '5', poles: '6', podiums: '22', fastestLaps: '6', firstSeason: '2023',
    ),

    // ── FERRARI ──────────────────────────────────────────────────────────────
    F1Driver(
      code: 'LEC', name: 'Charles Leclerc', number: '16',
      team: 'Ferrari', teamColor: '#E8002D',
      nationality: '🇲🇨 Monégasque',
      bio: 'Ferrari\'s talisman and the idol of the Tifosi. Leclerc secured a long-term deal through 2029, cementing his place as the future of the Scuderia. His Monaco win in 2024 remains one of the most emotional victories in modern F1. Now entering the new regulations era with Hamilton at his side — the pressure to deliver has never been higher.',
      championships: '0', wins: '9', poles: '26', podiums: '52', fastestLaps: '9', firstSeason: '2018',
    ),
    F1Driver(
      code: 'HAM', name: 'Lewis Hamilton', number: '44',
      team: 'Ferrari', teamColor: '#E8002D',
      nationality: '🇬🇧 British',
      bio: 'The greatest of all time. Seven World Championships, 103 wins, 104 pole positions — the records speak for themselves. In his second Ferrari season Hamilton is finding his rhythm in red. Pre-season testing showed his raw pace is undiminished at 41. The dream of an eighth championship at Ferrari would be the greatest sporting story ever told.',
      championships: '7', wins: '103', poles: '104', podiums: '197', fastestLaps: '67', firstSeason: '2007',
    ),

    // ── MERCEDES ─────────────────────────────────────────────────────────────
    F1Driver(
      code: 'RUS', name: 'George Russell', number: '63',
      team: 'Mercedes', teamColor: '#27F4D2',
      nationality: '🇬🇧 British',
      bio: 'Bookies\' favourite heading into 2026. Russell is the complete package — relentlessly fast in qualifying, increasingly dangerous in races, and technically brilliant with a new car. With Antonelli pushing him hard and Mercedes believed to have nailed the new regulations, this could finally be George\'s title year.',
      championships: '0', wins: '3', poles: '7', podiums: '24', fastestLaps: '9', firstSeason: '2019',
    ),
    F1Driver(
      code: 'ANT', name: 'Kimi Antonelli', number: '12',
      team: 'Mercedes', teamColor: '#27F4D2',
      nationality: '🇮🇹 Italian',
      bio: 'The most exciting young talent since Max Verstappen. Antonelli\'s 2025 rookie season exceeded all expectations — three podiums, pole positions, and a driving style that draws inevitable comparisons to a young Ayrton Senna. His bond with the Tifosi-adjacent Italian fans is electric. In 2026, year two, the pressure is on to convert pace into wins.',
      championships: '0', wins: '0', poles: '2', podiums: '3', fastestLaps: '1', firstSeason: '2025',
    ),

    // ── RED BULL RACING ───────────────────────────────────────────────────────
    F1Driver(
      code: 'VER', name: 'Max Verstappen', number: '1',
      team: 'Red Bull Racing', teamColor: '#3671C6',
      nationality: '🇳🇱 Dutch',
      bio: 'Four-time World Champion and arguably the greatest driver of his generation. Verstappen\'s Red Bull dominance was checked in 2025 but he remains the single most dangerous driver on the grid when the car suits him. Locked into Red Bull until 2028, he faces his biggest challenge yet in the new 2026 regulations cycle.',
      championships: '4', wins: '63', poles: '41', podiums: '112', fastestLaps: '31', firstSeason: '2015',
    ),
    F1Driver(
      code: 'HAD', name: 'Isack Hadjar', number: '6',
      team: 'Red Bull Racing', teamColor: '#3671C6',
      nationality: '🇫🇷 French-Algerian',
      bio: 'Red Bull\'s next great hope steps up to the senior team after an electric rookie season at Racing Bulls. Hadjar dominated F2 in 2024 with a maturity that belied his age and immediately impressed in his first F1 campaign. Partnering Verstappen is the ultimate sink-or-swim test — Red Bull believe he is ready.',
      championships: '0', wins: '0', poles: '1', podiums: '2', fastestLaps: '1', firstSeason: '2025',
    ),

    // ── WILLIAMS ─────────────────────────────────────────────────────────────
    F1Driver(
      code: 'SAI', name: 'Carlos Sainz', number: '55',
      team: 'Williams', teamColor: '#64C4FF',
      nationality: '🇪🇸 Spanish',
      bio: 'One of the most complete drivers on the grid, Sainz joined Williams on a mission to drag the historic team back to the front. He won in Australia 2024 days after an appendix operation — a moment that defined his extraordinary determination. With Williams now competitive, Sainz could be a dark horse for points every race weekend.',
      championships: '0', wins: '4', poles: '5', podiums: '24', fastestLaps: '5', firstSeason: '2015',
    ),
    F1Driver(
      code: 'ALB', name: 'Alexander Albon', number: '23',
      team: 'Williams', teamColor: '#64C4FF',
      nationality: '🇹🇭 Thai-British',
      bio: 'The comeback king entering his fifth consecutive season with Williams. Albon has been the bedrock of Williams\' revival, consistently extracting points from machinery that shouldn\'t deliver them. His technical feedback and team-building instincts are as valuable as his lap times. A pillar of the paddock.',
      championships: '0', wins: '0', poles: '0', podiums: '2', fastestLaps: '0', firstSeason: '2019',
    ),

    // ── ASTON MARTIN-HONDA ────────────────────────────────────────────────────
    F1Driver(
      code: 'ALO', name: 'Fernando Alonso', number: '14',
      team: 'Aston Martin', teamColor: '#229971',
      nationality: '🇪🇸 Spanish',
      bio: 'At 44, the greatest active driver in the sport enters what may be his final season with renewed hope. Adrian Newey has arrived, Honda power is new, and the regulations have reset. If ever there was a moment for Alonso to chase a third championship, this is it. El Plan has never been more alive. 24 seasons in Formula 1 — still the standard.',
      championships: '2', wins: '32', poles: '22', podiums: '106', fastestLaps: '23', firstSeason: '2001',
    ),
    F1Driver(
      code: 'STR', name: 'Lance Stroll', number: '18',
      team: 'Aston Martin', teamColor: '#229971',
      nationality: '🇨🇦 Canadian',
      bio: 'Entering his 10th F1 season and eighth with Aston Martin, Stroll has grown significantly as a driver under Alonso\'s shadow. His performances on street circuits can be stunning — his pole in Baku remains a reminder of his ceiling. With Newey\'s car underneath him in 2026, Stroll could have his best season yet.',
      championships: '0', wins: '0', poles: '1', podiums: '3', fastestLaps: '0', firstSeason: '2017',
    ),

    // ── ALPINE-RENAULT ────────────────────────────────────────────────────────
    F1Driver(
      code: 'GAS', name: 'Pierre Gasly', number: '10',
      team: 'Alpine', teamColor: '#FF87BC',
      nationality: '🇫🇷 French',
      bio: 'Alpine\'s undisputed team leader and France\'s greatest active F1 hope. Gasly\'s journey from being dropped by Red Bull to winning at Monza 2020 is one of the most remarkable in modern F1. His long-term commitment provides Alpine the stability they desperately need as they navigate the new technical era with Briatore at the helm.',
      championships: '0', wins: '1', poles: '0', podiums: '4', fastestLaps: '3', firstSeason: '2017',
    ),
    F1Driver(
      code: 'COL', name: 'Franco Colapinto', number: '43',
      team: 'Alpine', teamColor: '#FF87BC',
      nationality: '🇦🇷 Argentine',
      bio: 'Argentina\'s first F1 driver in decades, Colapinto burst onto the scene as a Williams substitute in 2024 and showed spectacular pace. He beat out Paul Aron for the Alpine seat in a fierce battle and now has a full season to show the world what he can do. Passionate, raw, and fearless — South America has a new hero.',
      championships: '0', wins: '0', poles: '0', podiums: '0', fastestLaps: '0', firstSeason: '2024',
    ),

    // ── HAAS-FERRARI ─────────────────────────────────────────────────────────
    F1Driver(
      code: 'BEA', name: 'Oliver Bearman', number: '87',
      team: 'Haas', teamColor: '#B6BABD',
      nationality: '🇬🇧 British',
      bio: 'Britain\'s next superstar entering his sophomore season after a stunning debut year. Bearman first turned heads with a points finish as a Ferrari substitute in Saudi 2024 — aged 18 with zero preparation. His full 2025 campaign proved that was no fluke. Cool-headed, technically gifted, and already on Ferrari\'s radar for a future seat.',
      championships: '0', wins: '0', poles: '0', podiums: '0', fastestLaps: '0', firstSeason: '2025',
    ),
    F1Driver(
      code: 'OCO', name: 'Esteban Ocon', number: '31',
      team: 'Haas', teamColor: '#B6BABD',
      nationality: '🇫🇷 French',
      bio: 'The 2021 Hungarian GP winner enters his second season at Haas with experience and fight. Ocon has spent his entire career battling in the midfield with everything he has and brings crucial knowledge of the technical regulations to a team that is growing. On his day, he is capable of results that embarrass much bigger operations.',
      championships: '0', wins: '1', poles: '0', podiums: '3', fastestLaps: '2', firstSeason: '2016',
    ),

    // ── RACING BULLS (RB) ─────────────────────────────────────────────────────
    F1Driver(
      code: 'LAW', name: 'Liam Lawson', number: '30',
      team: 'Racing Bulls', teamColor: '#6692FF',
      nationality: '🇳🇿 New Zealander',
      bio: 'New Zealand\'s finest current motorsport export, Lawson rebuilt his reputation brilliantly after his difficult Red Bull stint in early 2025. Racing Bulls is now his home base and he enters 2026 as the team\'s undisputed lead driver. Technical, precise, and physically imposing — the Kiwi racer has enormous potential still to unlock.',
      championships: '0', wins: '0', poles: '0', podiums: '0', fastestLaps: '0', firstSeason: '2024',
    ),
    F1Driver(
      code: 'LIN', name: 'Arvid Lindblad', number: '8',
      team: 'Racing Bulls', teamColor: '#6692FF',
      nationality: '🇬🇧 British-Swedish',
      bio: 'The only true rookie on the 2026 grid and Red Bull\'s most prized junior talent. Lindblad dominated the junior categories with a calmness and intelligence that the Red Bull academy rarely sees. At 18 years old he steps into F1 knowing the path to the senior Red Bull seat runs directly through his performances against Lawson.',
      championships: '0', wins: '0', poles: '0', podiums: '0', fastestLaps: '0', firstSeason: '2026',
    ),

    // ── AUDI (formerly Kick Sauber) ───────────────────────────────────────────
    F1Driver(
      code: 'HUL', name: 'Nico Hülkenberg', number: '27',
      team: 'Audi', teamColor: '#C0D800',
      nationality: '🇩🇪 German',
      bio: 'The man who holds the record for most F1 starts without a podium — and refuses to let that define him. Hülkenberg is the cornerstone of Audi\'s F1 project, providing the precise technical feedback a new manufacturer desperately needs. At 38 he is entering his third decade in F1 and leads Germany\'s greatest motorsport return since Mercedes in 2010.',
      championships: '0', wins: '0', poles: '1', podiums: '0', fastestLaps: '9', firstSeason: '2010',
    ),
    F1Driver(
      code: 'BOR', name: 'Gabriel Bortoleto', number: '5',
      team: 'Audi', teamColor: '#C0D800',
      nationality: '🇧🇷 Brazilian',
      bio: 'Brazil\'s newest F1 star and 2024 F2 champion. Bortoleto is a McLaren junior talent who earned his Audi seat with dominant, mature performances throughout the feeder series. He arrived in 2025 as one of the most complete rookies in years and enters 2026 as a key part of Audi\'s multi-year plan to reach the front of the grid.',
      championships: '0', wins: '0', poles: '1', podiums: '2', fastestLaps: '0', firstSeason: '2025',
    ),

    // ── CADILLAC (NEW TEAM) ───────────────────────────────────────────────────
    F1Driver(
      code: 'PER', name: 'Sergio Pérez', number: '11',
      team: 'Cadillac', teamColor: '#960000',
      nationality: '🇲🇽 Mexican',
      bio: 'Mexico\'s greatest racing hero returns to F1 after a year away. Dropped by Red Bull at the end of 2024, Pérez refused to walk away from the sport and accepted the Cadillac challenge with both hands. His race-management skills, tyre expertise, and 260+ race starts make him the perfect anchor for F1\'s boldest new project. Checo is back.',
      championships: '0', wins: '6', poles: '3', podiums: '35', fastestLaps: '10', firstSeason: '2011',
    ),
    F1Driver(
      code: 'BOT', name: 'Valtteri Bottas', number: '77',
      team: 'Cadillac', teamColor: '#960000',
      nationality: '🇫🇮 Finnish',
      bio: 'After a difficult final season at Kick Sauber, Bottas seized his second chance with the new Cadillac team. With over 220 race starts and the experience of fighting for world championships at Mercedes, he is the ideal co-pilot for an operation finding its feet. Calm, meticulous, and underrated — Bottas remains one of the cleanest racers on the grid.',
      championships: '0', wins: '10', poles: '20', podiums: '67', fastestLaps: '19', firstSeason: '2013',
    ),
  ];

  // ── Get driver by code ─────────────────────────────────────────────────────
  static F1Driver? getDriver(String code) {
    try {
      return drivers.firstWhere((d) => d.code == code);
    } catch (_) {
      return null;
    }
  }

  // ── Get drivers by team ────────────────────────────────────────────────────
  static List<F1Driver> getTeamDrivers(String team) {
    return drivers.where((d) => d.team == team).toList();
  }

  // ── All unique teams ───────────────────────────────────────────────────────
  static List<String> get teams => drivers.map((d) => d.team).toSet().toList();

  // ── Fetch current/next race from Ergast API ────────────────────────────────
  Future<F1Race?> getCurrentOrNextRace() async {
    try {
      final response = await http.get(
        Uri.parse('https://ergast.com/api/f1/current/next.json'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final races = data['MRData']['RaceTable']['Races'] as List;
        if (races.isEmpty) return _fallbackRace();

        final race = races.first;
        final dateStr = race['date'] as String;
        final timeStr = (race['time'] as String?)?.replaceAll('Z', '') ?? '13:00:00';
        final raceDate = DateTime.parse('${dateStr}T$timeStr').toLocal();
        final now = DateTime.now();

        final isLive = now.isAfter(raceDate) &&
            now.isBefore(raceDate.add(const Duration(hours: 3)));
        final isUpcoming = raceDate.isAfter(now);

        return F1Race(
          raceName: race['raceName'] ?? 'Grand Prix',
          circuit: race['Circuit']['circuitName'] ?? '',
          country: race['Circuit']['Location']['country'] ?? '',
          raceDate: raceDate,
          isLive: isLive,
          isUpcoming: isUpcoming,
          totalLaps: 70,
        );
      }
    } catch (_) {}
    return _fallbackRace();
  }

  F1Race _fallbackRace() => F1Race(
    raceName: 'Australian Grand Prix',
    circuit: 'Albert Park Circuit',
    country: 'Australia',
    raceDate: DateTime(2026, 3, 15, 15, 0),
    isLive: false,
    isUpcoming: true,
  );
}