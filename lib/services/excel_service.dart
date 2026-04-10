import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/player_stats.dart';
import '../models/game.dart';

/// Résultat d'un import Excel
class ImportResult {
  final List<Map<String, dynamic>> teams; // {team, players}
  final List<String> errors;
  final int teamCount;
  final int playerCount;

  const ImportResult({
    required this.teams,
    required this.errors,
    required this.teamCount,
    required this.playerCount,
  });
}

class ExcelService {
  // ── Couleurs disponibles ──────────────────────────────────────────────────
  static const _colorMap = {
    'bleu': '#2196F3',
    'rouge': '#F44336',
    'vert': '#4CAF50',
    'orange': '#FF9800',
    'violet': '#9C27B0',
    'noir': '#212121',
    'marine': '#1B2A3B',
    'or': '#FFC107',
  };

  // ══════════════════════════════════════════════════════════════════════════
  // IMPORT
  // ══════════════════════════════════════════════════════════════════════════

  /// Génère et partage un fichier modèle Excel prérempli.
  static Future<void> downloadTemplate() async {
    final excel = Excel.createExcel();

    // ── Feuille Équipes ──────────────────────────────────────────────────
    final teamSheet = excel['Équipes'];
    excel.setDefaultSheet('Équipes');

    // En-têtes
    teamSheet.appendRow([
      TextCellValue('Ville (facultatif)'),
      TextCellValue('Nom équipe'),
      TextCellValue('Couleur (bleu/rouge/vert/orange/violet/noir/marine/or)'),
    ]);
    _boldRow(teamSheet, 0);

    // Exemples
    teamSheet.appendRow([
      TextCellValue('Montréal'),
      TextCellValue('Royaux'),
      TextCellValue('bleu'),
    ]);
    teamSheet.appendRow([
      TextCellValue('Québec'),
      TextCellValue('Capitales'),
      TextCellValue('rouge'),
    ]);
    teamSheet.appendRow([
      TextCellValue(''),
      TextCellValue('Tigres'),
      TextCellValue('orange'),
    ]);

    // ── Feuille Joueurs ──────────────────────────────────────────────────
    final playerSheet = excel['Joueurs'];

    playerSheet.appendRow([
      TextCellValue('Ville équipe (facultatif)'),
      TextCellValue('Nom équipe'),
      TextCellValue('Numéro'),
      TextCellValue('Nom du joueur'),
      TextCellValue('Position (facultatif — P/C/1B/2B/3B/SS/LF/CF/RF/DH/UT)'),
    ]);
    _boldRow(playerSheet, 0);

    // Exemples
    playerSheet.appendRow([
      TextCellValue('Montréal'),
      TextCellValue('Royaux'),
      IntCellValue(14),
      TextCellValue('Jean Tremblay'),
      TextCellValue('1B'),
    ]);
    playerSheet.appendRow([
      TextCellValue('Montréal'),
      TextCellValue('Royaux'),
      IntCellValue(22),
      TextCellValue('Marc Gagnon'),
      TextCellValue('P'),
    ]);
    playerSheet.appendRow([
      TextCellValue('Québec'),
      TextCellValue('Capitales'),
      IntCellValue(7),
      TextCellValue('Pierre Lavoie'),
      TextCellValue('SS'),
    ]);
    playerSheet.appendRow([
      TextCellValue(''),
      TextCellValue('Tigres'),
      IntCellValue(3),
      TextCellValue('Alex Côté'),
      TextCellValue(''),
    ]);

    await _shareExcel(excel, 'modele_equipes_baseball.xlsx');
  }

