import 'package:flutter/material.dart';
import 'package:love_to_learn_sign/widgets/fullscreen_video_player.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'l10n/dynamic_l10n.dart';
import 'package:love_to_learn_sign/widgets/video_controls.dart';
import 'theme.dart';

class QuizVideoPage extends StatefulWidget {
  final String title;
  final int currentQuestion;
  final int maxQuestions;
  final int score;
  final String questionText;
  final VideoPlayerController controller;
  final double currentSpeed;
  final List<double> speeds;
  final List<String> options;
  final String correctAnswer;
  final int? selectedIndex;
  final bool answered;
  final bool isCorrect;
  final VoidCallback checkAnswer;
  final VoidCallback nextQuestion;
  final Function(int?) selectAnswer;
  final VoidCallback changeSpeed;
  final VoidCallback togglePlayPause;
  final VoidCallback onTimeExpired;
  final bool reviewedMode;
  final bool isReviewPass;
  final bool speedMode;
  final int timeLimit;
  final bool showNextButton;

  const QuizVideoPage({
    super.key,
    required this.title,
    required this.currentQuestion,
    required this.maxQuestions,
    required this.score,
    required this.questionText,
    required this.controller,
    required this.currentSpeed,
    required this.speeds,
    required this.options,
    required this.correctAnswer,
    required this.selectedIndex,
    required this.answered,
    required this.isCorrect,
    required this.checkAnswer,
    required this.nextQuestion,
    required this.selectAnswer,
    required this.changeSpeed,
    required this.togglePlayPause,
    required this.onTimeExpired,
    this.reviewedMode = false,
    this.isReviewPass = false,
    this.speedMode = false,
    this.timeLimit = 10,
    this.showNextButton = false,
  });

  @override
  _QuizVideoPageState createState() => _QuizVideoPageState();
}

