// FarmTap AI chat (decision 0027): one box. Type a question, attach photos
// or a video with the plus, and get an answer. Online, Google Gemini answers
// with FarmTap's facts about the cow that was named; offline (or when it is
// switched off) the built-in assistant answers simple farm questions from the
// records. An answer about a named cow is saved to that cow's health history.
// Photos and videos are held in memory for the one question and never stored.
import 'dart:async';
import 'dart:typed_data';

import 'package:farm_tap/core/ai/ai_assistant.dart';
import 'package:farm_tap/core/ai/ai_chat.dart';
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_herd.dart';
import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:farm_tap/core/ai/ai_privacy.dart';
import 'package:farm_tap/core/ai/ai_repository.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

class _Attached {
  const new(this.name, this.mime, this.kind, this.bytes);
  final String name;
  final String mime;
  final String kind;
  final Uint8List bytes;
}

class _Turn {
  const new({
    required this.fromUser,
    required this.text,
    this.files = const [],
    this.method,
    this.about,
    this.saved = false,
    this.note,
  });

  final bool fromUser;
  final String text;
  final List<_Attached> files;
  final Method? method;
  final String? about;
  final bool saved;
  final String? note;
}

class AiChatPage extends StatefulWidget {
  const new({required this.ctx, super.key, this.animalId});

  final AiPageContext ctx;

