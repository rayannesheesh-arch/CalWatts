import 'package:flutter/material.dart';

/// Enum representing all supported appliance categories across household,
/// commercial, IT, industrial, and warehouse environments.
enum ApplianceCategory {
  // Household
  fan,
  airConditioner,
  refrigerator,
  television,
  washingMachine,
  microwave,
  riceCooker,
  electricKettle,
  waterDispenser,
  light,
  electricIron,

  // Computers & IT
  desktopComputer,
  laptop,
  computerMonitor,
  gamingPc,
  server,
  serverRack,
  networkSwitch,
  router,
  modem,
  ups,
  nasStorage,
  printer,
  cctvSystem,

  // Warehouse & Industrial
  industrialFan,
  ventilationSystem,
  industrialAirConditioner,
  conveyorBelt,
  electricMotor,
  industrialPump,
  waterPump,
  weldingMachine,
  forkLiftCharger,
  industrialLighting,
  compressor,
  factoryMachinery,

  // Commercial & Business
  posTerminal,
  cashRegister,
  commercialRefrigerator,
  commercialFreezer,
  officePrinter,
  photocopier,
  projector,
  officeWorkstation,
  securitySystem,
  elevator,
  commercialLighting;

  String toJson() => name;

  static ApplianceCategory fromJson(String json) =>
      ApplianceCategory.values.firstWhere(
        (e) => e.name == json,
        orElse: () => ApplianceCategory.fan,
      );

  String get label {
    switch (this) {
      case ApplianceCategory.fan: return 'Electric Fan';
      case ApplianceCategory.airConditioner: return 'Air Conditioner';
      case ApplianceCategory.refrigerator: return 'Refrigerator';
      case ApplianceCategory.television: return 'Television';
      case ApplianceCategory.washingMachine: return 'Washing Machine';
      case ApplianceCategory.microwave: return 'Microwave';
      case ApplianceCategory.riceCooker: return 'Rice Cooker';
      case ApplianceCategory.electricKettle: return 'Electric Kettle';
      case ApplianceCategory.waterDispenser: return 'Water Dispenser';
      case ApplianceCategory.light: return 'Lighting';
      case ApplianceCategory.electricIron: return 'Electric Iron';
      case ApplianceCategory.desktopComputer: return 'Desktop Computer';
      case ApplianceCategory.laptop: return 'Laptop';
      case ApplianceCategory.computerMonitor: return 'Computer Monitor';
      case ApplianceCategory.gamingPc: return 'Gaming PC';
      case ApplianceCategory.server: return 'Server';
      case ApplianceCategory.serverRack: return 'Server Rack';
      case ApplianceCategory.networkSwitch: return 'Network Switch';
      case ApplianceCategory.router: return 'Router';
      case ApplianceCategory.modem: return 'Modem';
      case ApplianceCategory.ups: return 'UPS';
      case ApplianceCategory.nasStorage: return 'NAS / Storage';
      case ApplianceCategory.printer: return 'Printer';
      case ApplianceCategory.cctvSystem: return 'CCTV System';
      case ApplianceCategory.industrialFan: return 'Industrial Fan';
      case ApplianceCategory.ventilationSystem: return 'Ventilation System';
      case ApplianceCategory.industrialAirConditioner: return 'Industrial AC';
      case ApplianceCategory.conveyorBelt: return 'Conveyor Belt';
      case ApplianceCategory.electricMotor: return 'Electric Motor';
      case ApplianceCategory.industrialPump: return 'Industrial Pump';
      case ApplianceCategory.waterPump: return 'Water Pump';
      case ApplianceCategory.weldingMachine: return 'Welding Machine';
      case ApplianceCategory.forkLiftCharger: return 'Forklift Charger';
      case ApplianceCategory.industrialLighting: return 'Industrial Lighting';
      case ApplianceCategory.compressor: return 'Compressor';
      case ApplianceCategory.factoryMachinery: return 'Factory Machinery';
      case ApplianceCategory.posTerminal: return 'POS Terminal';
      case ApplianceCategory.cashRegister: return 'Cash Register';
      case ApplianceCategory.commercialRefrigerator: return 'Commercial Refrigerator';
      case ApplianceCategory.commercialFreezer: return 'Commercial Freezer';
      case ApplianceCategory.officePrinter: return 'Office Printer';
      case ApplianceCategory.photocopier: return 'Photocopier';
      case ApplianceCategory.projector: return 'Projector';
      case ApplianceCategory.officeWorkstation: return 'Office Workstation';
      case ApplianceCategory.securitySystem: return 'Security System';
      case ApplianceCategory.elevator: return 'Elevator';
      case ApplianceCategory.commercialLighting: return 'Commercial Lighting';
    }
  }

