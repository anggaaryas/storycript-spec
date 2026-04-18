import 'package:flutter/material.dart';
import 'package:storyscript_player_core/storyscript_player_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF175C8A)),
        useMaterial3: true,
      ),
      home: const StoryScriptViewerPage(),
    );
  }
}

class StoryScriptViewerPage extends StatefulWidget {
  const StoryScriptViewerPage({super.key});

  @override
  State<StoryScriptViewerPage> createState() => _StoryScriptViewerPageState();
}

class _StoryScriptViewerPageState extends State<StoryScriptViewerPage> {
  final TextEditingController _pathController = TextEditingController(
    text: '',
  );

  BigInt? _sessionId;
  BridgeState? _state;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    final sessionId = _sessionId;
    if (sessionId != null) {
      playerClose(sessionId: sessionId);
    }
    _pathController.dispose();
    super.dispose();
  }

  void _setBusy(bool value) {
    if (mounted) {
      setState(() {
        _busy = value;
      });
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
      });
    }
  }

  void _clearError() {
    if (mounted) {
      setState(() {
        _error = null;
      });
    }
  }

  void _loadStory() {
    _setBusy(true);
    _clearError();
    try {
      final oldSession = _sessionId;
      if (oldSession != null) {
        playerClose(sessionId: oldSession);
      }

      final newSession = playerOpenRaw(source: _pathController.text.trim());
      final nextState = playerGetState(sessionId: newSession);

      if (!mounted) {
        return;
      }
      setState(() {
        _sessionId = newSession;
        _state = nextState;
      });
    } catch (err) {
      _setError('Failed to open story: $err');
    } finally {
      _setBusy(false);
    }
  }

  void _advance() {
    final sessionId = _sessionId;
    if (sessionId == null) {
      _setError('Open a story first.');
      return;
    }

    _setBusy(true);
    _clearError();
    try {
      final nextState = playerAdvance(sessionId: sessionId);
      if (!mounted) {
        return;
      }
      setState(() {
        _state = nextState;
      });
    } catch (err) {
      _setError('Failed to advance story: $err');
    } finally {
      _setBusy(false);
    }
  }

  void _choose(int index) {
    final sessionId = _sessionId;
    if (sessionId == null) {
      _setError('Open a story first.');
      return;
    }

    _setBusy(true);
    _clearError();
    try {
      final nextState = playerChoose(sessionId: sessionId, index: index);
      if (!mounted) {
        return;
      }
      setState(() {
        _state = nextState;
      });
    } catch (err) {
      _setError('Failed to choose option: $err');
    } finally {
      _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final current = state?.current;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StoryScript Viewer'),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5FAFF), Color(0xFFE7F2FC), Color(0xFFF8FBF2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildControls(state),
                const SizedBox(height: 12),
                if (_error != null) _buildErrorBanner(_error!),
                if (_error != null) const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildCurrentPanel(state, current),
                      ),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildHistoryPanel(state)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BridgeState? state) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.85),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'StoryScript file path',
                hintText:
                    '../../example/showcase_crescent_moon_bookshop.StoryScript',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _loadStory,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Story'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy || state == null || state.finished
                      ? null
                      : _advance,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Advance'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _loadStory,
                  icon: const Icon(Icons.replay),
                  label: const Text('Restart'),
                ),
                if (_busy) const CircularProgressIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPanel(BridgeState? state, BridgeStep? current) {
    if (state == null) {
      return _panel(
        title: 'Current Scene',
        child: const Center(
          child: Text('Open a StoryScript file to start viewing steps.'),
        ),
      );
    }

    final variables = state.variables;
    final choices = current?.choices ?? const <BridgeChoice>[];

    return _panel(
      title: 'Current Scene',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Script', state.scriptName),
            _infoRow('Scene', state.scene),
            _infoRow('Status', state.finished ? 'Finished' : 'Running'),
            _infoRow('Step Kind', current?.kind ?? '-'),
            if ((current?.actorName ?? '').isNotEmpty)
              _infoRow('Actor', current!.actorName!),
            if ((current?.emotion ?? '').isNotEmpty)
              _infoRow('Emotion', current!.emotion!),
            const SizedBox(height: 10),
            Text(
              current?.text ?? 'No current text at this step.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Choices', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (choices.isEmpty)
              const Text('No choices available at this step.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < choices.length; i++)
                    FilledButton.tonal(
                      onPressed: _busy || state.finished
                          ? null
                          : () => _choose(i),
                      child: Text('${i + 1}. ${choices[i].text}'),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text('Variables', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (variables.isEmpty)
              const Text('No variables in state.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final variable in variables)
                    Chip(label: Text('${variable.name}: ${variable.value}')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel(BridgeState? state) {
    final history = state?.history ?? const <BridgeStep>[];

    return _panel(
      title: 'History (${history.length})',
      child: history.isEmpty
          ? const Center(child: Text('No history yet.'))
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final step = history[index];
                final text = step.text ?? '';
                final actor = step.actorName;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    actor == null || actor.isEmpty
                        ? step.kind
                        : '$actor • ${step.kind}',
                  ),
                  subtitle: Text(
                    text.isEmpty ? '-' : text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Card(
      color: const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB71C1C)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFB71C1C)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.84),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
