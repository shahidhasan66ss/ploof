import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../creations/providers/creation_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../stickers/data/sticker_catalog.dart';
import '../../../stickers/models/sticker.dart';
import '../../../templates/models/chat_template.dart';
import '../../../templates/providers/template_providers.dart';
import '../../models/chat_models.dart';
import '../../models/chat_theme.dart';
import '../../providers/editor_provider.dart';
import '../widgets/chat_renderer.dart';
import '../widgets/editor_sheets.dart';
import '../widgets/editor_toolbar.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({this.templateId, this.creationId, super.key});

  final String? templateId;
  final String? creationId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final HapticsService _haptics = const HapticsService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    final EditorNotifier editor = ref.read(editorProvider.notifier);
    if (widget.creationId != null) {
      final ChatProject? project = await ref.read(creationsProvider.notifier).getById(widget.creationId!);
      if (!mounted) return;
      if (project != null) {
        editor.initializeProject(project);
      } else {
        editor.initializeBlank();
        _showMessage('That saved chat could not be found. Here is a fresh one instead.');
      }
      return;
    }
    if (widget.templateId != null) {
      final ChatTemplate? template = ref.read(templateByIdProvider(widget.templateId!));
      if (template != null) {
        editor.initializeTemplate(template);
      } else {
        editor.initializeBlank();
        _showMessage('That template is unavailable. You can still make something funny.');
      }
      return;
    }
    editor.initializeBlank();
  }

  @override
  Widget build(BuildContext context) {
    final EditorState editorState = ref.watch(editorProvider);
    final ChatProject? project = editorState.project;
    if (project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _editTitle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(child: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 3),
              const Icon(Icons.edit_rounded, size: 16),
            ],
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Undo',
            onPressed: editorState.canUndo ? ref.read(editorProvider.notifier).undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: editorState.canRedo ? ref.read(editorProvider.notifier).redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(tooltip: 'Preview', onPressed: _preview, icon: const Icon(Icons.visibility_outlined)),
          TextButton(onPressed: _preview, child: const Text('Export')),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _ParticipantStrip(project: project, onTap: _editParticipant),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: ChatRenderer(
                  project: project,
                  selectedMessageId: editorState.selectedMessageId,
                  onReorder: (int oldIndex, int newIndex) {
                    ref.read(editorProvider.notifier).reorderMessages(oldIndex, newIndex);
                    _tapHaptic();
                  },
                  onMessageTap: (ChatMessage message) {
                    ref.read(editorProvider.notifier).selectMessage(message.id);
                    _messageActions(message);
                  },
                  onStickerTap: _stickerActions,
                ),
              ),
            ),
            EditorToolbar(
              onAddMessage: _addMessage,
              onMedia: _addMedia,
              onSticker: _addSticker,
              onReaction: _addReaction,
              onStyle: _chooseStyle,
              onMore: _showMore,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preview() async {
    final ChatProject? project = ref.read(editorProvider).project;
    if (project == null) return;
    try {
      await ref.read(creationsProvider.notifier).save(project);
      if (!mounted) return;
      context.push('/preview');
    } on CreationStorageException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _editTitle() async {
    final ChatProject? project = ref.read(editorProvider).project;
    if (project == null) return;
    final TextEditingController controller = TextEditingController(text: project.name);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Conversation title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Untitled chat'),
          onSubmitted: (String value) => Navigator.pop(dialogContext, value),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name != null) ref.read(editorProvider.notifier).setProjectTitle(name);
  }

  Future<void> _editParticipant(ChatParticipant participant) async {
    final ChatParticipant? updated = await showParticipantEditorSheet(context, participant);
    if (updated == null || !mounted) return;
    ref.read(editorProvider.notifier).updateParticipant(updated);
    _tapHaptic();
  }

  Future<void> _addMessage() async {
    final MessageSide? side = await showModalBottomSheet<MessageSide>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Which side?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.south_west_rounded)),
                title: const Text('Incoming message'),
                subtitle: const Text('From your fictional friend'),
                onTap: () => Navigator.pop(context, MessageSide.incoming),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.north_east_rounded)),
                title: const Text('Outgoing message'),
                subtitle: const Text('From your fictional self'),
                onTap: () => Navigator.pop(context, MessageSide.outgoing),
              ),
            ],
          ),
        ),
      ),
    );
    if (side == null || !mounted) return;
    final ChatProject? project = ref.read(editorProvider).project;
    if (project == null) return;
    final MessageDraft? draft = await showMessageEditorSheet(context: context, participants: project.participants, initialSide: side);
    if (draft == null || !mounted) return;
    final EditorNotifier editor = ref.read(editorProvider.notifier);
    editor.addTextMessage(side: draft.side, senderId: draft.senderId, text: draft.text);
    final ChatMessage? last = ref.read(editorProvider).project?.messages.last;
    if (last != null) {
      editor.updateMessage(last.copyWith(timestamp: draft.timestamp, status: draft.status));
      editor.selectMessage(last.id);
    }
    _tapHaptic();
  }

  Future<void> _editMessage(ChatMessage message) async {
    final ChatProject? project = ref.read(editorProvider).project;
    if (project == null || message.type == ChatMessageType.image) return;
    final MessageDraft? draft = await showMessageEditorSheet(context: context, participants: project.participants, message: message);
    if (draft == null || !mounted) return;
    ref.read(editorProvider.notifier).updateMessage(
          message.copyWith(
            text: draft.text,
            side: draft.side,
            senderId: draft.senderId,
            timestamp: draft.timestamp,
            status: draft.status,
          ),
        );
    _tapHaptic();
  }

  Future<void> _messageActions(ChatMessage message) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit text, sender & time'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Duplicate message'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(editorProvider.notifier).duplicateMessage(message.id);
                  _tapHaptic();
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_arrow_up_rounded),
                title: const Text('Move up'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(editorProvider.notifier).moveMessage(message.id, -1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_arrow_down_rounded),
                title: const Text('Move down'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(editorProvider.notifier).moveMessage(message.id, 1);
                },
              ),
              ListTile(
                leading: Icon(message.reaction == null ? Icons.add_reaction_outlined : Icons.remove_circle_outline),
                title: Text(message.reaction == null ? 'Add reaction' : 'Remove reaction'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (message.reaction == null) {
                    _addReaction();
                  } else {
                    ref.read(editorProvider.notifier).removeReaction(message.id);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(editorProvider.notifier).deleteMessage(message.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _stickerActions(ChatStickerPlacement sticker) async {
    final bool? remove = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(sticker.emoji, style: const TextStyle(fontSize: 45)),
              const SizedBox(height: 8),
              Text('Remove this sticker?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.delete_outline), label: const Text('Remove sticker')),
            ],
          ),
        ),
      ),
    );
    if (remove == true && mounted) ref.read(editorProvider.notifier).removeSticker(sticker.id);
  }

  Future<void> _addSticker() async {
    final ChatProject? project = ref.read(editorProvider).project;
    if (project == null || project.messages.isEmpty) {
      _showMessage('Add a message first, then attach a sticker.');
      return;
    }
    final StickerItem? sticker = await showModalBottomSheet<StickerItem>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _StickerPickerSheet(),
    );
    if (sticker == null || !mounted) return;
    ref.read(editorProvider.notifier).addSticker(sticker);
    _tapHaptic();
  }

  Future<void> _addReaction() async {
    final String? selected = ref.read(editorProvider).selectedMessageId;
    if (selected == null) {
      _showMessage('Tap a message first, then add a reaction.');
      return;
    }
    final String? emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Pick a reaction', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: reactionEmojis
                    .map((String emoji) => InkWell(
                          onTap: () => Navigator.pop(context, emoji),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                            child: Text(emoji, style: const TextStyle(fontSize: 28)),
                          ),
                        ))
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
    if (emoji == null || !mounted) return;
    ref.read(editorProvider.notifier).addReaction(selected, emoji);
    _tapHaptic();
  }

  Future<void> _addMedia() async {
    final MessageSide? side = await showModalBottomSheet<MessageSide>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Add a local image', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('The picture stays on your device and is never uploaded.'),
              const SizedBox(height: 12),
              ListTile(leading: const Icon(Icons.south_west_rounded), title: const Text('Incoming image'), onTap: () => Navigator.pop(context, MessageSide.incoming)),
              ListTile(leading: const Icon(Icons.north_east_rounded), title: const Text('Outgoing image'), onTap: () => Navigator.pop(context, MessageSide.outgoing)),
            ],
          ),
        ),
      ),
    );
    if (side == null) return;
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 2400);
      if (image == null || !mounted) return;
      final int bytes = await image.length();
      if (!mounted) return;
      if (bytes > AppConstants.maxImageBytes) {
        _showMessage('That image is too large. Try one under 15 MB.');
        return;
      }
      final bool exists = await File(image.path).exists();
      if (!mounted) return;
      if (!exists) {
        _showMessage('That image is no longer available. Please choose another one.');
        return;
      }
      final String localPath = await ref.read(creationStorageProvider).persistMedia(image.path);
      if (!mounted) return;
      ref.read(editorProvider.notifier).addMedia(side: side, path: localPath);
      _tapHaptic();
    } catch (_) {
      if (mounted) _showMessage('Could not add that image. Check photo access and try again.');
    }
  }

  Future<void> _chooseStyle() async {
    final String? styleId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Choose a chat style', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              SizedBox(
                height: 310,
                child: GridView.builder(
                  itemCount: chatThemes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.75),
                  itemBuilder: (BuildContext context, int index) {
                    final ChatThemeStyle style = chatThemes[index];
                    return InkWell(
                      onTap: () => Navigator.pop(context, style.id),
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(17), border: Border.all(color: style.timestamp.withOpacity(.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Container(width: 29, height: 13, decoration: BoxDecoration(color: style.incomingBubble, borderRadius: BorderRadius.circular(8))),
                                  const Spacer(),
                                  Container(width: 29, height: 13, decoration: BoxDecoration(color: style.outgoingBubble, borderRadius: BorderRadius.circular(8))),
                                ],
                              ),
                            ),
                            Text(style.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: style.incomingText, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (styleId != null && mounted) {
      ref.read(editorProvider.notifier).changeTheme(styleId);
      _tapHaptic();
    }
  }

  Future<void> _showMore() async {
    final ChatProject? project = ref.read(editorProvider).project;
    if (project == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.people_outline_rounded),
                title: const Text('Edit participants'),
                subtitle: const Text('Names, initials and avatar colors'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _participantsSheet(project);
                },
              ),
              ListTile(
                leading: const Icon(Icons.more_time_rounded),
                title: const Text('Add typing indicator'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _chooseTyping();
                },
              ),
              ListTile(
                leading: const Icon(Icons.shuffle_rounded),
                title: const Text('Randomize a line'),
                subtitle: const Text('Uses safe built-in content — no AI'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(editorProvider.notifier).randomizeTemplate();
                  _tapHaptic();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _participantsSheet(ChatProject project) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: project.participants
                .map(
                  (ChatParticipant participant) => ListTile(
                    leading: CircleAvatar(backgroundColor: Color(participant.colorValue), child: Text(participant.initials, style: const TextStyle(color: Colors.white))),
                    title: Text(participant.name),
                    subtitle: Text(participant.side == MessageSide.outgoing ? 'Outgoing side' : 'Incoming side'),
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _editParticipant(participant);
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _chooseTyping() async {
    final MessageSide? side = await showModalBottomSheet<MessageSide>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(title: const Text('Incoming typing'), leading: const Icon(Icons.south_west_rounded), onTap: () => Navigator.pop(context, MessageSide.incoming)),
              ListTile(title: const Text('Outgoing typing'), leading: const Icon(Icons.north_east_rounded), onTap: () => Navigator.pop(context, MessageSide.outgoing)),
            ],
          ),
        ),
      ),
    );
    if (side != null && mounted) {
      ref.read(editorProvider.notifier).addTyping(side: side);
      _tapHaptic();
    }
  }

  void _tapHaptic() {
    _haptics.tap(enabled: ref.read(settingsProvider).hapticsEnabled);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ParticipantStrip extends StatelessWidget {
  const _ParticipantStrip({required this.project, required this.onTap});
  final ChatProject project;
  final ValueChanged<ChatParticipant> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 6),
          itemCount: project.participants.length,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
          itemBuilder: (BuildContext context, int index) {
            final ChatParticipant participant = project.participants[index];
            return ActionChip(
              avatar: CircleAvatar(backgroundColor: Color(participant.colorValue), child: Text(participant.initials, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800))),
              label: Text(participant.name),
              onPressed: () => onTap(participant),
            );
          },
        ),
      );
}

class _StickerPickerSheet extends StatefulWidget {
  const _StickerPickerSheet();

  @override
  State<_StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<_StickerPickerSheet> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final List<StickerItem> visible = stickers.where((StickerItem sticker) => _category == 'All' || sticker.category == _category).toList(growable: false);
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Sticker shelf', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stickerCategories.length,
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) => ChoiceChip(
                    label: Text(stickerCategories[index]),
                    selected: _category == stickerCategories[index],
                    onSelected: (_) => setState(() => _category = stickerCategories[index]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: visible.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemBuilder: (BuildContext context, int index) => Semantics(
                    button: true,
                    label: visible[index].label,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, visible[index]),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(visible[index].emoji, style: const TextStyle(fontSize: 31)),
                            const SizedBox(height: 3),
                            Text(visible[index].label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
