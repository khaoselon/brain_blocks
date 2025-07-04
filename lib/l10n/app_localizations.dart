// lib/l10n/app_localizations.dart - 修正版
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// アプリ名
  String get appName;

  /// ゲーム開始
  String get gameStart;

  /// 設定
  String get settings;

  /// ヘルプ
  String get help;

  /// 難易度
  String get difficulty;
  String get difficultyEasy;
  String get difficultyMedium;
  String get difficultyHard;

  /// ゲーム情報
  String get moves;
  String get time;
  String get hints;
  String get remaining;

  /// ボタン
  String get playAgain;
  String get backToMenu;
  String get reset;
  String get pause;
  String get resume;

  /// メッセージ
  String get congratulations;
  String get tryAgain;
  String get gameCompleted;
  String get gameFailed;

  /// 設定項目
  String get sound;
  String get haptics;
  String get colorBlindFriendly;
  String get theme;
  String get adFree;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'ja',
      'en',
      'ko',
      'zh',
      'es',
      'pt',
      'de',
      'it',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_getLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;

  AppLocalizations _getLocalizations(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return _AppLocalizationsJa();
      case 'en':
        return _AppLocalizationsEn();
      case 'ko':
        return _AppLocalizationsKo();
      case 'zh':
        return locale.countryCode == 'TW'
            ? _AppLocalizationsZhTw()
            : _AppLocalizationsZhCn();
      case 'es':
        return _AppLocalizationsEs();
      case 'pt':
        return _AppLocalizationsPt();
      case 'de':
        return _AppLocalizationsDe();
      case 'it':
        return _AppLocalizationsIt();
      default:
        return _AppLocalizationsJa(); // デフォルトは日本語
    }
  }
}

// 日本語 - constを削除
class _AppLocalizationsJa extends AppLocalizations {
  @override
  String get appName => 'ブレインブロックス';
  @override
  String get gameStart => 'ゲーム開始';
  @override
  String get settings => '設定';
  @override
  String get help => 'ヘルプ';
  @override
  String get difficulty => '難易度';
  @override
  String get difficultyEasy => '初級 (5×5)';
  @override
  String get difficultyMedium => '中級 (7×7)';
  @override
  String get difficultyHard => '上級 (10×10)';
  @override
  String get moves => '手数';
  @override
  String get time => '時間';
  @override
  String get hints => 'ヒント';
  @override
  String get remaining => '残り';
  @override
  String get playAgain => 'もう一度プレイ';
  @override
  String get backToMenu => 'メニューに戻る';
  @override
  String get reset => 'リセット';
  @override
  String get pause => '一時停止';
  @override
  String get resume => '再開';
  @override
  String get congratulations => 'おめでとうございます！';
  @override
  String get tryAgain => 'もう一度挑戦！';
  @override
  String get gameCompleted => 'ゲームクリア';
  @override
  String get gameFailed => 'ゲーム失敗';
  @override
  String get sound => 'サウンド';
  @override
  String get haptics => '触覚フィードバック';
  @override
  String get colorBlindFriendly => '色覚バリアフリー';
  @override
  String get theme => 'テーマ';
  @override
  String get adFree => '広告除去';
}

// 英語 - constを削除
class _AppLocalizationsEn extends AppLocalizations {
  @override
  String get appName => 'BrainBlocks';
  @override
  String get gameStart => 'Start Game';
  @override
  String get settings => 'Settings';
  @override
  String get help => 'Help';
  @override
  String get difficulty => 'Difficulty';
  @override
  String get difficultyEasy => 'Easy (5×5)';
  @override
  String get difficultyMedium => 'Medium (7×7)';
  @override
  String get difficultyHard => 'Hard (10×10)';
  @override
  String get moves => 'Moves';
  @override
  String get time => 'Time';
  @override
  String get hints => 'Hints';
  @override
  String get remaining => 'Remaining';
  @override
  String get playAgain => 'Play Again';
  @override
  String get backToMenu => 'Back to Menu';
  @override
  String get reset => 'Reset';
  @override
  String get pause => 'Pause';
  @override
  String get resume => 'Resume';
  @override
  String get congratulations => 'Congratulations!';
  @override
  String get tryAgain => 'Try Again!';
  @override
  String get gameCompleted => 'Game Completed';
  @override
  String get gameFailed => 'Game Failed';
  @override
  String get sound => 'Sound';
  @override
  String get haptics => 'Haptics';
  @override
  String get colorBlindFriendly => 'Color Blind Friendly';
  @override
  String get theme => 'Theme';
  @override
  String get adFree => 'Ad Free';
}

