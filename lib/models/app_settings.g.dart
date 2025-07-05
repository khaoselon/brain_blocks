// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 0;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      soundEnabled: fields[0] as bool? ?? true,
      hapticsEnabled: fields[1] as bool? ?? true,
      colorBlindFriendly: fields[2] as bool? ?? false,
      defaultDifficulty: fields[3] as String? ?? 'easy',
      adFree: fields[4] as bool? ?? false,
      personalizedAds: fields[5] as bool? ?? true,
      themeMode: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.soundEnabled)
      ..writeByte(1)
      ..write(obj.hapticsEnabled)
      ..writeByte(2)
      ..write(obj.colorBlindFriendly)
      ..writeByte(3)
      ..write(obj.defaultDifficulty)
      ..writeByte(4)
      ..write(obj.adFree)
      ..writeByte(5)
      ..write(obj.personalizedAds)
      ..writeByte(6)
      ..write(obj.themeMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
