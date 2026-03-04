import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlens_mobile/models/message_model.dart';

/// Scrollable transcript panel showing the conversation between user and
/// Dr. Muhammad.
///
/// Agent messages are left-aligned in blue; user messages are right-aligned in
/// a translucent white. Each bubble shows a speaker label and timestamp.
class TranscriptPanel extends StatefulWidget {
  const TranscriptPanel({super.key, required this.messages});

  final List<MessageModel> messages;

  @override
  State<TranscriptPanel> createState() => _TranscriptPanelState();
}

class _TranscriptPanelState extends State<TranscriptPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant TranscriptPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text(
          'Listening…',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return _TranscriptBubble(message: widget.messages[index]);
      },
    );
  }
}

// =====================================================================
//  Single transcript bubble
// =====================================================================

class _TranscriptBubble extends StatelessWidget {
  const _TranscriptBubble({required this.message});
  final MessageModel message;

  static final DateFormat _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final isAgent = message.speaker == 'agent';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isAgent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              // Speaker label
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
                child: Text(
                  isAgent ? 'Dr. Muhammad' : 'You',
                  style: TextStyle(
                    color: isAgent
                        ? const Color(0xFF90CAF9)
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Bubble
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isAgent
                      ? const Color(0xFF1A73E8).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isAgent ? 4 : 16),
                    bottomRight: Radius.circular(isAgent ? 16 : 4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isAgent
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              // Timestamp
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, top: 2),
                child: Text(
                  _timeFmt.format(message.timestamp),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