  /// Opened from an animal's page.
  final String? animalId;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  final _files = <_Attached>[];
  late String? _animalId = widget.animalId;
  AiFarm? _farm;
  bool _busy = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<AiFarm> _reload() async {
    final f = await widget.ctx.repo.load(role: widget.ctx.role);
    if (mounted) setState(() => _farm = f);
    return f;
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: context.motion.normal,
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  String _mimeOf(String path, {required bool video}) {
    final p = path.toLowerCase();
    if (video) {
      if (p.endsWith('.mov')) return 'video/quicktime';
      if (p.endsWith('.webm')) return 'video/webm';
      if (p.endsWith('.3gp')) return 'video/3gpp';
      return 'video/mp4';
    }
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  int get _fileBytes => _files.fold(0, (t, f) => t + f.bytes.length);

  Future<void> _attach(AppLocalizations l10n, String what) async {
    final picker = ImagePicker();
    try {
      final picked = <XFile>[];
      var video = false;
      switch (what) {
        case 'camera':
          final x = await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: photoMaxSide.toDouble(),
            imageQuality: 82,
          );
          if (x != null) picked.add(x);
        case 'gallery':
          picked.addAll(
            await picker.pickMultiImage(maxWidth: photoMaxSide.toDouble(), imageQuality: 82),
          );
        case 'video':
          video = true;
          final x = await picker.pickVideo(source: ImageSource.gallery);
          if (x != null) picked.add(x);
        case 'record':
          video = true;
          final x = await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
          if (x != null) picked.add(x);
      }
      for (final x in picked) {
        if (_files.length >= chatMaxFiles) {
          setState(() => _problem = l10n.aiChatFileLimit(chatMaxFiles));
          break;
        }
        if (_fileBytes + await x.length() > chatMaxBytes) {
          setState(() => _problem = l10n.aiChatTooBig);
          break;
        }
        final mime = _mimeOf(x.path, video: video);
        final kind = chatFileKind(mime);
        if (kind == null) continue;
        final bytes = await x.readAsBytes();
        _files.add(_Attached(x.name, mime, kind, bytes));
        setState(() => _problem = null);
      }
      if (mounted) setState(() {});
    } on Object {
      if (mounted) setState(() => _problem = l10n.aiPhotoFailed);
    }
  }

  Future<void> _attachSheet(AppLocalizations l10n) async {
    final what = await showAdaptiveSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.aiChatAttach),
          sheet.space.gapMd,
          for (final (icon, label, key) in [
            (Symbols.photo_camera_rounded, l10n.takePhoto, 'camera'),
            (Symbols.photo_library_rounded, l10n.chooseFromGallery, 'gallery'),
            (Symbols.videocam_rounded, l10n.aiChatVideo, 'video'),
            (Symbols.video_camera_back_rounded, l10n.aiChatRecord, 'record'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: sheet.colors.primary),
              title: Text(label),
              onTap: () => Navigator.of(sheet).pop(key),
            ),
        ],
      ),
    );
    if (what != null && mounted) await _attach(l10n, what);
  }

  Future<void> _send(AppLocalizations l10n) async {
    final typed = _text.text.trim();
    if ((typed.isEmpty && _files.isEmpty) || _busy) return;
    final question = typed.isEmpty ? l10n.aiChatLookAtThis : typed;
    final sent = List<_Attached>.of(_files);
    final started = context.clock.now();
    setState(() {
      _text.clear();
      _files.clear();
      _problem = null;
      _busy = true;
      _turns.add(_Turn(fromUser: true, text: question, files: sent));
    });
    _toEnd();
    final farm = await _reload();
    if (!mounted) return;
    final ctx = widget.ctx;
    final animals = alive(farm.data.animals).where(isActive).toList();
    final cows = [for (final a in animals) Mentionable(a.id, name: a.str('name'), tag: a.str('tagNumber'))];
    final named = findAnimalMention(question, cows) ?? _animalId;
    final cow = animals.where((a) => a.id == named).firstOrNull;
    if (mounted) setState(() => _animalId = named);
    final names = nameLabels(
      animals: [for (final a in animals) (name: a.str('name'), tagNumber: a.str('tagNumber'))],
      people: [ctx.byName],
      places: [ctx.farmName],
    );
    final calc = ask(question, farm.data, role: ctx.role, cfg: farm.config);
    final calcText = calc.ok ? [calc.text, ...calc.bullets.map((b) => '- $b')].join('\n') : null;
    int ms() => context.clock.now().difference(started).inMilliseconds;

    void finish(_Turn t) {
      if (!mounted) return;
      setState(() {
        _turns.add(t);
        _busy = false;
      });
      _toEnd();
    }

    void offline(String note) {
      unawaited(ctx.repo.log('assistant', ok: calc.ok, ms: ms(), method: calc.method));
      final shown = calc.ok ? calc.text : '$note\n\n${l10n.aiChatOfflineHelp}';
      final bullets = calc.ok ? calc.bullets.map((b) => '- $b').toList() : <String>[];
      finish(
        _Turn(
          fromUser: false,
          text: [shown, ...bullets].join('\n'),
          method: calc.method,
          about: cow == null ? null : animalName(cow),
          note: calc.ok ? note : null,
        ),
      );
    }

    final limit = photoAllowed(farm.chatUsedToday, enabled: farm.config.photoEnabled, perFarmPerDay: farm.config.photoPerFarmPerDay);
    final analyzer = ctx.chat;
    if (analyzer == null || !farm.config.photoEnabled || !limit.ok) {
      final why = !farm.config.photoEnabled || analyzer == null ? l10n.aiChatNotOn : l10n.aiChatOffLimit;
      offline(sent.isEmpty ? why : '$why ${l10n.aiChatFilesNotRead}');
      return;
    }
    try {
      final facts = cow == null
          ? <String>[]
          : animalFacts(
              animalHealth(farm.data, cow.id),
              sex: cow.str('sex'),
              dairyStatus: cow.str('dairyStatus'),
              dateOfBirth: cow.str('dateOfBirth'),
              day: today(farm.data),
            );
      final prompt = buildChatPrompt(
        message: redact(question, names),
        facts: facts,
        calculated: calcText == null ? null : redact(calcText, names),
        fileKinds: [for (final f in sent) f.kind],
      );
      final recent = _turns.length > 1 ? _turns.sublist(0, _turns.length - 1) : <_Turn>[];
      final history = [
        for (final t in recent.skip(recent.length > 8 ? recent.length - 8 : 0))
          if (t.text.isNotEmpty) ChatTurn(t.fromUser, redact(t.text, names)),
      ];
      final raw = await analyzer.ask(
        system: chatSystem,
        history: history,
        prompt: prompt,
        files: [for (final f in sent) ChatPart(f.mime, f.bytes)],
        model: farm.config.photoModel,
      );
      final reply = readChatReply(raw, question);
      final shown = restore(reply.text, names);
      unawaited(ctx.repo.log('chat', ok: true, ms: ms(), method: Method.model));
      var saved = false;
      if (cow != null) {
        try {
          await ctx.repo.savePhotoAssessment(
            chatAssessmentBody(
              cow.id,
              question,
              ChatReply(
                text: shown,
                removed: reply.removed,
                health: reply.health,
                risk: reply.risk,
                callVet: reply.callVet,
                report: reply.report,
              ),
              {for (final f in sent) f.kind}.toList(),
              farm.config.photoModel,
              ctx.repo.nowIso,
            ),
          );
          saved = true;
        } on Object {
          saved = false;
        }
      }
      finish(
        _Turn(
          fromUser: false,
          text: shown,
          method: Method.model,
          about: cow == null ? null : animalName(cow),
          saved: saved,
          note: reply.removed > 0 ? l10n.aiChatMedsLeftOut : null,
        ),
      );
    } on Object catch (e) {
      unawaited(ctx.repo.log('chat', ok: false, ms: ms(), method: Method.model));
      final why = switch (photoFailureOf(e)) {
        PhotoFailure.network => l10n.aiPhotoErrNetwork,
        PhotoFailure.busy => l10n.aiPhotoErrBusy,
        PhotoFailure.appCheck => l10n.aiPhotoErrAppCheck,
        PhotoFailure.unreadable => l10n.aiPhotoErrRead,
      };
      offline(sent.isEmpty ? why : '$why ${l10n.aiChatFilesNotRead}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farm = _farm;
    final animals = farm == null ? <Rec>[] : alive(farm.data.animals).where(isActive).toList();
    final about = animals.where((a) => a.id == _animalId).firstOrNull;
    return AdaptiveScaffold(
      title: l10n.aiChatTitle,
      showBack: true,
      padBody: false,
      scrollable: false,
      actions: [
        if (_turns.isNotEmpty)
          IconButton(
            tooltip: l10n.aiChatNew,
            icon: const Icon(Symbols.edit_square_rounded),
            onPressed: () => setState(() {
              _turns.clear();
              _files.clear();
              _problem = null;
            }),
          ),
        IconButton(
          tooltip: l10n.aiChatTools,
          icon: const Icon(Symbols.apps_rounded),
          onPressed: () => widget.ctx.onModule('tools'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _turns.isEmpty
                ? Center(
                    child: Padding(
                      padding: context.space.screen,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconBubble(
                            icon: Symbols.auto_awesome_rounded,
                            tone: FarmTapTone.primary,
                            size: context.sizes.bubbleMd,
                          ),
                          context.space.gapMd,
                          Text(l10n.aiChatEmpty, style: context.text.titleLarge, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    controller: _scroll,
                    padding: context.space.screen,
                    children: [
                      for (final t in _turns) ...[_Bubble(turn: t, l10n: l10n), context.space.gapLg],
                      if (_busy)
                        Row(
                          children: [
                            Icon(Symbols.auto_awesome_rounded, color: context.colors.primary),
                            context.space.gapSm,
                            Text(
                              l10n.aiChatThinking,
                              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: context.space.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (about != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InputChip(
                      label: Text(l10n.aiChatAbout(animalName(about))),
                      onDeleted: () => setState(() => _animalId = null),
                    ),
                  ),
                if (_problem != null) ...[
                  AiNote(_problem!, icon: Symbols.warning_rounded, tone: FarmTapTone.warning),
                  context.space.gapXs,
                ],
                if (_files.isNotEmpty)
                  Wrap(
                    spacing: context.space.sm,
                    children: [
                      for (var i = 0; i < _files.length; i++)
                        InputChip(
                          avatar: _files[i].kind == 'photo'
                              ? ClipOval(child: Image.memory(_files[i].bytes, fit: BoxFit.cover))
                              : const Icon(Symbols.videocam_rounded),
                          label: Text(_files[i].name, overflow: TextOverflow.ellipsis),
                          onDeleted: () => setState(() => _files.removeAt(i)),
                        ),
                    ],
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton.filledTonal(
                      tooltip: l10n.aiChatAttach,
                      icon: const Icon(Symbols.add_rounded),
                      onPressed: _busy ? null : () => unawaited(_attachSheet(l10n)),
                    ),
                    context.space.gapSm,
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 2000,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(hintText: l10n.aiChatHint, counterText: ''),
                      ),
                    ),
                    context.space.gapSm,
                    IconButton.filled(
                      tooltip: l10n.aiChatSend,
                      icon: const Icon(Symbols.arrow_upward_rounded),
                      onPressed: _busy ? null : () => unawaited(_send(l10n)),
                    ),
                  ],
                ),
                context.space.gapXs,
                Text(
                  l10n.aiChatDisclaimer,
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const new({required this.turn, required this.l10n});

  final _Turn turn;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = turn;
    if (t.fromUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: context.radii.card,
            ),
            child: Padding(
              padding: context.space.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.files.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.space.xs),
                      child: Wrap(
                        spacing: context.space.xs,
                        runSpacing: context.space.xs,
                        children: [
                          for (final f in t.files)
                            if (f.kind == 'photo')
                              ClipRRect(
                                borderRadius: context.radii.chip,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints.tightFor(
                                    width: context.sizes.bubbleMd * 2,
                                    height: context.sizes.bubbleMd * 2,
                                  ),
                                  child: Image.memory(f.bytes, fit: BoxFit.cover),
                                ),
                              )
                            else
                              Chip(avatar: const Icon(Symbols.videocam_rounded), label: Text(f.name)),
                        ],
                      ),
                    ),
                  Text(t.text, style: context.text.bodyLarge?.copyWith(color: context.colors.onPrimaryContainer)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChatText(t.text),
        context.space.gapSm,
        Wrap(
          spacing: context.space.sm,
          runSpacing: context.space.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (t.method != null) MethodBadge(t.method!),
            if (t.saved) AiNote(l10n.aiChatSavedTo(t.about ?? ''), icon: Symbols.check_circle_rounded, tone: FarmTapTone.success),
            if (t.note != null)
              Text(t.note!, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

/// Plain-text answers shown the way a chat shows them: paragraphs, lists and **bold**.
class _ChatText extends StatelessWidget {
  const new(this.text);

  final String text;

  List<InlineSpan> _inline(BuildContext context, String t) {
    final out = <InlineSpan>[];
    final parts = t.split(RegExp(r'(\*\*[^*]+\*\*)'));
    for (final p in parts) {
      if (p.length > 4 && p.startsWith('**') && p.endsWith('**')) {
        out.add(
          TextSpan(
            text: p.substring(2, p.length - 2),
            style: context.text.bodyLarge?.copyWith(fontWeight: FarmTapWeights.semiBold),
          ),
        );
      } else {
        out.add(TextSpan(text: p));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final bullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(line);
      final number = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(line);
      final head = RegExp(r'^#{1,4}\s+(.*)$').firstMatch(line);
      final lead = bullet != null ? '•  ' : (number != null ? '${number.group(1)}.  ' : null);
      final body = bullet?.group(1) ?? number?.group(2) ?? head?.group(1) ?? line;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: context.space.xs),
          child: Text.rich(
            TextSpan(
              style: context.text.bodyLarge?.copyWith(fontWeight: head != null ? FarmTapWeights.semiBold : null),
              children: [if (lead != null) TextSpan(text: lead), ..._inline(context, body)],
            ),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}
