import 'package:flutter/material.dart';
import 'package:neurostack/core/failures/domain_failure.dart';

sealed class ProgressState {
  const ProgressState();
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

class ProgressLoaded extends ProgressState {
  const ProgressLoaded({
    required this.rows,
    required this.weekRange,
    required this.todayIndex,
    required this.isOffline,
  });

  final List<ProtocolRow> rows;
  final DateTimeRange weekRange;
  final int todayIndex;
  final bool isOffline;

  ProgressLoaded copyWith({
    List<ProtocolRow>? rows,
    DateTimeRange? weekRange,
    int? todayIndex,
    bool? isOffline,
  }) {
    return ProgressLoaded(
      rows: rows ?? this.rows,
      weekRange: weekRange ?? this.weekRange,
      todayIndex: todayIndex ?? this.todayIndex,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class ProgressError extends ProgressState {
  const ProgressError(this.failure);

  final DomainFailure failure;
}

class ProtocolRow {
  const ProtocolRow({
    required this.protocolId,
    required this.protocolName,
    required this.cells,
  });

  final String protocolId;
  final String protocolName;
  final List<DayCell> cells;
}

class DayCell {
  const DayCell({
    required this.date,
    required this.state,
  });

  final DateTime date;
  final CellState state;
}

enum CellState { completed, notDone, future }