class _QuizVideoPageState extends State<QuizVideoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  // Note : _bounceAnimation n'était pas utilisé, je le laisse au cas où.
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _tadaScaleAnimation;
  late final Animation<double> _tadaRotationAnimation;
  bool _answered = false;
  bool _isCorrect = false;
  Timer? _timer;
  int _remainingTime = 0;
  String _timeUpMessage = '';
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 800), // Durée un peu plus longue pour l'effet Tada
    );

    // Animation de rebond originale (non utilisée pour le Tada)
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    // ==================== CORRECTION APPLIQUÉE ICI ====================
    // 1. Créer une animation avec une courbe simple qui ne dépasse pas les bornes [0, 1].
    final CurvedAnimation tadaAnimation = CurvedAnimation(
      parent: _bounceController,
      curve:
          Curves.linear, // Utiliser une courbe simple comme linear ou easeOut.
    );

    // 2. Appliquer cette animation simple aux TweenSequences.
    _tadaScaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.2), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.2), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 10),
    ]).animate(tadaAnimation); // Utilisation de l'animation corrigée

    _tadaRotationAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 10),
    ]).animate(tadaAnimation); // Utilisation de l'animation corrigée
    // =================================================================

    // initialize from widget props
    _answered = widget.answered;
    _isCorrect = widget.isCorrect;
    if (widget.speedMode) {
      _startTimer();
    }
  }

  void _expireTime() {
    if (!mounted) return;
    if (_hasExpired) return;
    if (_answered) return;

    _hasExpired = true;
    _timer?.cancel();
    setState(() {
      _answered = true;
      _isCorrect = false;
      _timeUpMessage = S.of(context)!.timeUpMessage;
    });
    widget.onTimeExpired();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingTime = widget.timeLimit;
    _timeUpMessage = '';
    _hasExpired = false;

    // Defensive: if a bad value ever comes through, treat it as an immediate timeout.
    if (_remainingTime <= 0) {
      // Defer so we don't call setState synchronously during initState.
      WidgetsBinding.instance.addPostFrameCallback((_) => _expireTime());
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // If the user already answered, stop the countdown for this question.
      if (_answered) {
        timer.cancel();
        return;
      }
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _expireTime();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... Le reste de votre code reste inchangé ...
    final bool isReviewQuestion = widget.reviewedMode && widget.isReviewPass;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isReviewQuestion)
                Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(Icons.history,
                        color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 6),
                        Text(
                      '${widget.currentQuestion}/${widget.maxQuestions}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                        ),
                      ],
                    )
              else
                Text(
                  S.of(context)!.questionProgress(
                      '${widget.currentQuestion}', '${widget.maxQuestions}'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                    ),
              const SizedBox(height: 4),
              if (!isReviewQuestion)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: widget.currentQuestion / widget.maxQuestions,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.secondary,
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Builder(
                  builder: (context) {
                    final double width = 330.0;
                    final double height = 400.0;
                    return Container(
                      width: width,
                      height: height,
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface2,
                        borderRadius: BorderRadius.circular(10),
                    ),
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                            Positioned.fill(
                              child: widget.controller.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio:
                                          widget.controller.value.aspectRatio,
                                      child: VideoPlayer(
                                        key: ValueKey(widget.controller),
                                        widget.controller,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                        Positioned(
                          top: 8,
                              right: 8,
                          child: IconButton(
                                icon: Icon(
                                  Icons.fullscreen,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.8),
                                  size: 30,
                                ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                      builder: (context) =>
                                          FullscreenVideoPlayer(
                                    controller: widget.controller,
                                    wordId: '',
                                    showShareButton: false,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        VideoControls(
                          controller: widget.controller,
                          currentSpeed: widget.currentSpeed,
                          changeSpeed: widget.changeSpeed,
                          togglePlayPause: widget.togglePlayPause,
                        ),
                        if (widget.speedMode)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_remainingTime s',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onError,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_timeUpMessage.isNotEmpty)
                Text(
                  _timeUpMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                widget.questionText,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: List.generate(widget.options.length, (index) {
                  final isSelected = widget.selectedIndex == index;
                  final isRight = widget.options[index] == widget.correctAnswer;
                  final Color color;
                  if (_answered) {
                    color = isRight
                        ? Theme.of(context).colorScheme.correct
                        : (isSelected
                            ? Theme.of(context).colorScheme.wrong
                            : Theme.of(context).scaffoldBackgroundColor);
                  } else {
                    color = isSelected
                        ? Theme.of(context).colorScheme.surface2
                        : Theme.of(context).scaffoldBackgroundColor;
                  }

                  Widget button = GestureDetector(
                    onTap: _answered ? null : () => widget.selectAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSurface2
                              : Theme.of(context).colorScheme.onSurface2,
                          width: (_answered ? 2 : (isSelected ? 2 : 1)),
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 1,
                            spreadRadius: 2,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_answered)
                            if (isRight)
                              Icon(Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 26)
                            else if (isSelected)
                              Icon(Icons.cancel,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 26),
                          if (_answered && (isRight || isSelected))
                            const SizedBox(width: 8),
                          Text(
                            translateCategory(context, widget.options[index]),
                            style: TextStyle(
                              color: _answered
                                  ? Theme.of(context).colorScheme.primary
                                  : (isSelected
                                  ? Theme.of(context).colorScheme.onSurface2
                                  : Theme.of(context).colorScheme.primary),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (_answered && isRight) {
                    button = AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _tadaRotationAnimation.value,
                          child: Transform.scale(
                            scale: _tadaScaleAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: button,
                    );
                  }
                  return button;
                }),
              ),
              const SizedBox(height: 16),
              if (!_answered)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface2,
                  ),
                  onPressed: () {
                    if (widget.selectedIndex == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          content: Row(
                            children: [
                              Icon(Icons.cancel,
                                  color:
                                      Theme.of(context).colorScheme.onSurface2),
                              const SizedBox(width: 8),
                      Text(
                           S.of(context)!.selectAnswerFirst,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface2),
                              ),
                            ],
                          ),
                        ),
                      );
                      return;
                    }
                    final bool correct =
                        widget.options[widget.selectedIndex!] ==
                            widget.correctAnswer;
                    
                    setState(() {
                      _answered = true;
                      _isCorrect = correct;
                    });
                    _timer?.cancel();

                    // Always start the animation controller after an answer
                    _bounceController.forward(from: 0);

                    // checkAnswer() in quiz_page.dart will play the sounds
                    widget.checkAnswer();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                         S.of(context)!.submit,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface2,
                            fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.check,
                          color: Theme.of(context).colorScheme.onSurface2,
                          size: 26),
                    ],
                  ),
                )
              else if (_timeUpMessage.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface2,
                        ),
                        onPressed: () {
                          _timer?.cancel();
                          // nextQuestion() in quiz_page.dart will play the sound
                          widget.nextQuestion();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Text(
                                S.of(context)!.next,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface2,
                                      fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward,
                                color: Theme.of(context).colorScheme.onSurface2,
                                size: 26),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else if (widget.showNextButton)
                Column(
                  children: [
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface2,
                        ),
                        onPressed: () {
                          _timer?.cancel();
                          // nextQuestion() in quiz_page.dart will play the sound
                          widget.nextQuestion();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Text(
                             S.of(context)!.next,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface2,
                                      fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward,
                                color: Theme.of(context).colorScheme.onSurface2,
                                size: 26),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
