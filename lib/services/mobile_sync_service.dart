import 'dart:convert';

import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/simulation_day.dart';
import 'package:calwatt/services/api_client.dart';
import 'package:calwatt/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class MobileSyncService {
  MobileSyncService(this._api);

  static const _uuid = Uuid();
  final CalWattApiClient _api;
  String? lastError;
  bool isOnline = false;
  bool sessionExpired = false;
  int pendingChangesCount = 0;

  Future<void> queueAppliance(Appliance appliance) async {
    final queue = await _readQueue();
    queue.removeWhere(
      (item) =>
          item['type'] == 'appliance-delete' &&
          item['entityId'] == appliance.id,
    );
    queue.removeWhere(
      (item) =>
          item['type'] == 'appliance-upsert' &&
          item['entityId'] == appliance.id,
    );
    queue.add({
      'opId': _uuid.v4(),
      'type': 'appliance-upsert',
      'entityId': appliance.id,
      'payload': _serverAppliance(appliance),
    });
    await _writeQueue(queue);
    pendingChangesCount = queue.length;
  }

  Future<void> queueApplianceDelete(String id) async {
    final queue = await _readQueue();
    queue.removeWhere(
      (item) => item['type'] == 'appliance-upsert' && item['entityId'] == id,
    );
    if (int.tryParse(id) == null) {
      await _writeQueue(queue);
      pendingChangesCount = queue.length;
      return;
    }
    queue.removeWhere(
      (item) => item['type'] == 'appliance-delete' && item['entityId'] == id,
    );
    queue.add({'opId': _uuid.v4(), 'type': 'appliance-delete', 'entityId': id});
    await _writeQueue(queue);
    pendingChangesCount = queue.length;
  }

  Future<void> queueSimulationDay(SimDay day) async {
    final queue = await _readQueue();
    queue.removeWhere(
      (item) =>
          item['type'] == 'simulation-delete' &&
          item['entityId'] == day.day,
    );
    queue.removeWhere(
      (item) =>
          item['type'] == 'simulation-upsert' && item['entityId'] == day.day,
    );
    queue.add({
      'opId': _uuid.v4(),
      'type': 'simulation-upsert',
      'entityId': day.day,
      'payload': day.usages
          .map(
            (usage) => {
              'applianceId': usage.applianceId,
              'hours': usage.hours,
              'quantity': usage.quantity,
            },
          )
          .toList(),
    });
    await _writeQueue(queue);
    pendingChangesCount = queue.length;
  }

  Future<void> queueSimulationDelete(int day) async {
    final queue = await _readQueue();
    queue.removeWhere(
      (item) =>
          item['entityId'] == day &&
          (item['type'] == 'simulation-upsert' ||
              item['type'] == 'simulation-delete'),
    );
    queue.add({
      'opId': _uuid.v4(),
      'type': 'simulation-delete',
      'entityId': day,
    });
    await _writeQueue(queue);
    pendingChangesCount = queue.length;
  }

  Future<void> importLegacyData({
    required List<Appliance> appliances,
    required List<SimDay> days,
  }) async {
    try {
      final remote = (await _api.getAppliances())
          .map(Appliance.fromServerJson)
          .toList();
      final remoteByName = {
        for (final appliance in remote)
          appliance.name.trim().toLowerCase(): appliance,
      };
      final localToRemote = <String, String>{};
      final merged = [...remote];
      for (final local in appliances) {
        final existing = remoteByName[local.name.trim().toLowerCase()];
        if (existing == null) {
          merged.add(local);
          await queueAppliance(local);
          continue;
        }
        localToRemote[local.id] = existing.id;
        final imported = local.copyWith(id: existing.id);
        final index = merged.indexWhere((item) => item.id == existing.id);
        merged[index] = imported;
        if (jsonEncode(_serverAppliance(imported)) !=
            jsonEncode(_serverAppliance(existing))) {
          await queueAppliance(imported);
        }
      }
      final importedDays = days
          .map(
            (day) => day.copyWith(
              usages: day.usages
                  .map(
                    (usage) => usage.copyWith(
                      applianceId:
                          localToRemote[usage.applianceId] ?? usage.applianceId,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
      await StorageService.saveAppliances(merged);
      await StorageService.saveSimulationDays(importedDays);
      for (final day in importedDays) {
        await queueSimulationDay(day);
      }
    } on ApiConnectionException catch (error) {
      lastError = error.message;
      isOnline = false;
      await StorageService.saveAppliances(appliances);
      await StorageService.saveSimulationDays(days);
      for (final appliance in appliances) {
        await queueAppliance(appliance);
      }
      for (final day in days) {
        await queueSimulationDay(day);
      }
    }
  }

  Future<bool> synchronize() async {
    lastError = null;
    sessionExpired = false;
    try {
      await _flushQueue();
      final appliances = (await _api.getAppliances())
          .map(Appliance.fromServerJson)
          .toList();
      final days = (await _api.getSimulation())
          .map(_simulationFromServer)
          .toList();
      final dashboard = await _api.getDashboard();
      final history = await _api.getConsumptionHistory();
      await StorageService.saveAppliances(appliances);
      await StorageService.saveSimulationDays(days);
      final rate = (dashboard['rate'] as Map<String, dynamic>)['rate'] as num;
      await StorageService.setElectricityRate(rate.toDouble());
      await StorageService.saveConsumptionHistory(jsonEncode(history));
      isOnline = true;
      pendingChangesCount = (await _readQueue()).length;
      return true;
    } on ApiConnectionException catch (error) {
      lastError = error.message;
      isOnline = false;
      return false;
    } on ApiException catch (error) {
      lastError = error.message;
      sessionExpired = error.statusCode == 401;
      isOnline = error.statusCode != null &&
          error.statusCode! < 500 &&
          error.statusCode != 401;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadHistory() async {
    final cached = await StorageService.loadConsumptionHistory();
    if (!isOnline || cached == null) return _decodeHistory(cached);
    try {
      final records = await _api.getConsumptionHistory();
      await StorageService.saveConsumptionHistory(jsonEncode(records));
      return records;
    } on ApiConnectionException catch (error) {
      lastError = error.message;
      isOnline = false;
      return _decodeHistory(cached);
    } on ApiException catch (error) {
      lastError = error.message;
      return _decodeHistory(cached);
    }
  }

  Future<void> _flushQueue() async {
    const order = [
      'appliance-upsert',
      'simulation-upsert',
      'simulation-delete',
      'appliance-delete',
    ];
    while (true) {
      var processed = false;
      for (final type in order) {
        while (true) {
          final queue = await _readQueue();
          final pending = queue.where((item) => item['type'] == type);
          if (pending.isEmpty) break;
          final operation = pending.first;
          await _apply(operation);
          final currentQueue = await _readQueue();
          currentQueue.removeWhere((item) => item['opId'] == operation['opId']);
          await _writeQueue(currentQueue);
          processed = true;
        }
      }
      if ((await _readQueue()).isEmpty || !processed) break;
    }
    pendingChangesCount = (await _readQueue()).length;
  }

  Future<void> _apply(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final id = operation['entityId'];
    if (type == 'appliance-upsert') {
      final idString = id.toString();
      final payload = Map<String, dynamic>.from(operation['payload'] as Map);
      if (int.tryParse(idString) == null) {
        final created = await _api.createAppliance(payload);
        await _remapApplianceId(idString, created['id'].toString());
      } else {
        await _api.updateAppliance(idString, payload);
      }
      return;
    }
    if (type == 'appliance-delete') {
      try {
        await _api.deleteAppliance(id.toString());
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
      }
      return;
    }
    if (type == 'simulation-upsert') {
      final usages = List<Map<String, dynamic>>.from(
        (operation['payload'] as List).map(
          (usage) => Map<String, dynamic>.from(usage as Map),
        ),
      );
      await _api.saveSimulationDay(
        id as int,
        usages
            .map(
              (usage) => {
                ...usage,
                'applianceId': int.parse(usage['applianceId'].toString()),
              },
            )
            .toList(),
      );
      return;
    }
    if (type == 'simulation-delete') {
      await _api.deleteSimulationDay(id as int);
      return;
    }
    throw ApiException('Unknown pending mobile change: $type.');
  }

  Future<void> _remapApplianceId(String oldId, String newId) async {
    final appliances = await StorageService.loadAppliances();
    await StorageService.saveAppliances(
      appliances
          .map((item) => item.id == oldId ? item.copyWith(id: newId) : item)
          .toList(),
    );
    final days = await StorageService.loadSimulationDays();
    final remappedDays = days
        .map(
          (day) => day.copyWith(
            usages: day.usages
                .map(
                  (usage) => usage.applianceId == oldId
                      ? usage.copyWith(applianceId: newId)
                      : usage,
                )
                .toList(),
          ),
        )
        .toList();
    await StorageService.saveSimulationDays(remappedDays);

    final queue = await _readQueue();
    for (final operation in queue.where(
      (item) => item['type'] == 'simulation-upsert',
    )) {
      final usages = (operation['payload'] as List).map((item) {
        final usage = Map<String, dynamic>.from(item as Map);
        if (usage['applianceId'] == oldId) usage['applianceId'] = newId;
        return usage;
      }).toList();
      operation['payload'] = usages;
    }
    await _writeQueue(queue);
  }

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final json = await StorageService.loadQueue();
    if (json == null || json.isEmpty) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(json) as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> queue) =>
      StorageService.saveQueue(jsonEncode(queue));

  List<Map<String, dynamic>> _decodeHistory(String? value) {
    if (value == null || value.isEmpty) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(value) as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Map<String, dynamic> _serverAppliance(Appliance appliance) => {
    'name': appliance.name,
    'category': appliance.category.name,
    'wattage': appliance.wattage,
    'dailyOperatingHours': appliance.dailyOperatingHours,
    'operatingDays': appliance.operatingDays,
    'isOn': appliance.isOn,
    'quantity': appliance.quantity,
  };

  SimDay _simulationFromServer(Map<String, dynamic> value) => SimDay(
    day: value['day'] as int,
    usages: (value['usages'] as List).map((item) {
      final usage = Map<String, dynamic>.from(item as Map);
      return SimApplianceUsage(
        applianceId: usage['applianceId'].toString(),
        hours: (usage['hours'] as num).toDouble(),
        quantity: (usage['quantity'] as num).toInt(),
      );
    }).toList(),
  );
}
