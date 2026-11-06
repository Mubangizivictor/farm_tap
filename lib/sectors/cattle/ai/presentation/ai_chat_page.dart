// FarmTap AI chat (decision 0027): one box. Type a question, attach photos
// or a video with the plus, and get an answer. Online, Google Gemini answers
// with FarmTap's facts about the cow that was named; offline (or when it is
// switched off) the built-in assistant answers simple farm questions from the
// records. An answer about a named cow is saved to that cow's health history.
// Photos and videos are held in memory for the one question and never stored.
import 'dart:async';
import 'dart:convert';

import 'package:farm_tap/core/ai/ai_chat.dart';
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_herd.dart';
import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:farm_tap/core/ai/ai_privacy.dart';
import 'package:farm_tap/core/ai/ai_quota.dart';
import 'package:farm_tap/core/ai/ai_repository.dart';
import 'package:farm_tap/core/ai/ai_route.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_chat_cards.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_usage_widgets.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
    this.asked,
    this.detail,
    this.actions = const [],
    this.followUps = const [],
    this.grounding,
    this.triage,
    this.animalId,
    this.hadMedia = false,
    this.layer,
    this.errorKind,
  });

  factory fromJson(Map<String, dynamic> j) => _Turn(
    fromUser: j['fromUser'] == true,
    text: '${j['text'] ?? ''}',
    method: Method.values.where((m) => m.name == j['method']).firstOrNull,
    about: j['about'] as String?,
    saved: j['saved'] == true,
    note: j['note'] as String?,
    asked: j['asked'] as String?,
    detail: j['detail'] as String?,
    actions: [
      for (final dynamic a in (j['actions'] as List<dynamic>? ?? const <dynamic>[]))
        ChatAction('${(a as Map<String, dynamic>)['label']}', '${a['href']}'),
    ],
    followUps: [for (final dynamic f in (j['followUps'] as List<dynamic>? ?? const <dynamic>[])) '$f'],
    animalId: j['animalId'] as String?,
    hadMedia: j['hadMedia'] == true,
    layer: Layer.values.where((x) => x.name == j['layer']).firstOrNull,
    errorKind: aiErrorKindOf(j['errorKind']),
    triage: j['triage'] == null
        ? null
        : Triage(
            level: '${(j['triage'] as Map<String, dynamic>)['level']}',
            label: '${(j['triage'] as Map<String, dynamic>)['label']}',
            doNow: [for (final dynamic d in ((j['triage'] as Map<String, dynamic>)['doNow'] as List<dynamic>)) '$d'],
            report: (j['triage'] as Map<String, dynamic>)['report'] == true,
          ),
    grounding: j['grounding'] == null
        ? null
        : ChatGrounding(
            queries: [
              for (final dynamic q in ((j['grounding'] as Map<String, dynamic>)['queries'] as List<dynamic>)) '$q',
            ],
            sources: [
              for (final dynamic s in ((j['grounding'] as Map<String, dynamic>)['sources'] as List<dynamic>))
                ChatSource('${(s as Map<String, dynamic>)['title']}', '${s['uri']}'),
            ],
            suggestionsHtml: (j['grounding'] as Map<String, dynamic>)['html'] as String?,
          ),
  );

  final bool fromUser;
  final String text;
  final List<_Attached> files;
  final Method? method;
  final String? about;
  final bool saved;
  final String? note;

  /// The question this answer replied to.
  final String? asked;

  /// The real reason an online answer failed, for the Details line.
  final String? detail;
  final List<ChatAction> actions;
  final List<String> followUps;
  final ChatGrounding? grounding;

  /// Urgency card for a sick-animal answer.
  final Triage? triage;

  /// The animal this answer is about.
  final String? animalId;

  /// A photo or video was sent with the question.
  final bool hadMedia;

  /// Which layer answered (decision 0028): records and insight are calculated, ai is a model.
  final Layer? layer;

  /// Why the AI did not answer (a banner above the built-in answer).
  final AiErrorKind? errorKind;

  /// Files are never saved.
  Map<String, dynamic> toJson() => {
    'fromUser': fromUser,
    'text': text,
    'method': method?.name,
    'about': about,
    'saved': saved,
    'note': note,
    'asked': asked,
    'detail': detail,
    'actions': [
      for (final a in actions) {'label': a.label, 'href': a.href},
    ],
    'followUps': followUps,
    'animalId': animalId,
    'hadMedia': hadMedia,
    'layer': layer?.name,
    'errorKind': errorKind?.name,
    'triage': triage == null
        ? null
        : {'level': triage!.level, 'label': triage!.label, 'doNow': triage!.doNow, 'report': triage!.report},
    'grounding': grounding == null
        ? null
        : {
            'queries': grounding!.queries,
            'sources': [
              for (final s in grounding!.sources) {'title': s.title, 'uri': s.uri},
            ],
            'html': grounding!.suggestionsHtml,
          },
  };
}