// 他の言語も同様にconstを削除（簡略化のため主要言語のみ表示）
class _AppLocalizationsKo extends AppLocalizations {
  @override
  String get appName => '브레인블럭스';
  @override
  String get gameStart => '게임 시작';
  @override
  String get settings => '설정';
  @override
  String get help => '도움말';
  @override
  String get difficulty => '난이도';
  @override
  String get difficultyEasy => '초급 (5×5)';
  @override
  String get difficultyMedium => '중급 (7×7)';
  @override
  String get difficultyHard => '고급 (10×10)';
  @override
  String get moves => '이동 횟수';
  @override
  String get time => '시간';
  @override
  String get hints => '힌트';
  @override
  String get remaining => '남은';
  @override
  String get playAgain => '다시 플레이';
  @override
  String get backToMenu => '메뉴로 돌아가기';
  @override
  String get reset => '리셋';
  @override
  String get pause => '일시정지';
  @override
  String get resume => '재개';
  @override
  String get congratulations => '축하합니다!';
  @override
  String get tryAgain => '다시 도전!';
  @override
  String get gameCompleted => '게임 완료';
  @override
  String get gameFailed => '게임 실패';
  @override
  String get sound => '사운드';
  @override
  String get haptics => '햅틱';
  @override
  String get colorBlindFriendly => '색맹 친화적';
  @override
  String get theme => '테마';
  @override
  String get adFree => '광고 제거';
}

// 繁体字中国語、簡体字中国語、その他の言語クラスも同様
class _AppLocalizationsZhTw extends AppLocalizations {
  @override
  String get appName => '腦力方塊';
  @override
  String get gameStart => '開始遊戲';
  @override
  String get settings => '設定';
  @override
  String get help => '說明';
  @override
  String get difficulty => '難度';
  @override
  String get difficultyEasy => '初級 (5×5)';
  @override
  String get difficultyMedium => '中級 (7×7)';
  @override
  String get difficultyHard => '高級 (10×10)';
  @override
  String get moves => '移動次數';
  @override
  String get time => '時間';
  @override
  String get hints => '提示';
  @override
  String get remaining => '剩餘';
  @override
  String get playAgain => '再玩一次';
  @override
  String get backToMenu => '返回選單';
  @override
  String get reset => '重置';
  @override
  String get pause => '暫停';
  @override
  String get resume => '繼續';
  @override
  String get congratulations => '恭喜！';
  @override
  String get tryAgain => '再試一次！';
  @override
  String get gameCompleted => '遊戲完成';
  @override
  String get gameFailed => '遊戲失敗';
  @override
  String get sound => '音效';
  @override
  String get haptics => '觸覺回饋';
  @override
  String get colorBlindFriendly => '色盲友善';
  @override
  String get theme => '主題';
  @override
  String get adFree => '移除廣告';
}

class _AppLocalizationsZhCn extends AppLocalizations {
  @override
  String get appName => '脑力方块';
  @override
  String get gameStart => '开始游戏';
  @override
  String get settings => '设置';
  @override
  String get help => '帮助';
  @override
  String get difficulty => '难度';
  @override
  String get difficultyEasy => '初级 (5×5)';
  @override
  String get difficultyMedium => '中级 (7×7)';
  @override
  String get difficultyHard => '高级 (10×10)';
  @override
  String get moves => '移动次数';
  @override
  String get time => '时间';
  @override
  String get hints => '提示';
  @override
  String get remaining => '剩余';
  @override
  String get playAgain => '再玩一次';
  @override
  String get backToMenu => '返回菜单';
  @override
  String get reset => '重置';
  @override
  String get pause => '暂停';
  @override
  String get resume => '继续';
  @override
  String get congratulations => '恭喜！';
  @override
  String get tryAgain => '再试一次！';
  @override
  String get gameCompleted => '游戏完成';
  @override
  String get gameFailed => '游戏失败';
  @override
  String get sound => '音效';
  @override
  String get haptics => '触觉反馈';
  @override
  String get colorBlindFriendly => '色盲友好';
  @override
  String get theme => '主题';
  @override
  String get adFree => '移除广告';
}

class _AppLocalizationsEs extends AppLocalizations {
  @override
  String get appName => 'BrainBlocks';
  @override
  String get gameStart => 'Iniciar Juego';
  @override
  String get settings => 'Configuración';
  @override
  String get help => 'Ayuda';
  @override
  String get difficulty => 'Dificultad';
  @override
  String get difficultyEasy => 'Fácil (5×5)';
  @override
  String get difficultyMedium => 'Medio (7×7)';
  @override
  String get difficultyHard => 'Difícil (10×10)';
  @override
  String get moves => 'Movimientos';
  @override
  String get time => 'Tiempo';
  @override
  String get hints => 'Pistas';
  @override
  String get remaining => 'Restante';
  @override
  String get playAgain => 'Jugar de Nuevo';
  @override
  String get backToMenu => 'Volver al Menú';
  @override
  String get reset => 'Reiniciar';
  @override
  String get pause => 'Pausa';
  @override
  String get resume => 'Reanudar';
  @override
  String get congratulations => '¡Felicidades!';
  @override
  String get tryAgain => '¡Inténtalo de Nuevo!';
  @override
  String get gameCompleted => 'Juego Completado';
  @override
  String get gameFailed => 'Juego Fallido';
  @override
  String get sound => 'Sonido';
  @override
  String get haptics => 'Hápticos';
  @override
  String get colorBlindFriendly => 'Amigable para Daltónicos';
  @override
  String get theme => 'Tema';
  @override
  String get adFree => 'Sin Anuncios';
}

