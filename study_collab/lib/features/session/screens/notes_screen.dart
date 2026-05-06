import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

class NotesScreen extends StatefulWidget {
  final String sessionId;
  const NotesScreen({super.key, required this.sessionId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late List<SharedFile> _files;

  @override
  void initState() {
    super.initState();
    _seedFiles();
  }

  void _seedFiles() {
    final now = DateTime.now();
    _files = [
      SharedFile(
        id: '1',
        name: 'Lecture Notes Week 12.pdf',
        url: '',
        uploaderId: 'host-1',
        uploaderName: 'Alex Johnson',
        type: 'pdf',
        uploadedAt: now.subtract(const Duration(hours: 3)),
      ),
      SharedFile(
        id: '2',
        name: 'Practice Problems Set.pdf',
        url: '',
        uploaderId: 'member-1',
        uploaderName: 'Priya Sharma',
        type: 'pdf',
        uploadedAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      SharedFile(
        id: '3',
        name: 'Useful Reference Guide',
        url: 'https://example.com/ref',
        uploaderId: 'host-1',
        uploaderName: 'Alex Johnson',
        type: 'link',
        uploadedAt: now.subtract(const Duration(minutes: 45)),
      ),
      SharedFile(
        id: '4',
        name: 'Whiteboard Photo.jpg',
        url: '',
        uploaderId: 'member-2',
        uploaderName: 'Sam Lee',
        type: 'image',
        uploadedAt: now.subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  String? get _myId =>
      context.read<AuthProvider>().currentUser?.id;
  String? get _myName =>
      context.read<AuthProvider>().currentUser?.name;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = (file.extension ?? '').toLowerCase();
        final type = _extToType(ext);
        setState(() {
          _files.insert(
            0,
            SharedFile(
              id: const Uuid().v4(),
              name: file.name,
              url: '',
              uploaderId: _myId ?? 'me',
              uploaderName: _myName ?? 'You',
              type: type,
              uploadedAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (_) {}
  }

  String _extToType(String ext) {
    if (['pdf'].contains(ext)) return 'pdf';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['doc', 'docx', 'txt', 'md'].contains(ext)) return 'doc';
    return 'doc';
  }

  void _addLink(String name, String url) {
    setState(() {
      _files.insert(
        0,
        SharedFile(
          id: const Uuid().v4(),
          name: name.isEmpty ? url : name,
          url: url,
          uploaderId: _myId ?? 'me',
          uploaderName: _myName ?? 'You',
          type: 'link',
          uploadedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _showUploadMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _UploadOption(
                icon: Icons.upload_file_outlined,
                label: 'Upload File',
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
              _UploadOption(
                icon: Icons.link_outlined,
                label: 'Add Link',
                onTap: () {
                  Navigator.pop(context);
                  _showAddLinkDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLinkDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Label (optional)',
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link_outlined, size: 18),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.hint)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 38)),
            onPressed: () {
              if (urlCtrl.text.trim().isNotEmpty) {
                _addLink(nameCtrl.text.trim(), urlCtrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context
        .read<SessionsProvider>()
        .sessions
        .where((s) => s.id == widget.sessionId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(session?.title ?? 'Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadMenu,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Web drop zone
          if (kIsWeb) ...[
            DottedBorder(
              color: AppColors.border,
              strokeWidth: 1.5,
              dashPattern: const [8, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          color: AppColors.hint, size: 20),
                      const SizedBox(width: 8),
                      Text('Drop files here to upload',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.hint)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_files.isEmpty)
            _EmptyNotes()
          else
            ..._files.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FileItem(
                    file: f,
                    isOwner: f.uploaderId == (_myId ?? ''),
                    onDelete: () =>
                        setState(() => _files.remove(f)),
                  ),
                )),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _UploadOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: AppColors.background,
      leading: Icon(icon, color: AppColors.accent),
      title: Text(label),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.hint),
      onTap: onTap,
    );
  }
}

class _FileItem extends StatelessWidget {
  final SharedFile file;
  final bool isOwner;
  final VoidCallback onDelete;
  const _FileItem(
      {required this.file,
      required this.isOwner,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final timeStr = DateFormat('MMM d, h:mm a').format(file.uploadedAt);
    final (icon, color) = _iconFor(file.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${file.uploaderName} · $timeStr',
                    style:
                        tt.labelSmall?.copyWith(color: AppColors.hint)),
              ],
            ),
          ),
          // Actions
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  size: 18, color: AppColors.hint),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onSelected: (v) {
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.download_outlined,
                  size: 18, color: AppColors.hint),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Downloading ${file.name}...')),
                );
              },
            ),
        ],
      ),
    );
  }

  (IconData, Color) _iconFor(String type) {
    return switch (type) {
      'pdf' => (Icons.picture_as_pdf_outlined, const Color(0xFFE53E3E)),
      'image' => (Icons.image_outlined, const Color(0xFF5186CD)),
      'link' => (Icons.link_outlined, AppColors.accent),
      _ => (Icons.description_outlined, const Color(0xFF16A085)),
    };
  }
}

class _EmptyNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_outlined,
              size: 56, color: AppColors.disabled),
          const SizedBox(height: 16),
          Text('No files yet', style: tt.titleLarge),
          const SizedBox(height: 6),
          Text('Tap + to upload a file or add a link',
              style: tt.bodyMedium?.copyWith(color: AppColors.hint)),
        ],
      ),
    );
  }
}
