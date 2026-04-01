//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateSharingPermissionsDto {
  /// Returns a new [UpdateSharingPermissionsDto] instance.
  UpdateSharingPermissionsDto({
    this.permissions = const [],
  });

  List<SharingPermission> permissions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateSharingPermissionsDto &&
    _deepEquality.equals(other.permissions, permissions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (permissions.hashCode);

  @override
  String toString() => 'UpdateSharingPermissionsDto[permissions=$permissions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'permissions'] = this.permissions;
    return json;
  }

  /// Returns a new [UpdateSharingPermissionsDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateSharingPermissionsDto? fromJson(dynamic value) {
    upgradeDto(value, "UpdateSharingPermissionsDto");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return UpdateSharingPermissionsDto(
        permissions: SharingPermission.listFromJson(json[r'permissions']),
      );
    }
    return null;
  }

  static List<UpdateSharingPermissionsDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateSharingPermissionsDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateSharingPermissionsDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateSharingPermissionsDto> mapFromJson(dynamic json) {
    final map = <String, UpdateSharingPermissionsDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateSharingPermissionsDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateSharingPermissionsDto-objects as value to a dart map
  static Map<String, List<UpdateSharingPermissionsDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateSharingPermissionsDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateSharingPermissionsDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'permissions',
  };
}

