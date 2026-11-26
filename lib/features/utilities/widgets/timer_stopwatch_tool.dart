import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_toast.dart';

enum _ClockMode { timer, stopwatch, alarm }

class TimerStopwatchTool extends StatefulWidget {
  const TimerStopwatchTool({super.key});

  @override
  State<TimerStopwatchTool> createState() => _TimerStopwatchNexoratate();
}

class _TimerStopwatchNexoratate extends State<TimerStopwatchTool> {
  _ClockMode _mode = _ClockMode.timer;

  // Countdown Timer state
  Duration _initialDuration = const Duration(minutes: 5);
  Duration _remainingDuration = const Duration(minutes: 5);
  Timer? _countdownTimer;
  bool _isCountdownRunning = false;

  // Stopwatch state
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTicker;
  final List<_LapRecord> _laps = [];
  Duration _lastLapTotal = Duration.zero;

  // Alarm state
  final List<_AlarmItem> _alarms = [];
  Timer? _alarmTicker;
  int _nextAlarmId = 1;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopwatchTicker?.cancel();
    _alarmTicker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _setPreset(Duration duration) {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownRunning = false;
      _initialDuration = duration;
      _remainingDuration = duration;
    });
  }

  void _adjustDuration(Duration delta) {
    if (_isCountdownRunning) return;
    final nextSeconds = (_remainingDuration.inSeconds + delta.inSeconds).clamp(
      0,
      359999,
    );
    final updated = Duration(seconds: nextSeconds);
    setState(() {
      _initialDuration = updated;
      _remainingDuration = updated;
    });
  }

  void _toggleCountdown() {
    if (_isCountdownRunning) {
      _countdownTimer?.cancel();
      setState(() => _isCountdownRunning = false);
      return;
    }
    if (_remainingDuration.inSeconds <= 0) {
      if (_initialDuration.inSeconds <= 0) return;
      _remainingDuration = _initialDuration;
    }

    setState(() => _isCountdownRunning = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingDuration.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingDuration = Duration.zero;
          _isCountdownRunning = false;
        });
        HapticFeedback.heavyImpact();
        AppToast.success(context, 'Timer finished!');
      } else {
        setState(() {
          _remainingDuration -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _resetCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownRunning = false;
      _remainingDuration = _initialDuration;
    });
  }

  void _toggleStopwatch() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _stopwatchTicker?.cancel();
      setState(() {});
    } else {
      _stopwatch.start();
      _stopwatchTicker = Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (mounted) setState(() {});
      });
      setState(() {});
    }
  }

  void _recordLap() {
    if (!_stopwatch.isRunning) return;
    final total = _stopwatch.elapsed;
    final split = total - _lastLapTotal;
    setState(() {
      _laps.insert(
        0,
        _LapRecord(index: _laps.length + 1, split: split, total: total),
      );
      _lastLapTotal = total;
    });
  }

  void _resetStopwatch() {
    _stopwatch.stop();
    _stopwatch.reset();
    _stopwatchTicker?.cancel();
    setState(() {
      _laps.clear();
      _lastLapTotal = Duration.zero;
    });
  }

  String _formatCountdown(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatStopwatch(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centis = (d.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$centis';
  }

  void _ensureAlarmTicker() {
    if (_alarms.any((a) => a.enabled)) {
      _alarmTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final now = DateTime.now();
        for (var i = 0; i < _alarms.length; i++) {
          final alarm = _alarms[i];
          if (alarm.enabled && !now.isBefore(alarm.nextTrigger)) {
            _alarms[i] = alarm.copyWith(enabled: false);
            _onAlarmTriggered(alarm);
          }
        }
        if (!_alarms.any((a) => a.enabled)) {
          _alarmTicker?.cancel();
          _alarmTicker = null;
        }
        setState(() {});
      });
    } else {
      _alarmTicker?.cancel();
      _alarmTicker = null;
    }
  }

  void _onAlarmTriggered(_AlarmItem alarm) {
    HapticFeedback.heavyImpact();
    AppToast.success(context, 'Alarm: ${alarm.label}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.4)),
        ),
        title: const Row(
          children: [
            Icon(Icons.alarm_on_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Alarm Ringing', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '${alarm.formattedTime} — ${alarm.label}',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Alarm.stop(alarm.id).catchError((_) => false);
              Navigator.of(ctx).pop();
              final snoozeTarget = DateTime.now().add(const Duration(minutes: 5));
              _addAlarmForTime(
                snoozeTarget.hour,
                snoozeTarget.minute,
                '${alarm.label} (Snooze)',
                exactTarget: snoozeTarget,
              );
            },
            child: const Text(
              'Snooze 5m',
              style: TextStyle(color: Colors.amberAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Alarm.stop(alarm.id).catchError((_) => false);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: const Color(0xFF030712),
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleNativeAlarm(_AlarmItem alarm) async {
    try {
      final settings = AlarmSettings(
        id: alarm.id,
        dateTime: alarm.nextTrigger,
        assetAudioPath: null,
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          fadeDuration: const Duration(seconds: 3),
          volume: 0.9,
        ),
        notificationSettings: NotificationSettings(
          title: 'Nexora Alarm',
          body: '${alarm.formattedTime} — ${alarm.label}',
          stopButton: 'Stop',
        ),
      );
      await Alarm.set(alarmSettings: settings);
    } catch (_) {
      // Ignored in environments without native alarm platform channel (e.g. tests).
    }
  }

  Future<void> _pickAndAddAlarm() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked == null || !mounted) return;
    _addAlarmForTime(picked.hour, picked.minute, 'Alarm');
  }

  void _addQuickAlarm(Duration offset) {
    final target = DateTime.now().add(offset);
    _addAlarmForTime(
      target.hour,
      target.minute,
      'Quick Alarm (+${offset.inMinutes}m)',
      exactTarget: target,
    );
  }

  void _addAlarmForTime(
    int hour,
    int minute,
    String label, {
    DateTime? exactTarget,
  }) {
    final now = DateTime.now();
    var target = exactTarget ?? DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    final newAlarm = _AlarmItem(
      id: _nextAlarmId++,
      hour: hour,
      minute: minute,
      label: label,
      enabled: true,
      nextTrigger: target,
    );
    setState(() {
      _alarms.add(newAlarm);
    });
    _scheduleNativeAlarm(newAlarm);
    _ensureAlarmTicker();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _modePill(
                  label: 'Timer',
                  icon: Icons.hourglass_bottom_rounded,
                  selected: _mode == _ClockMode.timer,
                  onTap: () => setState(() => _mode = _ClockMode.timer),
                ),
              ),
              Expanded(
                child: _modePill(
                  label: 'Stopwatch',
                  icon: Icons.timer_outlined,
                  selected: _mode == _ClockMode.stopwatch,
                  onTap: () => setState(() => _mode = _ClockMode.stopwatch),
                ),
              ),
              Expanded(
                child: _modePill(
                  label: 'Alarm',
                  icon: Icons.alarm_rounded,
                  selected: _mode == _ClockMode.alarm,
                  onTap: () => setState(() => _mode = _ClockMode.alarm),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        switch (_mode) {
          _ClockMode.timer => _buildTimerView(),
          _ClockMode.stopwatch => _buildStopwatchView(),
          _ClockMode.alarm => _buildAlarmView(),
        },
      ],
    );
  }

  Widget _modePill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amberAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? const Color(0xFF030712) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF030712) : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerView() {
    final total = _initialDuration.inSeconds;
    final progress =
        total > 0 ? (_remainingDuration.inSeconds / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final mins in [1, 5, 10, 15, 30])
              ChoiceChip(
                label: Text('${mins}m'),
                selected:
                    !_isCountdownRunning &&
                    _initialDuration.inMinutes == mins &&
                    _initialDuration.inSeconds == mins * 60,
                onSelected: (_) => _setPreset(Duration(minutes: mins)),
                selectedColor: Colors.amberAccent,
                backgroundColor: const Color(0xFF111827),
                labelStyle: TextStyle(
                  color:
                      (!_isCountdownRunning &&
                              _initialDuration.inSeconds == mins * 60)
                          ? const Color(0xFF030712)
                          : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: Colors.white12),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.amberAccent,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCountdown(_remainingDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isCountdownRunning
                        ? 'Running'
                        : (_remainingDuration == Duration.zero
                            ? 'Completed'
                            : 'Ready'),
                    style: TextStyle(
                      color:
                          _isCountdownRunning
                              ? Colors.amberAccent
                              : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!_isCountdownRunning)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _adjustChip('-1m', () => _adjustDuration(const Duration(minutes: -1))),
              const SizedBox(width: 6),
              _adjustChip('-10s', () => _adjustDuration(const Duration(seconds: -10))),
              const SizedBox(width: 6),
              _adjustChip('+10s', () => _adjustDuration(const Duration(seconds: 10))),
              const SizedBox(width: 6),
              _adjustChip('+1m', () => _adjustDuration(const Duration(minutes: 1))),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleCountdown,
                icon: Icon(
                  _isCountdownRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(_isCountdownRunning ? 'Pause' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: const Color(0xFF030712),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetCountdown,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adjustChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStopwatchView() {
    final elapsed = _stopwatch.elapsed;
    final running = _stopwatch.isRunning;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Center(
            child: Text(
              _formatStopwatch(elapsed),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleStopwatch,
                icon: Icon(
                  running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(running ? 'Pause' : (elapsed > Duration.zero ? 'Resume' : 'Start')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: const Color(0xFF030712),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: running ? _recordLap : _resetStopwatch,
                icon: Icon(running ? Icons.flag_outlined : Icons.refresh_rounded),
                label: Text(running ? 'Lap' : 'Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_laps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _laps.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 10),
              itemBuilder: (context, index) {
                final lap = _laps[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lap ${lap.index}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '+${_formatStopwatch(lap.split)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _formatStopwatch(lap.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
  Widget _buildAlarmView() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final mins in [1, 5, 15, 30, 60])
              ActionChip(
                label: Text('+${mins}m'),
                onPressed: () => _addQuickAlarm(Duration(minutes: mins)),
                backgroundColor: const Color(0xFF111827),
                labelStyle: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: Colors.white12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickAndAddAlarm,
          icon: const Icon(Icons.add_alarm_rounded),
          label: const Text('Set Custom Alarm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent,
            foregroundColor: const Color(0xFF030712),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        if (_alarms.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Text(
              'No alarms set. Tap a quick chip or "Set Custom Alarm".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _alarms.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Colors.white12, height: 10),
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                final diff = alarm.nextTrigger.difference(now);
                final statusText = alarm.enabled
                    ? (diff.isNegative
                        ? 'Ringing...'
                        : 'In ${diff.inHours}h ${diff.inMinutes.remainder(60)}m ${diff.inSeconds.remainder(60)}s')
                    : 'Off';
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.formattedTime,
                            style: TextStyle(
                              color: alarm.enabled
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            '${alarm.label} • $statusText',
                            style: TextStyle(
                              color: alarm.enabled
                                  ? Colors.amberAccent
                                  : Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm.enabled,
                      activeThumbColor: Colors.amberAccent,
                      onChanged: (val) {
                        setState(() {
                          var next = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            alarm.hour,
                            alarm.minute,
                          );
                          if (!next.isAfter(now)) {
                            next = next.add(const Duration(days: 1));
                          }
                          final updated = alarm.copyWith(
                            enabled: val,
                            nextTrigger: next,
                          );
                          _alarms[index] = updated;
                          if (val) {
                            _scheduleNativeAlarm(updated);
                          } else {
                            Alarm.stop(alarm.id).catchError((_) => false);
                          }
                        });
                        _ensureAlarmTicker();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () {
                        Alarm.stop(alarm.id).catchError((_) => false);
                        setState(() => _alarms.removeAt(index));
                        _ensureAlarmTicker();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LapRecord {
  final int index;
  final Duration split;
  final Duration total;

  const _LapRecord({
    required this.index,
    required this.split,
    required this.total,
  });
}

class _AlarmItem {
  final int id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final DateTime nextTrigger;

  const _AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
    required this.nextTrigger,
  });

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  _AlarmItem copyWith({bool? enabled, DateTime? nextTrigger}) {
    return _AlarmItem(
      id: id,
      hour: hour,
      minute: minute,
      label: label,
      enabled: enabled ?? this.enabled,
      nextTrigger: nextTrigger ?? this.nextTrigger,
    );
  }
}