class _AppLocalizationsPt extends AppLocalizations {
  @override
  String get appName => 'BrainBlocks';
  @override
  String get gameStart => 'Iniciar Jogo';
  @override
  String get settings => 'Configurações';
  @override
  String get help => 'Ajuda';
  @override
  String get difficulty => 'Dificuldade';
  @override
  String get difficultyEasy => 'Fácil (5×5)';
  @override
  String get difficultyMedium => 'Médio (7×7)';
  @override
  String get difficultyHard => 'Difícil (10×10)';
  @override
  String get moves => 'Movimentos';
  @override
  String get time => 'Tempo';
  @override
  String get hints => 'Dicas';
  @override
  String get remaining => 'Restante';
  @override
  String get playAgain => 'Jogar Novamente';
  @override
  String get backToMenu => 'Voltar ao Menu';
  @override
  String get reset => 'Reiniciar';
  @override
  String get pause => 'Pausar';
  @override
  String get resume => 'Retomar';
  @override
  String get congratulations => 'Parabéns!';
  @override
  String get tryAgain => 'Tente Novamente!';
  @override
  String get gameCompleted => 'Jogo Completado';
  @override
  String get gameFailed => 'Jogo Falhado';
  @override
  String get sound => 'Som';
  @override
  String get haptics => 'Tátil';
  @override
  String get colorBlindFriendly => 'Amigável para Daltônicos';
  @override
  String get theme => 'Tema';
  @override
  String get adFree => 'Sem Anúncios';
}

class _AppLocalizationsDe extends AppLocalizations {
  @override
  String get appName => 'BrainBlocks';
  @override
  String get gameStart => 'Spiel Starten';
  @override
  String get settings => 'Einstellungen';
  @override
  String get help => 'Hilfe';
  @override
  String get difficulty => 'Schwierigkeit';
  @override
  String get difficultyEasy => 'Einfach (5×5)';
  @override
  String get difficultyMedium => 'Mittel (7×7)';
  @override
  String get difficultyHard => 'Schwer (10×10)';
  @override
  String get moves => 'Züge';
  @override
  String get time => 'Zeit';
  @override
  String get hints => 'Hinweise';
  @override
  String get remaining => 'Verbleibend';
  @override
  String get playAgain => 'Erneut Spielen';
  @override
  String get backToMenu => 'Zurück zum Menü';
  @override
  String get reset => 'Zurücksetzen';
  @override
  String get pause => 'Pause';
  @override
  String get resume => 'Fortsetzen';
  @override
  String get congratulations => 'Glückwunsch!';
  @override
  String get tryAgain => 'Erneut Versuchen!';
  @override
  String get gameCompleted => 'Spiel Abgeschlossen';
  @override
  String get gameFailed => 'Spiel Gescheitert';
  @override
  String get sound => 'Ton';
  @override
  String get haptics => 'Haptik';
  @override
  String get colorBlindFriendly => 'Farbenblind-freundlich';
  @override
  String get theme => 'Design';
  @override
  String get adFree => 'Werbefrei';
}

class _AppLocalizationsIt extends AppLocalizations {
  @override
  String get appName => 'BrainBlocks';
  @override
  String get gameStart => 'Inizia Gioco';
  @override
  String get settings => 'Impostazioni';
  @override
  String get help => 'Aiuto';
  @override
  String get difficulty => 'Difficoltà';
  @override
  String get difficultyEasy => 'Facile (5×5)';
  @override
  String get difficultyMedium => 'Medio (7×7)';
  @override
  String get difficultyHard => 'Difficile (10×10)';
  @override
  String get moves => 'Mosse';
  @override
  String get time => 'Tempo';
  @override
  String get hints => 'Suggerimenti';
  @override
  String get remaining => 'Rimanente';
  @override
  String get playAgain => 'Gioca di Nuovo';
  @override
  String get backToMenu => 'Torna al Menu';
  @override
  String get reset => 'Ripristina';
  @override
  String get pause => 'Pausa';
  @override
  String get resume => 'Riprendi';
  @override
  String get congratulations => 'Congratulazioni!';
  @override
  String get tryAgain => 'Riprova!';
  @override
  String get gameCompleted => 'Gioco Completato';
  @override
  String get gameFailed => 'Gioco Fallito';
  @override
  String get sound => 'Suono';
  @override
  String get haptics => 'Aptica';
  @override
  String get colorBlindFriendly => 'Amico dei Daltonici';
  @override
  String get theme => 'Tema';
  @override
  String get adFree => 'Senza Pubblicità';
}