  IconData get icon {
    switch (this) {
      case ApplianceCategory.fan: return Icons.air;
      case ApplianceCategory.airConditioner: return Icons.ac_unit;
      case ApplianceCategory.refrigerator: return Icons.kitchen;
      case ApplianceCategory.television: return Icons.tv;
      case ApplianceCategory.washingMachine: return Icons.local_laundry_service;
      case ApplianceCategory.microwave: return Icons.microwave;
      case ApplianceCategory.riceCooker: return Icons.rice_bowl;
      case ApplianceCategory.electricKettle: return Icons.coffee_maker;
      case ApplianceCategory.waterDispenser: return Icons.water_drop;
      case ApplianceCategory.light: return Icons.lightbulb;
      case ApplianceCategory.electricIron: return Icons.iron;
      case ApplianceCategory.desktopComputer: return Icons.computer;
      case ApplianceCategory.laptop: return Icons.laptop;
      case ApplianceCategory.computerMonitor: return Icons.monitor;
      case ApplianceCategory.gamingPc: return Icons.sports_esports;
      case ApplianceCategory.server: return Icons.dns;
      case ApplianceCategory.serverRack: return Icons.storage;
      case ApplianceCategory.networkSwitch: return Icons.device_hub;
      case ApplianceCategory.router: return Icons.router;
      case ApplianceCategory.modem: return Icons.settings_input_antenna;
      case ApplianceCategory.ups: return Icons.battery_charging_full;
      case ApplianceCategory.nasStorage: return Icons.save;
      case ApplianceCategory.printer: return Icons.print;
      case ApplianceCategory.cctvSystem: return Icons.videocam;
      case ApplianceCategory.industrialFan: return Icons.wind_power;
      case ApplianceCategory.ventilationSystem: return Icons.hvac;
      case ApplianceCategory.industrialAirConditioner: return Icons.ac_unit;
      case ApplianceCategory.conveyorBelt: return Icons.linear_scale;
      case ApplianceCategory.electricMotor: return Icons.settings;
      case ApplianceCategory.industrialPump: return Icons.water;
      case ApplianceCategory.waterPump: return Icons.opacity;
      case ApplianceCategory.weldingMachine: return Icons.construction;
      case ApplianceCategory.forkLiftCharger: return Icons.electric_car;
      case ApplianceCategory.industrialLighting: return Icons.highlight;
      case ApplianceCategory.compressor: return Icons.compress;
      case ApplianceCategory.factoryMachinery: return Icons.precision_manufacturing;
      case ApplianceCategory.posTerminal: return Icons.point_of_sale;
      case ApplianceCategory.cashRegister: return Icons.local_atm;
      case ApplianceCategory.commercialRefrigerator: return Icons.kitchen;
      case ApplianceCategory.commercialFreezer: return Icons.ac_unit;
      case ApplianceCategory.officePrinter: return Icons.print;
      case ApplianceCategory.photocopier: return Icons.copy;
      case ApplianceCategory.projector: return Icons.videocam;
      case ApplianceCategory.officeWorkstation: return Icons.desktop_windows;
      case ApplianceCategory.securitySystem: return Icons.security;
      case ApplianceCategory.elevator: return Icons.elevator;
      case ApplianceCategory.commercialLighting: return Icons.wb_incandescent;
    }
  }

  String get groupLabel {
    switch (this) {
      case ApplianceCategory.fan:
      case ApplianceCategory.airConditioner:
      case ApplianceCategory.refrigerator:
      case ApplianceCategory.television:
      case ApplianceCategory.washingMachine:
      case ApplianceCategory.microwave:
      case ApplianceCategory.riceCooker:
      case ApplianceCategory.electricKettle:
      case ApplianceCategory.waterDispenser:
      case ApplianceCategory.light:
      case ApplianceCategory.electricIron:
        return 'Household';
      case ApplianceCategory.desktopComputer:
      case ApplianceCategory.laptop:
      case ApplianceCategory.computerMonitor:
      case ApplianceCategory.gamingPc:
      case ApplianceCategory.server:
      case ApplianceCategory.serverRack:
      case ApplianceCategory.networkSwitch:
      case ApplianceCategory.router:
      case ApplianceCategory.modem:
      case ApplianceCategory.ups:
      case ApplianceCategory.nasStorage:
      case ApplianceCategory.printer:
      case ApplianceCategory.cctvSystem:
        return 'Computers & IT';
      case ApplianceCategory.industrialFan:
      case ApplianceCategory.ventilationSystem:
      case ApplianceCategory.industrialAirConditioner:
      case ApplianceCategory.conveyorBelt:
      case ApplianceCategory.electricMotor:
      case ApplianceCategory.industrialPump:
      case ApplianceCategory.waterPump:
      case ApplianceCategory.weldingMachine:
      case ApplianceCategory.forkLiftCharger:
      case ApplianceCategory.industrialLighting:
      case ApplianceCategory.compressor:
      case ApplianceCategory.factoryMachinery:
        return 'Warehouse & Industrial';
      case ApplianceCategory.posTerminal:
      case ApplianceCategory.cashRegister:
      case ApplianceCategory.commercialRefrigerator:
      case ApplianceCategory.commercialFreezer:
      case ApplianceCategory.officePrinter:
      case ApplianceCategory.photocopier:
      case ApplianceCategory.projector:
      case ApplianceCategory.officeWorkstation:
      case ApplianceCategory.securitySystem:
      case ApplianceCategory.elevator:
      case ApplianceCategory.commercialLighting:
        return 'Commercial & Business';
    }
  }
}