  /// Ouvre le sélecteur de fichier et importe les équipes/joueurs.
  static Future<ImportResult?> importTeams() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null) return null;

    final excel = Excel.decodeBytes(bytes);
    final errors = <String>[];
    final teamData = <String, Map<String, dynamic>>{};

    // ── Lire les équipes ─────────────────────────────────────────────────
    final teamSheet = excel.tables['Équipes'] ?? excel.tables['Equipes'];
    if (teamSheet == null) {
      errors.add('Feuille "Équipes" introuvable.');
    } else {
      for (int r = 1; r < teamSheet.rows.length; r++) {
        final row = teamSheet.rows[r];
        final city = _cellStr(row, 0);
        final name = _cellStr(row, 1);
        final colorName = _cellStr(row, 2).toLowerCase();

        if (name.isEmpty) continue;

        final colorHex = _colorMap[colorName] ?? '#2196F3';
        final key = '$city|$name';
        teamData[key] = {
          'city': city,
          'name': name,
          'color': colorHex,
          'players': <Map<String, dynamic>>[],
        };
      }
    }

    // ── Lire les joueurs ─────────────────────────────────────────────────
    final playerSheet = excel.tables['Joueurs'];
    if (playerSheet == null) {
      errors.add('Feuille "Joueurs" introuvable.');
    } else {
      for (int r = 1; r < playerSheet.rows.length; r++) {
        final row = playerSheet.rows[r];
        final city = _cellStr(row, 0);
        final teamName = _cellStr(row, 1);
        final numberStr = _cellStr(row, 2);
        final playerName = _cellStr(row, 3);
        final position = _cellStr(row, 4).toUpperCase();

        if (playerName.isEmpty) continue;

        final number = int.tryParse(numberStr) ?? 0;
        final key = '$city|$teamName';

        if (!teamData.containsKey(key)) {
          final label = city.isEmpty ? teamName : '$city $teamName';
          errors.add(
              'Ligne ${r + 1} (Joueurs) : équipe "$label" non trouvée dans la feuille Équipes.');
          continue;
        }

        final validPos = position.isEmpty || !Player.positions.contains(position)
            ? 'UT'
            : position;
        (teamData[key]!['players'] as List).add({
          'name': playerName,
          'number': number,
          'position': validPos,
        });
      }
    }

    int playerCount = 0;
    for (final t in teamData.values) {
      playerCount += (t['players'] as List).length;
    }

    return ImportResult(
      teams: teamData.values.toList(),
      errors: errors,
      teamCount: teamData.length,
      playerCount: playerCount,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPORT
  // ══════════════════════════════════════════════════════════════════════════

  /// Génère et partage un fichier Excel contenant les statistiques complètes.
  static Future<void> exportStats({
    required List<TeamStats> teamStats,
    required List<PlayerStats> playerStats,
    required List<Game> games,
  }) async {
    final excel = Excel.createExcel();
    excel.setDefaultSheet('Classement');

    // ── Feuille 1 : Classement ────────────────────────────────────────────
    final standingsSheet = excel['Classement'];
    standingsSheet.appendRow([
      TextCellValue('Équipe'),
      TextCellValue('PJ'),
      TextCellValue('V'),
      TextCellValue('D'),
      TextCellValue('N'),
      TextCellValue('PCT'),
      TextCellValue('R+'),
      TextCellValue('R-'),
      TextCellValue('Diff'),
      TextCellValue('CS'),
      TextCellValue('Err'),
      TextCellValue('HR'),
    ]);
    _boldRow(standingsSheet, 0);

    for (final t in teamStats) {
      standingsSheet.appendRow([
        TextCellValue(t.teamName),
        IntCellValue(t.gamesPlayed),
        IntCellValue(t.wins),
        IntCellValue(t.losses),
        IntCellValue(t.ties),
        TextCellValue(t.winPctDisplay),
        IntCellValue(t.runsScored),
        IntCellValue(t.runsAllowed),
        IntCellValue(t.runDifferential),
        IntCellValue(t.hits),
        IntCellValue(t.errors),
        IntCellValue(t.homeRuns),
      ]);
    }

    // ── Feuille 2 : Statistiques frappeurs ────────────────────────────────
    final battingSheet = excel['Frappeurs'];
    battingSheet.appendRow([
      TextCellValue('Joueur'),
      TextCellValue('Équipe'),
      TextCellValue('PJ'),
      TextCellValue('AB'),
      TextCellValue('CS'),
      TextCellValue('1B'),
      TextCellValue('2B'),
      TextCellValue('3B'),
      TextCellValue('HR'),
      TextCellValue('RBI'),
      TextCellValue('BB'),
      TextCellValue('K'),
      TextCellValue('HBP'),
      TextCellValue('SAC'),
      TextCellValue('R'),
      TextCellValue('AVG'),
      TextCellValue('OBP'),
      TextCellValue('SLG'),
      TextCellValue('OPS'),
    ]);
    _boldRow(battingSheet, 0);

    for (final p in playerStats) {
      battingSheet.appendRow([
        TextCellValue(p.playerName),
        TextCellValue(p.teamName),
        IntCellValue(p.games),
        IntCellValue(p.atBats),
        IntCellValue(p.hits),
        IntCellValue(p.singles),
        IntCellValue(p.doubles),
        IntCellValue(p.triples),
        IntCellValue(p.homeRuns),
        IntCellValue(p.rbi),
        IntCellValue(p.walks),
        IntCellValue(p.strikeouts),
        IntCellValue(p.hitByPitch),
        IntCellValue(p.sacrifices),
        IntCellValue(p.runs),
        TextCellValue(p.avgDisplay),
        TextCellValue(p.obpDisplay),
        TextCellValue(p.slgDisplay),
        TextCellValue(_fmt3(p.ops)),
      ]);
    }

    // ── Feuille 3 : Résultats des matchs ──────────────────────────────────
    final gamesSheet = excel['Matchs'];
    final inningHeaders = List.generate(9, (i) => TextCellValue('${i + 1}'));
    gamesSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Heure'),
      TextCellValue('Emplacement'),
      TextCellValue('Visiteurs'),
      TextCellValue('Locaux'),
      TextCellValue('Score Visit.'),
      TextCellValue('Score Loc.'),
      TextCellValue('CS Visit.'),
      TextCellValue('CS Loc.'),
      TextCellValue('Err Visit.'),
      TextCellValue('Err Loc.'),
      ...inningHeaders,
    ]);
    _boldRow(gamesSheet, 0);

    for (final g in games) {
      if (g.status != GameStatus.completed) continue;
      final inningAway = List.generate(9, (i) {
        final score = g.inningScore(i + 1);
        return score == null ? TextCellValue('-') : IntCellValue(score.awayRuns);
      });
      gamesSheet.appendRow([
        TextCellValue(
            '${g.gameDate.day}/${g.gameDate.month}/${g.gameDate.year}'),
        TextCellValue(
            '${g.gameDate.hour.toString().padLeft(2, '0')}:${g.gameDate.minute.toString().padLeft(2, '0')}'),
        TextCellValue(g.location),
        TextCellValue(g.awayTeamName),
        TextCellValue(g.homeTeamName),
        IntCellValue(g.awayScore),
        IntCellValue(g.homeScore),
        IntCellValue(g.awayHits),
        IntCellValue(g.homeHits),
        IntCellValue(g.awayErrors),
        IntCellValue(g.homeErrors),
        ...inningAway,
      ]);
    }

    await _shareExcel(excel, 'baseball_stats_${_dateTag()}.xlsx');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static String _cellStr(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final cell = row[index];
    if (cell == null) return '';
    final val = cell.value;
    if (val == null) return '';
    return val.toString().trim();
  }

  static void _boldRow(Sheet sheet, int rowIndex) {
    final row = sheet.rows[rowIndex];
    for (final cell in row) {
      if (cell == null) continue;
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  static String _fmt3(double v) =>
      '.${(v * 1000).round().toString().padLeft(3, '0')}';

  static String _dateTag() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _shareExcel(Excel excel, String filename) async {
    final bytes = excel.save();
    if (bytes == null) throw Exception('Impossible de générer le fichier Excel');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: filename,
    );
  }
}
