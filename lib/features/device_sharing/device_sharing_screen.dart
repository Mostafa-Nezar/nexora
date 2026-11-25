import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'models/transfer_models.dart';
import 'services/device_sharing_service.dart';

class DeviceSharingScreen extends StatefulWidget {
  const DeviceSharingScreen({super.key});

  @override
  State<DeviceSharingScreen> createState() => _DeviceSharingScreenState();
}

class _DeviceSharingScreenState extends State<DeviceSharingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeviceSharingService _service = DeviceSharingService();
  final List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service.initialize();
    _service.addListener(_onServiceUpdate);

    // Listen to incoming prompts
    _service.incomingTransfers.listen(_handleIncomingTransferPrompt);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _handleIncomingTransferPrompt(IncomingTransferPrompt prompt) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF131D31),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF1E3A8A),
                child: Icon(Icons.download_rounded, color: Color(0xFF60A5FA), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Incoming File Transfer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${prompt.senderName} wants to send you a file',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt.fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            prompt.formattedSize,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        prompt.completer?.complete(false);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        prompt.completer?.complete(true);
                        Navigator.pop(ctx);
                        _tabController.animateTo(2); // Jump to Transfer tab
                      },
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          for (final path in result.paths) {
            if (path != null) {
              _selectedFiles.add(File(path));
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  void _sendToDevice(DiscoveredDevice device) async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one file to send.')),
      );
      return;
    }

    final filesToSend = List<File>.from(_selectedFiles);
    setState(() {
      _selectedFiles.clear();
    });

    _tabController.animateTo(2); // Switch to Transfers tab
    await _service.sendFiles(targetDevice: device, files: filesToSend);
  }

  void _showPairingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pair with QR / PIN', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: '${_service.deviceId}|${_service.currentLocalIp}|${DeviceSharingService.tcpTransferPort}|${_service.currentPin}',
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PIN: ${_service.currentPin}',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'IP: ${_service.currentLocalIp}:${DeviceSharingService.tcpTransferPort}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  void _showManualConnectDialog() {
    final ipController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Connect by IP & PIN', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Target Device IP',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '192.168.1.50',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Pairing PIN',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '4-digit PIN',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              final ip = ipController.text.trim();
              final pin = pinController.text.trim();
              if (ip.isNotEmpty) {
                final manualDevice = DiscoveredDevice(
                  id: 'manual_${ip.hashCode}',
                  name: 'Device ($ip)',
                  platform: DevicePlatformType.unknown,
                  ip: ip,
                  port: DeviceSharingService.tcpTransferPort,
                  lastSeen: DateTime.now(),
                  pin: pin,
                );
                Navigator.pop(ctx);
                _sendToDevice(manualDevice);
              }
            },
            child: const Text('Connect & Send', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C192E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.wifi_tethering, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Text(
              'Device Sharing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            tooltip: 'My QR Code & PIN',
            onPressed: _showPairingDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_link, color: Colors.white),
            tooltip: 'Direct IP Connect',
            onPressed: _showManualConnectDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: [
            const Tab(icon: Icon(Icons.send_rounded), text: 'Send'),
            const Tab(icon: Icon(Icons.devices_other), text: 'Nearby Devices'),
            Tab(
              icon: Badge(
                isLabelVisible: _service.transfers.any((t) => t.status == TransferStatus.transferring),
                child: const Icon(Icons.swap_horiz_rounded),
              ),
              text: 'Transfers',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildNearbyTab(),
          _buildTransfersTab(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // TAB 1: SEND (Select Files + Quick Transfer Targets)
  // -----------------------------------------------------------
  Widget _buildSendTab() {
    return Column(
      children: [
        // Top Action Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Select Files to Share',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => setState(() => _selectedFiles.clear()),
                  icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                  tooltip: 'Clear selection',
                ),
              ]
            ],
          ),
        ),

        // Selected Files List
        if (_selectedFiles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Items (${_selectedFiles.length})',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatTotalSize(_selectedFiles),
                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedFiles.length,
              itemBuilder: (ctx, i) {
                final file = _selectedFiles[i];
                final name = file.path.split(Platform.pathSeparator).last;
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(_getFileIcon(name), color: const Color(0xFF38BDF8), size: 22),
                          GestureDetector(
                            onTap: () => setState(() => _selectedFiles.removeAt(i)),
                            child: const Icon(Icons.close, size: 16, color: Colors.white60),
                          ),
                        ],
                      ),
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Target Devices
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Send To Nearby Device:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8), size: 20),
                onPressed: () => _service.broadcastBeacon(),
              )
            ],
          ),
        ),

        Expanded(
          child: _service.nearbyDevices.isEmpty
              ? _buildEmptyState(
                  icon: Icons.radar,
                  title: 'Searching for nearby devices...',
                  subtitle: 'Make sure the recipient has Tools open on the Device Sharing tab.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _service.nearbyDevices.length,
                  itemBuilder: (ctx, i) {
                    final dev = _service.nearbyDevices[i];
                    return Card(
                      color: const Color(0xFF131D31),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A),
                          child: Icon(_getPlatformIcon(dev.platform), color: const Color(0xFF60A5FA)),
                        ),
                        title: Text(
                          dev.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${dev.platform.name.toUpperCase()} • ${dev.ip}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _sendToDevice(dev),
                          icon: const Icon(Icons.send, size: 16, color: Colors.white),
                          label: const Text('Send', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------
  // TAB 2: NEARBY DEVICES & RECEIVE RADAR
  // -----------------------------------------------------------
  Widget _buildNearbyTab() {
    return Column(
      children: [
        // My Device Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2B48), Color(0xFF0B192C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2),
                child: const Icon(Icons.wifi_tethering, color: Color(0xFF38BDF8), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _service.deviceName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to receive • IP: ${_service.currentLocalIp}',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                    ),
                    Text(
                      'Security PIN: ${_service.currentPin}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code, color: Colors.white),
                onPressed: _showPairingDialog,
              )
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Devices (${_service.nearbyDevices.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _service.broadcastBeacon(),
                icon: const Icon(Icons.radar, color: Color(0xFF38BDF8), size: 18),
                label: const Text('Rescan', style: TextStyle(color: Color(0xFF38BDF8))),
              ),
            ],
          ),
        ),

        Expanded(
          child: _service.nearbyDevices.isEmpty
              ? _buildEmptyState(
                  icon: Icons.cell_tower,
                  title: 'No devices found nearby',
                  subtitle: 'Make sure other devices are connected to the same Wi-Fi or Hotspot.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _service.nearbyDevices.length,
                  itemBuilder: (ctx, i) {
                    final dev = _service.nearbyDevices[i];
                    return Card(
                      color: const Color(0xFF131D31),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A),
                          child: Icon(_getPlatformIcon(dev.platform), color: const Color(0xFF60A5FA)),
                        ),
                        title: Text(
                          dev.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${dev.platform.name.toUpperCase()} • ${dev.ip}:${dev.port}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            _pickFiles().then((_) {
                              if (_selectedFiles.isNotEmpty) {
                                _sendToDevice(dev);
                              }
                            });
                          },
                          child: const Text('Share', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------
  // TAB 3: ACTIVE TRANSFERS & HISTORY
  // -----------------------------------------------------------
  Widget _buildTransfersTab() {
    if (_service.transfers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.swap_horiz_rounded,
        title: 'No transfers yet',
        subtitle: 'Files sent or received will appear here with live speed and progress.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfers (${_service.transfers.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _service.clearHistory(),
                child: const Text('Clear Finished', style: TextStyle(color: Color(0xFF94A3B8))),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _service.transfers.length,
            itemBuilder: (ctx, i) {
              final item = _service.transfers[i];
              return _buildTransferCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransferCard(TransferItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case TransferStatus.completed:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case TransferStatus.transferring:
        statusColor = const Color(0xFF38BDF8);
        statusIcon = Icons.sync;
        break;
      case TransferStatus.paused:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pause_circle_filled;
        break;
      case TransferStatus.failed:
      case TransferStatus.rejected:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
        statusIcon = Icons.hourglass_top;
    }

    final isSending = item.direction == TransferDirection.send;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isSending ? "Sending to" : "Receiving from"} ${item.remoteDeviceName} • ${item.formattedSize}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (item.status == TransferStatus.transferring) ...[
                IconButton(
                  icon: const Icon(Icons.pause, color: Colors.orangeAccent, size: 20),
                  onPressed: () => _service.pauseTransfer(item.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                  onPressed: () => _service.cancelTransfer(item.id),
                ),
              ] else if (item.status == TransferStatus.paused) ...[
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Color(0xFF10B981), size: 20),
                  onPressed: () => _service.resumeTransfer(item.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                  onPressed: () => _service.cancelTransfer(item.id),
                ),
              ]
            ],
          ),
          if (item.status == TransferStatus.transferring || item.status == TransferStatus.paused) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: item.progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(item.progress * 100).toStringAsFixed(1)}% • ${item.formattedSpeed}',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'ETA: ${item.formattedTimeRemaining}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ] else if (item.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              item.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ] else if (item.status == TransferStatus.completed) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Integrity verified (SHA-256)',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
        return Icons.movie;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getPlatformIcon(DevicePlatformType type) {
    switch (type) {
      case DevicePlatformType.android:
        return Icons.phone_android;
      case DevicePlatformType.ios:
        return Icons.phone_iphone;
      case DevicePlatformType.windows:
        return Icons.desktop_windows;
      case DevicePlatformType.macos:
        return Icons.laptop_mac;
      default:
        return Icons.devices;
    }
  }

  String _formatTotalSize(List<File> files) {
    int total = 0;
    for (final f in files) {
      try {
        total += f.lengthSync();
      } catch (_) {}
    }
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    if (total < 1024 * 1024 * 1024) return '${(total / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(total / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
