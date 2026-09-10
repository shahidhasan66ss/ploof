import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_models.dart';

class MessageDraft {
  const MessageDraft({
    required this.text,
    required this.side,
    required this.senderId,
    required this.timestamp,
    required this.status,
  });

  final String text;
  final MessageSide side;
  final String senderId;
  final DateTime timestamp;
  final MessageStatus status;
}

Future<MessageDraft?> showMessageEditorSheet({
  required BuildContext context,
  required List<ChatParticipant> participants,
  ChatMessage? message,
  MessageSide initialSide = MessageSide.outgoing,
}) {
  return showModalBottomSheet<MessageDraft>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _MessageEditorSheet(
      participants: participants,
      message: message,
      initialSide: initialSide,
    ),
  );
}

class _MessageEditorSheet extends StatefulWidget {
  const _MessageEditorSheet({required this.participants, this.message, required this.initialSide});
  final List<ChatParticipant> participants;
  final ChatMessage? message;
  final MessageSide initialSide;

  @override
  State<_MessageEditorSheet> createState() => _MessageEditorSheetState();
}

class _MessageEditorSheetState extends State<_MessageEditorSheet> {
  late final TextEditingController _controller;
  late MessageSide _side;
  late String _senderId;
  late DateTime _time;
  late MessageStatus _status;

  @override
  void initState() {
    super.initState();
    final ChatMessage? message = widget.message;
    _side = message?.side ?? widget.initialSide;
    _senderId = message?.senderId ?? _senderForSide(_side);
    _time = message?.timestamp ?? DateTime.now();
    _status = message?.status ?? (_side == MessageSide.outgoing ? MessageStatus.sent : MessageStatus.none);
    _controller = TextEditingController(text: message?.text ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ChatParticipant> eligible = widget.participants
        .where((ChatParticipant participant) => participant.side == _side)
        .toList(growable: false);
    if (eligible.isNotEmpty && !eligible.any((ChatParticipant item) => item.id == _senderId)) {
      _senderId = eligible.first.id;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.message == null ? 'Add a message' : 'Edit message', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            SegmentedButton<MessageSide>(
              segments: const <ButtonSegment<MessageSide>>[
                ButtonSegment<MessageSide>(value: MessageSide.incoming, label: Text('Incoming'), icon: Icon(Icons.south_west_rounded)),
                ButtonSegment<MessageSide>(value: MessageSide.outgoing, label: Text('Outgoing'), icon: Icon(Icons.north_east_rounded)),
              ],
              selected: <MessageSide>{_side},
              onSelectionChanged: (Set<MessageSide> values) => setState(() {
                _side = values.first;
                _senderId = _senderForSide(_side);
                if (_side == MessageSide.incoming) _status = MessageStatus.none;
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              autofocus: widget.message == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Make the chat chaotic...'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _senderId,
              decoration: const InputDecoration(labelText: 'Sender'),
              items: eligible
                  .map((ChatParticipant participant) => DropdownMenuItem<String>(value: participant.id, child: Text(participant.name)))
                  .toList(growable: false),
              onChanged: (String? value) => setState(() => _senderId = value ?? _senderId),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: Text('Timestamp: ${DateFormat.MMMd().add_jm().format(_time)}')),
                TextButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule_rounded), label: const Text('Change')),
              ],
            ),
            if (_side == MessageSide.outgoing)
              DropdownButtonFormField<MessageStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Message status'),
                items: MessageStatus.values
                    .map((MessageStatus value) => DropdownMenuItem<MessageStatus>(value: value, child: Text(_statusLabel(value))))
                    .toList(growable: false),
                onChanged: (MessageStatus? value) => setState(() => _status = value ?? _status),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final String text = _controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(
                    context,
                    MessageDraft(text: text, side: _side, senderId: _senderId, timestamp: _time, status: _status),
                  );
                },
                child: Text(widget.message == null ? 'Add message' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? selected = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_time));
    if (selected == null || !mounted) return;
    setState(() => _time = DateTime(_time.year, _time.month, _time.day, selected.hour, selected.minute));
  }

  String _senderForSide(MessageSide side) => widget.participants
      .firstWhere(
        (ChatParticipant participant) => participant.side == side,
        orElse: () => widget.participants.first,
      )
      .id;
}

String _statusLabel(MessageStatus status) {
  switch (status) {
    case MessageStatus.none:
      return 'No status';
    case MessageStatus.sent:
      return 'Sent';
    case MessageStatus.delivered:
      return 'Delivered';
    case MessageStatus.seen:
      return 'Seen';
  }
}

Future<ChatParticipant?> showParticipantEditorSheet(BuildContext context, ChatParticipant participant) {
  return showModalBottomSheet<ChatParticipant>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _ParticipantEditorSheet(participant: participant),
  );
}

class _ParticipantEditorSheet extends StatefulWidget {
  const _ParticipantEditorSheet({required this.participant});
  final ChatParticipant participant;

  @override
  State<_ParticipantEditorSheet> createState() => _ParticipantEditorSheetState();
}

class _ParticipantEditorSheetState extends State<_ParticipantEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _initials;
  late int _color;

  static const List<int> colors = <int>[0xFF7058E7, 0xFFF07D69, 0xFF40A98C, 0xFFE2A737, 0xFF4A8DDC, 0xFFC064A3];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.participant.name);
    _initials = TextEditingController(text: widget.participant.initials);
    _color = widget.participant.colorValue;
  }

  @override
  void dispose() {
    _name.dispose();
    _initials.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Edit fictional participant', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Use a playful name or initials. Avoid pretending to be a real person.'),
              const SizedBox(height: 16),
              TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Display name')),
              const SizedBox(height: 12),
              TextField(controller: _initials, maxLength: 2, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Avatar initials', counterText: '')),
              const SizedBox(height: 10),
              Text('Avatar color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: colors
                    .map(
                      (int color) => Semantics(
                        label: 'Avatar color',
                        selected: _color == color,
                        child: InkWell(
                          onTap: () => setState(() => _color = color),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: _color == color ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final String name = _name.text.trim().isEmpty ? widget.participant.name : _name.text.trim();
                    final String initials = _initials.text.trim().isEmpty
                        ? name.substring(0, 1).toUpperCase()
                        : _initials.text.trim().substring(0, 1).toUpperCase();
                    Navigator.pop(
                      context,
                      widget.participant.copyWith(name: name, initials: initials, colorValue: _color),
                    );
                  }, 
                  child: const Text('Save participant'),
                ),
              ),
            ],
          ),
        ),
      );
}