/// One saved chat in the list behind "Chats" (kept on this phone only).
class _SavedChat {
  const new({required this.id, required this.title, required this.updatedAt, required this.turns});

  factory fromJson(Map<String, dynamic> j) => _SavedChat(
    id: '${j['id']}',
    title: '${j['title']}',
    updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
    turns: [
      for (final dynamic t in (j['turns'] as List<dynamic>? ?? const <dynamic>[]))
        _Turn.fromJson(t as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final int updatedAt;
  final List<_Turn> turns;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt,
    'turns': [for (final t in turns) t.toJson()],
  };
}

const _chatsKey = 'farmtap.ai.chats';
const _maxChats = 40;

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

  /// What the busy row says ("Checking your farm records...", "Preparing your AI response...").
  String _working = '';

  /// The server's count of today's AI answers (server route only).
  UsageView? _serverUsage;
  String? _problem;
  String _chatId = '';
  List<_SavedChat> _chats = [];
  SharedPreferences? _prefs;
  Map<String, String> _case = {};
  String _lang = 'auto';
  final _skipPick = <_Turn>{};

  @override
  void initState() {
    super.initState();
    unawaited(_reload().then((_) => _loadUsage()));
    unawaited(_loadChats());
  }

  Future<void> _loadUsage() async {
    final server = widget.ctx.server;
    if (server == null || widget.ctx.tenantId.isEmpty) return;
    final a = _farm?.config.assistant;
    if (a == null || a.route != 'server' || !a.enabled) return;
    final u = await server.usage(widget.ctx.tenantId);
    if (mounted && u != null) setState(() => _serverUsage = u);
  }

  /// Today's allowance: the server's own count on the server route, else counted from this farm's AI log.
  UsageView? _usage(AiFarm? farm) {
    if (farm == null) return null;
    final a = farm.config.assistant;
    if (!a.enabled) return null;
    return a.route == 'server' ? _serverUsage : usageView(farm.chatUsedToday, a.dailyLimit, a.warnPct);
  }

  Future<void> _loadChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _lang = prefs.getString('farmtap.ai.lang') ?? 'auto';
      final raw = prefs.getString(_chatsKey);
      if (raw == null) return;
      final list = [
        for (final dynamic c in jsonDecode(raw) as List<dynamic>) _SavedChat.fromJson(c as Map<String, dynamic>),
      ];
      if (mounted) setState(() => _chats = list);
    } on Object {
      // Saved chats could not be read: start with none.
    }
  }

  void _saveChat() {
    if (_turns.isEmpty) return;
    final now = context.clock.now().millisecondsSinceEpoch;
    if (_chatId.isEmpty) _chatId = '$now';
    final first = _turns.where((t) => t.fromUser).firstOrNull;
    final keep = _turns.length > 60 ? _turns.sublist(_turns.length - 60) : List<_Turn>.of(_turns);
    final chat = _SavedChat(id: _chatId, title: chatTitle(first?.text ?? ''), updatedAt: now, turns: keep);
    final next = [chat, ..._chats.where((c) => c.id != chat.id)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _chats = next.take(_maxChats).toList();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setString(_chatsKey, jsonEncode([for (final c in _chats) c.toJson()]));
    } on Object {
      // Not kept: the chat still works.
    }
  }

  void _newChat() {
    setState(() {
      _turns.clear();
      _files.clear();
      _problem = null;
      _busy = false;
      _chatId = '';
      _case = {};
    });
  }

  void _openChat(_SavedChat c) {
    setState(() {
      _turns
        ..clear()
        ..addAll(c.turns);
      _files.clear();
      _problem = null;
      _chatId = c.id;
      _case = {};
    });
    _toEnd();
  }

  void _removeChat(_SavedChat c) {
    setState(() => _chats = _chats.where((x) => x.id != c.id).toList());
    if (c.id == _chatId) _newChat();
    unawaited(_persist());
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
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
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
          picked.addAll(await picker.pickMultiImage(maxWidth: photoMaxSide.toDouble(), imageQuality: 82));
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

  Future<void> _send(AppLocalizations l10n, {String? say}) async {
    final typed = (say ?? _text.text).trim();
    if ((typed.isEmpty && (say != null || _files.isEmpty)) || _busy) return;
    final question = typed.isEmpty ? l10n.aiChatLookAtThis : typed;
    final sent = say != null ? <_Attached>[] : List<_Attached>.of(_files);
    final before = List<_Turn>.of(_turns);
    setState(() {
      if (say == null) _text.clear();
      _files.clear();
      _problem = null;
      _busy = true;
      _turns.add(_Turn(fromUser: true, text: question, files: sent));
    });
    _toEnd();
    await _answer(l10n, question, sent, before);
  }

  /// Asks the same question again and replaces the answer.
  Future<void> _again(AppLocalizations l10n, _Turn answer) async {
    if (_busy) return;
    final i = _turns.indexOf(answer);
    if (i < 1 || !_turns[i - 1].fromUser) return;
    final me = _turns[i - 1];
    final before = _turns.sublist(0, i - 1);
    setState(() {
      _turns.removeRange(i, _turns.length);
      _busy = true;
    });
    await _answer(l10n, me.text, me.files, List<_Turn>.of(before));
  }

  Future<void> _copy(AppLocalizations l10n, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.aiChatCopied)));
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Answers one question. [before] is every turn that came before it.
  /// Decision 0028: the question is classified first. Records and built-in
  /// insights answer at once (no AI, no allowance used); only questions that
  /// need reasoning, or carry a file, go to the AI.
  Future<void> _answer(AppLocalizations l10n, String question, List<_Attached> sent, List<_Turn> before) async {
    final started = context.clock.now();
    if (mounted) setState(() => _working = workingText(Layer.records));
    final farm = await _reload();
    if (!mounted) return;
    final ctx = widget.ctx;
    final asst = farm.config.assistant;
    final animals = alive(farm.data.animals).where(isActive).toList();
    final cows = [for (final a in animals) Mentionable(a.id, name: a.str('name'), tag: a.str('tagNumber'))];
    final named = findAnimalMention(question, cows) ?? _animalId;
    final cow = animals.where((a) => a.id == named).firstOrNull;
    if (mounted) setState(() => _animalId = named);
    final route = classify(
      question,
      farm.data,
      role: ctx.role,
      cfg: farm.config,
      files: sent.length,
      maxChars: asst.maxChars,
    );
    final calc = route.answer;
    final calcText = calc != null && calc.ok ? [calc.text, ...calc.bullets.map((b) => '- $b')].join('\n') : null;
    final animalRef = cow == null ? null : (id: cow.id, name: animalName(cow));
    int ms() => context.clock.now().difference(started).inMilliseconds;

    void finish(_Turn t) {
      if (!mounted) return;
      setState(() {
        _turns.add(t);
        _busy = false;
        _working = '';
      });
      _saveChat();
      _toEnd();
    }

    // Layers 1 and 2 (and the fallback when the AI does not answer).
    void builtIn({AiErrorKind? error, String? note}) {
      unawaited(ctx.repo.log('assistant', ok: calc?.ok ?? false, ms: ms(), method: calc?.method ?? Method.calculated));
      final body = calc == null ? l10n.aiChatOfflineHelp : [calc.text, ...calc.bullets.map((b) => '- $b')].join('\n');
      final actions = chatActions(question: question, answer: body, health: false, callVet: null, animal: animalRef);
      if (actions.isEmpty && calc != null && calc.links.isNotEmpty) {
        actions.add(ChatAction('Go to ${calc.links.first.label}', calc.links.first.href));
      }
      finish(
        _Turn(
          fromUser: false,
          text: body,
          method: calc?.method ?? Method.calculated,
          about: cow == null ? null : animalName(cow),
          note: note,
          asked: question,
          actions: actions,
          layer: route.layer == Layer.records ? Layer.records : Layer.insight,
          errorKind: error,
        ),
      );
    }

    if (route.reason == RouteReason.tooLong) {
      finish(
        _Turn(
          fromUser: false,
          text: 'Keep your question under ${asst.maxChars} characters.',
          method: Method.calculated,
          asked: question,
          layer: Layer.insight,
          errorKind: AiErrorKind.invalid,
        ),
      );
      return;
    }
    if (route.layer != Layer.ai) {
      builtIn();
      return;
    }
    final lost = sent.isEmpty ? null : l10n.aiChatFilesNotRead;
    final usage = _usage(farm);
    final server = asst.route == 'server' ? ctx.server : null;
    final analyzer = ctx.chat;
    final blocked = !asst.enabled || (asst.route == 'server' ? server == null : analyzer == null)
        ? AiErrorKind.disabled
        : usage != null && usage.level == UsageLevel.out
        ? AiErrorKind.limit
        : null;
    if (blocked != null) {
      builtIn(error: blocked, note: lost);
      return;
    }
    if (mounted) setState(() => _working = workingText(Layer.ai, model: true));
    final names = nameLabels(
      animals: [for (final a in animals) (name: a.str('name'), tagNumber: a.str('tagNumber'))],
      people: [ctx.byName],
      places: [ctx.farmName],
    );
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
      final search = needsSearch(question, calculated: calc?.ok ?? false);
      final message = redact(question, names);
      final calculated = calcText == null ? null : redact(calcText, names);
      final media = sent.any((f) => f.kind == 'photo' || f.kind == 'video');
      final history = [
        for (final h in chatHistory([
          for (final t in before)
            if (t.text.isNotEmpty && t.errorKind == null) (fromUser: t.fromUser, text: redact(t.text, names)),
        ]))
          ChatTurn(fromUser: h.fromUser, text: h.text),
      ];
      final String text;
      final ChatGrounding? grounding;
      final String model;
      if (server != null) {
        final r = await server.ask(
          ServerAsk(
            tenantId: ctx.tenantId,
            message: message,
            facts: facts,
            calculated: calculated,
            history: [for (final h in history) (role: h.fromUser ? 'user' : 'model', text: h.text)],
            files: [for (final f in sent) (mime: f.mime, base64: base64Encode(f.bytes))],
            language: _lang == 'auto' ? null : _lang,
            search: search,
          ),
          timeout: Duration(milliseconds: asst.timeoutMs), // theme-guard: ignore
        );
        if (mounted && r.usage != null) setState(() => _serverUsage = r.usage);
        text = r.text;
        model = r.model;
        grounding = _groundingFrom(r.grounding);
      } else {
        final got = await analyzer!.ask(
          system: chatSystem,
          history: history,
          prompt: buildChatPrompt(
            message: message,
            facts: facts,
            calculated: calculated,
            fileKinds: [for (final f in sent) f.kind],
            search: search,
            language: _lang,
          ),
          files: [for (final f in sent) ChatPart(f.mime, f.bytes)],
          models: chatModels(asst.model, hasMedia: media),
        );
        text = got.text;
        model = asst.model;
        grounding = got.grounding;
      }
      final reply = readChatReply(text, question);
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
              model,
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
          layer: Layer.ai,
          about: cow == null ? null : animalName(cow),
          saved: saved,
          note: reply.removed > 0 ? l10n.aiChatMedsLeftOut : null,
          asked: question,
          actions: chatActions(
            question: question,
            answer: shown,
            health: reply.health,
            callVet: reply.callVet,
            animal: animalRef,
          ),
          followUps: chatFollowUps(question: question, answer: shown, health: reply.health),
          triage: triageOf(
            ChatReply(
              text: shown,
              removed: reply.removed,
              health: reply.health,
              risk: reply.risk,
              callVet: reply.callVet,
              report: reply.report,
            ),
            question: question,
          ),
          animalId: cow?.id,
          hadMedia: media,
          grounding: grounding == null
              ? null
              : ChatGrounding(
                  queries: [for (final q in grounding.queries) restore(q, names)],
                  sources: grounding.sources,
                  suggestionsHtml: grounding.suggestionsHtml,
                ),
        ),
      );
    } on Object catch (e) {
      unawaited(ctx.repo.log('chat', ok: false, ms: ms(), method: Method.model));
      var kind = AiErrorKind.unavailable;
      if (e is AiRequestException) {
        kind = e.kind;
        if (mounted && e.usage != null) setState(() => _serverUsage = e.usage);
      } else if (e is ChatException) {
        kind = chatFailureKind(e.failure.name, e.detail);
        // For the FarmTap owner in the debug log only; farmers see the plain banner.
        debugPrint('[FarmTap AI] ${e.failure.name}: ${e.detail}');
      }
      builtIn(error: kind, note: lost);
    }
  }

  /// Google Search sources from the server's answer.
  ChatGrounding? _groundingFrom(Map<String, Object?>? g) {
    if (g == null) return null;
    final sources = g['sources'];
    final queries = g['queries'];
    return ChatGrounding(
      queries: [
        if (queries is List)
          for (final q in queries) '$q',
      ],
      sources: [
        if (sources is List)
          for (final s in sources)
            if (s is Map) ChatSource('${s['title'] ?? ''}', '${s['uri'] ?? ''}'),
      ],
      suggestionsHtml: g['suggestionsHtml'] as String?,
    );
  }

  Rec? _cowOf(_Turn t, List<Rec> animals) => animals.where((a) => a.id == t.animalId).firstOrNull;

  ({String id, String name})? _cowRef(_Turn t, List<Rec> animals) {
    final c = _cowOf(t, animals);
    return c == null ? null : (id: c.id, name: animalName(c));
  }

  String _today() => (_farm == null ? context.clock.now().toIso8601String() : today(_farm!.data)).substring(0, 10);

  List<ChatAction> _actsFor(_Turn t, List<Rec> animals) {
    if (t.method != Method.model) return t.actions;
    final cow = _cowRef(t, animals);
    return [
      ...chatDoActions(animal: cow, triage: t.triage, day: _today()),
      ...chatActions(
        question: t.asked ?? '',
        answer: t.text,
        health: t.triage != null,
        callVet: t.triage?.level,
        animal: cow,
      ),
    ];
  }

  String _messageOf(_Turn t, List<Rec> animals) {
    final cow = _cowOf(t, animals);
    final farm = _farm;
    final label = cow == null
        ? null
        : '${animalName(cow)}${cow.str('name') != null && cow.str('tagNumber') != null ? ' (${cow.str('tagNumber')})' : ''}';
    return vetSummary(
      farm: widget.ctx.farmName,
      animal: cow == null || farm == null
          ? null
          : (
              label: label!,
              facts: animalFacts(
                animalHealth(farm.data, cow.id),
                sex: cow.str('sex'),
                dairyStatus: cow.str('dairyStatus'),
                dateOfBirth: cow.str('dateOfBirth'),
                day: today(farm.data),
              ),
            ),
      question: t.asked ?? '',
      answer: t.text,
      answers: _case,
      triage: t.triage,
      hasPhoto: t.hadMedia,
      day: _today(),
    );
  }

  List<Widget> _cardsFor(_Turn t, AppLocalizations l10n, List<Rec> animals) {
    if (t.fromUser || t.method != Method.model) return const [];
    final isLast = identical(t, _turns.where((x) => !x.fromUser).lastOrNull);
    final i = _turns.indexOf(t);
    final photos = i > 0 ? _turns[i - 1].files.where((f) => f.kind == 'photo').toList() : const <_Attached>[];
    return [
      if (t.triage != null)
        TriageCard(
          triage: t.triage!,
          message: _messageOf(t, animals),
          vetName: null,
          onWhatsapp: () => unawaited(_whatsapp(null, _messageOf(t, animals))),
          onSharePhoto: photos.isEmpty ? null : () => unawaited(_sharePhotos(photos, _messageOf(t, animals))),
        ),
      if (t.animalId == null && (t.triage != null || t.hadMedia) && !_skipPick.contains(t))
        CowPicker(
          animals: [
            for (final a in animals)
              (
                id: a.id,
                label:
                    '${animalName(a)}${a.str('name') != null && a.str('tagNumber') != null ? ' (${a.str('tagNumber')})' : ''}',
              ),
          ],
          onPick: (id) => unawaited(_pickCow(t, id, animals, l10n)),
          onSkip: () => setState(() => _skipPick.add(t)),
        ),
      if (isLast && t.triage != null && !_busy)
        CaseCard(
          answers: _case,
          animalKnown: t.animalId != null,
          busy: _busy,
          onAnswer: (id, v) => setState(() => _case = {..._case, id: v}),
          onSend: () => unawaited(_send(l10n, say: 'More details about this animal. ${caseText(_case)}.')),
        ),
    ];
  }

  Future<void> _sharePhotos(List<_Attached> photos, String message) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          files: [for (final p in photos.take(3)) XFile.fromData(p.bytes, mimeType: p.mime, name: p.name)],
        ),
      );
    } on Object {
      // The farmer closed the share sheet.
    }
  }

  Future<void> _whatsapp(String? phone, String message) async {
    final link = whatsappLink(phone, message) ?? whatsappLink(null, message)!;
    await _open(link);
  }

  Future<void> _pickCow(_Turn t, String id, List<Rec> animals, AppLocalizations l10n) async {
    final cow = animals.where((a) => a.id == id).firstOrNull;
    if (cow == null) return;
    var saved = false;
    try {
      final i = _turns.indexOf(t);
      final me = i > 0 ? _turns[i - 1] : null;
      final tr = t.triage;
      await widget.ctx.repo.savePhotoAssessment(
        chatAssessmentBody(
          id,
          t.asked ?? '',
          ChatReply(
            text: t.text,
            removed: 0,
            health: tr != null,
            risk: tr?.level == 'now'
                ? Severity.critical
                : (tr?.level == 'today' ? Severity.high : (tr != null ? Severity.medium : Severity.low)),
            callVet: tr?.level,
            report: tr?.report ?? false,
          ),
          {for (final f in me?.files ?? const <_Attached>[]) f.kind}.toList(),
          _farm?.config.photoModel ?? '',
          widget.ctx.repo.nowIso,
        ),
      );
      saved = true;
    } on Object {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      final i = _turns.indexOf(t);
      if (i >= 0) {
        _turns[i] = _Turn(
          fromUser: false,
          text: t.text,
          method: t.method,
          about: animalName(cow),
          saved: saved,
          note: t.note,
          asked: t.asked,
          detail: t.detail,
          actions: t.actions,
          followUps: t.followUps,
          grounding: t.grounding,
          triage: t.triage,
          animalId: id,
          hadMedia: t.hadMedia,
        );
      }
    });
    _saveChat();
  }

  Future<void> _chatsSheet(AppLocalizations l10n) async {
    var find = '';
    await showAdaptiveSheet<void>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (_, setSheet) {
          final words = find.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
          final shown = [
            for (final c in _chats)
              if (words.every((w) => '${c.title}\n${c.turns.map((t) => t.text).join('\n')}'.toLowerCase().contains(w)))
                c,
          ];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(l10n.aiChatHistoryTitle, subtitle: l10n.aiChatKeptHere),
              sheet.space.gapMd,
              FilledButton.icon(
                icon: const Icon(Symbols.edit_square_rounded),
                label: Text(l10n.aiChatNew),
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _newChat();
                },
              ),
              sheet.space.gapSm,
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.aiChatSearch,
                  prefixIcon: const Icon(Symbols.search_rounded),
                ),
                onChanged: (v) => setSheet(() => find = v),
              ),
              sheet.space.gapSm,
              if (shown.isEmpty)
                Padding(
                  padding: EdgeInsets.all(sheet.space.md),
                  child: Text(
                    _chats.isEmpty ? l10n.aiChatNoChats : l10n.aiChatNoMatch,
                    style: sheet.text.bodyMedium?.copyWith(color: sheet.colors.onSurfaceVariant),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in shown)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          selected: c.id == _chatId,
                          title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            Navigator.of(sheet).pop();
                            _openChat(c);
                          },
                          trailing: IconButton(
                            tooltip: l10n.aiChatDeleteChat,
                            icon: const Icon(Symbols.delete_rounded),
                            onPressed: () {
                              _removeChat(c);
                              setSheet(() {});
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farm = _farm;
    final animals = farm == null ? <Rec>[] : alive(farm.data.animals).where(isActive).toList();
    final about = animals.where((a) => a.id == _animalId).firstOrNull;
    final usage = _usage(farm);
    final trusted = farm?.config.assistant.route == 'server';
    return AdaptiveScaffold(
      title: l10n.aiChatTitle,
      showBack: true,
      padBody: false,
      scrollable: false,
      actions: [
        if (usage != null)
          Tooltip(
            message: aiUsageTitle,
            child: ActionChip(
              avatar: const Icon(Symbols.auto_awesome_rounded),
              label: Text('${usage.used}/${usage.limit}'),
              onPressed: () => unawaited(
                showAdaptiveSheet<void>(
                  context,
                  builder: (sheet) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AiUsageMeter(view: usage, trusted: trusted),
                      sheet.space.gapMd,
                      Text(aiUsageFree, style: sheet.text.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: l10n.aiChatLanguage,
          icon: const Icon(Symbols.translate_rounded),
          initialValue: _lang,
          onSelected: (v) {
            setState(() => _lang = v);
            unawaited(_prefs?.setString('farmtap.ai.lang', v) ?? Future<bool>.value(false));
          },
          itemBuilder: (_) => [for (final l in chatLanguages) PopupMenuItem(value: l.id, child: Text(l.label))],
        ),
        IconButton(
          tooltip: l10n.aiChatHistory,
          icon: const Icon(Symbols.history_rounded),
          onPressed: () => unawaited(_chatsSheet(l10n)),
        ),
        if (_turns.isNotEmpty)
          IconButton(tooltip: l10n.aiChatNew, icon: const Icon(Symbols.edit_square_rounded), onPressed: _newChat),
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
                          IconBubble(icon: Symbols.auto_awesome_rounded, size: context.sizes.bubbleMd),
                          context.space.gapMd,
                          Text(l10n.aiChatEmpty, style: context.text.titleLarge, textAlign: TextAlign.center),
                          if (usage != null) ...[context.space.gapLg, AiUsageMeter(view: usage, trusted: trusted)],
                        ],
                      ),
                    ),
                  )
                : ListView(
                    controller: _scroll,
                    padding: context.space.screen,
                    children: [
                      for (final t in _turns) ...[
                        _Bubble(
                          turn: t,
                          l10n: l10n,
                          isLast: t == _turns.where((x) => !x.fromUser).lastOrNull,
                          busy: _busy,
                          onLink: widget.ctx.onLink,
                          onOpen: (url) => unawaited(_open(url)),
                          onCopy: () => unawaited(_copy(l10n, t.text)),
                          onAgain: () => unawaited(_again(l10n, t)),
                          onFollow: (q) => unawaited(_send(l10n, say: q)),
                          cards: _cardsFor(t, l10n, animals),
                          acts: _actsFor(t, animals),
                          aiLimit: usage?.limit ?? farm?.config.assistant.dailyLimit ?? 10,
                        ),
                        context.space.gapLg,
                      ],
                      if (_busy)
                        Row(
                          children: [
                            Icon(Symbols.auto_awesome_rounded, color: context.colors.primary),
                            context.space.gapSm,
                            Text(
                              _working.isEmpty ? l10n.aiChatThinking : _working,
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
                if (usage != null && usage.level != UsageLevel.ok) ...[
                  AiUsageWarning(view: usage),
                  context.space.gapXs,
                ],
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
  const new({
    required this.turn,
    required this.l10n,
    required this.isLast,
    required this.busy,
    required this.onLink,
    required this.onOpen,
    required this.onCopy,
    required this.onAgain,
    required this.onFollow,
    required this.cards,
    required this.acts,
    this.aiLimit = 10,
  });

  final _Turn turn;
  final AppLocalizations l10n;
  final bool isLast;
  final bool busy;
  final AiLinkOpener onLink;
  final void Function(String url) onOpen;
  final VoidCallback onCopy;
  final VoidCallback onAgain;
  final void Function(String question) onFollow;

  /// Today's AI allowance, for the "limit reached" banner.
  final int aiLimit;

  /// Triage, which-cow and vet-question cards for this answer.
  final List<Widget> cards;

  /// Buttons to other parts of FarmTap.
  final List<ChatAction> acts;

  @override
  Widget build(BuildContext context) {
    final t = turn;
    if (t.fromUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
          child: DecoratedBox(
            decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: context.radii.card),
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
        if (t.errorKind != null) ...[AiErrorBanner(kind: t.errorKind!, limit: aiLimit), context.space.gapSm],
        _ChatText(t.text),
        for (final c in cards) ...[context.space.gapSm, c],
        context.space.gapSm,
        Wrap(
          spacing: context.space.sm,
          runSpacing: context.space.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (t.method != null) MethodBadge(t.method!),
            if (t.layer != null)
              Text(
                layerLabel(t.layer!),
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            if (t.saved)
              AiNote(l10n.aiChatSavedTo(t.about ?? ''), icon: Symbols.check_circle_rounded, tone: FarmTapTone.success),
            if (t.note != null)
              Text(t.note!, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
        if (acts.isNotEmpty) ...[
          context.space.gapSm,
          Wrap(
            spacing: context.space.sm,
            runSpacing: context.space.xs,
            children: [
              for (final a in acts)
                ActionChip(
                  avatar: const Icon(Symbols.arrow_forward_rounded),
                  label: Text(a.label),
                  onPressed: () => onLink(a.href),
                ),
            ],
          ),
        ],
        if (t.grounding != null && t.grounding!.sources.isNotEmpty) ...[
          context.space.gapSm,
          Text(l10n.aiChatSources, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          Wrap(
            spacing: context.space.sm,
            runSpacing: context.space.xs,
            children: [
              for (final s in t.grounding!.sources)
                ActionChip(
                  avatar: const Icon(Symbols.link_rounded),
                  label: Text(s.title, overflow: TextOverflow.ellipsis),
                  onPressed: () => onOpen(s.uri),
                ),
            ],
          ),
        ],
        Row(
          children: [
            IconButton(tooltip: l10n.aiChatCopy, icon: const Icon(Symbols.content_copy_rounded), onPressed: onCopy),
            if (t.asked != null)
              IconButton(
                tooltip: l10n.aiChatAgain,
                icon: const Icon(Symbols.refresh_rounded),
                onPressed: busy ? null : onAgain,
              ),
          ],
        ),
        if (isLast && !busy && t.followUps.isNotEmpty)
          Wrap(
            spacing: context.space.sm,
            runSpacing: context.space.xs,
            children: [for (final f in t.followUps) ActionChip(label: Text(f), onPressed: () => onFollow(f))],
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
              children: [
                if (lead != null) TextSpan(text: lead),
                ..._inline(context, body),
              ],
            ),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}
