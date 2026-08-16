import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/app_colors.dart';

class VoiceGuideScreen extends StatefulWidget {
  final int? initialPlaceId;
  final String? initialPlaceName;

  const VoiceGuideScreen({
    super.key,
    this.initialPlaceId,
    this.initialPlaceName,
  });

  @override
  State<VoiceGuideScreen> createState() => _VoiceGuideScreenState();
}

class _VoiceGuideScreenState extends State<VoiceGuideScreen> {
  final TextEditingController questionController = TextEditingController();
  final FocusNode questionFocusNode = FocusNode();

  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speechToText = stt.SpeechToText();

  final Dio dio = Dio(
    BaseOptions(
      //baseUrl: 'http://192.168.100.248:8000',
     // baseUrl: 'http://10.0.2.2:8000',
     //mama
       baseUrl: 'http://192.168.100.246:8000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  final List<_PlaceOption> places = const [
    _PlaceOption(id: 1, name: 'Petra'),
    _PlaceOption(id: 2, name: 'Wadi Rum'),
    _PlaceOption(id: 3, name: 'Jerash'),
    _PlaceOption(id: 4, name: 'Dead Sea'),
  ];

  late int selectedPlaceId;
  bool isLoading = false;
  bool isListening = false;
  bool isSpeaking = false;
  bool speechAvailable = false;

  String selectedLanguage = 'English';
  String? answer;

  @override
  void initState() {
    selectedPlaceId = widget.initialPlaceId ?? 1;
    super.initState();

    _initializeSpeech();
    _initializeTextToSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() {
              isListening = false;
            });
          }
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            isListening = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Microphone error: ${error.errorMsg}',
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      setState(() {
        speechAvailable = available;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        speechAvailable = false;
      });
    }
  }

  Future<void> _initializeTextToSpeech() async {
    flutterTts.setStartHandler(() {
      if (!mounted) return;

      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((message) {
      if (!mounted) return;

      setState(() {
        isSpeaking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice error: $message'),
        ),
      );
    });
  }

  Future<void> startListening() async {
    FocusScope.of(context).unfocus();

    if (!speechAvailable) {
      await _initializeSpeech();
    }

    if (!speechAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is not available. Check microphone permission.',
          ),
        ),
      );
      return;
    }

    if (isSpeaking) {
      await stopSpeaking();
    }

    final localeId =
        selectedLanguage == 'Arabic' ? 'ar_SA' : 'en_US';

    setState(() {
      isListening = true;
    });

    await speechToText.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          questionController.text = result.recognizedWords;

          questionController.selection = TextSelection.fromPosition(
            TextPosition(
              offset: questionController.text.length,
            ),
          );
        });
      },
    );
  }

  Future<void> stopListening() async {
    await speechToText.stop();

    if (!mounted) return;

    setState(() {
      isListening = false;
    });
  }

  Future<void> speakAnswer() async {
    final text = answer?.trim();

    if (text == null || text.isEmpty) {
      return;
    }

    if (isListening) {
      await stopListening();
    }

    final languageCode =
        selectedLanguage == 'Arabic' ? 'ar-SA' : 'en-US';

    await flutterTts.setLanguage(languageCode);
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    if (!mounted) return;

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();

    if (!mounted) return;

    setState(() {
      isSpeaking = false;
    });
  }

  Future<void> askGuide() async {
    final question = questionController.text.trim();

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please type a question or use the microphone.',
          ),
        ),
      );
      return;
    }

    if (isListening) {
      await stopListening();
    }

    if (isSpeaking) {
      await stopSpeaking();
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      answer = null;
    });

    try {
      final response = await dio.post(
        '/guide/',
        data: {
  'place_id': selectedPlaceId,
  'question': question,
  'language': selectedLanguage,
},
      );

      if (!mounted) return;

      final data = response.data;

      if (data is Map && data['success'] == true) {
        final returnedAnswer =
            data['answer']?.toString() ??
            'No answer was returned.';

        setState(() {
          answer = returnedAnswer;
        });

        await speakAnswer();
      } else {
        final message = data is Map
            ? data['error']?.toString()
            : 'Failed to get an answer.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Failed to get an answer.',
            ),
          ),
        );
      }
    } on DioException catch (error) {
      if (!mounted) return;

      String message = 'Failed to connect to the voice guide.';

      if (error.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timed out.';
      } else if (error.type == DioExceptionType.connectionError) {
        message =
            'Make sure the backend is running.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        message =
            'The AI took too long to respond.';
      } else if (error.response != null) {
        message =
            'Server error: ${error.response?.statusCode}';
      } else if (error.message != null) {
        message = error.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void clearQuestion() {
    questionController.clear();
    questionFocusNode.requestFocus();

    setState(() {
      answer = null;
    });
  }

  @override
  void dispose() {
    questionController.dispose();
    questionFocusNode.dispose();

    speechToText.stop();
    flutterTts.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.sand,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.sand,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: AppColors.darkBrown,
          ),
          title: const Text(
            'AI Voice Guide',
            style: TextStyle(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3C2921),
                      Color(0xFF76503B),
                      Color(0xFFB77E55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBrown.withOpacity(0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ask your AI tour guide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Type your question or speak using the microphone.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Select a place',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<int>(
                initialValue: selectedPlaceId,
                isExpanded: true,
                decoration: _inputDecoration(
                  prefixIcon: Icons.location_on_rounded,
                ),
                items: places.map((place) {
                  return DropdownMenuItem(
                    value: place.id,
                    child: Text(place.name),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedPlaceId = value;
                            answer = null;
                          });
                        }
                      },
              ),

              const SizedBox(height: 18),

              const Text(
                'Answer language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'English',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected:
                          selectedLanguage == 'English',
                      selectedColor:
                          AppColors.brown.withOpacity(0.25),
                      onSelected: isLoading
                          ? null
                          : (_) {
                              setState(() {
                                selectedLanguage = 'English';
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'العربية',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected:
                          selectedLanguage == 'Arabic',
                      selectedColor:
                          AppColors.brown.withOpacity(0.25),
                      onSelected: isLoading
                          ? null
                          : (_) {
                              setState(() {
                                selectedLanguage = 'Arabic';
                              });
                            },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Your question',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: TextField(
                  controller: questionController,
                  focusNode: questionFocusNode,
                  enabled: !isLoading,
                  readOnly: false,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 3,
                  maxLines: 6,
                  enableInteractiveSelection: true,
                  autocorrect: true,
                  enableSuggestions: true,
                  onTap: () {
                    questionFocusNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    hintText: selectedLanguage == 'Arabic'
                        ? 'مثال: ما هو تاريخ البتراء؟'
                        : 'Example: What is the history of Petra?',
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.fromLTRB(
                      18,
                      18,
                      10,
                      18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: isListening
                              ? 'Stop listening'
                              : 'Speak question',
                          onPressed: isLoading
                              ? null
                              : isListening
                                  ? stopListening
                                  : startListening,
                          icon: Icon(
                            isListening
                                ? Icons.stop_circle_rounded
                                : Icons.mic_rounded,
                            color: isListening
                                ? Colors.red
                                : AppColors.brown,
                            size: 29,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Clear',
                          onPressed:
                              isLoading ? null : clearQuestion,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isListening) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Listening... speak now',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 57,
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading ? null : askGuide,
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    isLoading
                        ? 'Asking AI...'
                        : 'Ask AI Guide',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.darkBrown.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              if (answer != null) ...[
                const SizedBox(height: 26),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            color: AppColors.brown,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI Guide Answer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      SelectableText(
                        answer!,
                        textDirection:
                            selectedLanguage == 'Arabic'
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textDark,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isSpeaking
                              ? stopSpeaking
                              : speakAnswer,
                          icon: Icon(
                            isSpeaking
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                          ),
                          label: Text(
                            isSpeaking
                                ? 'Stop Voice'
                                : 'Listen to Answer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSpeaking
                                    ? Colors.red.shade700
                                    : AppColors.brown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.brown,
      ),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.brown,
          width: 1.5,
        ),
      ),
    );
  }
}

class _PlaceOption {
  final int id;
  final String name;

  const _PlaceOption({
    required this.id,
    required this.name,
  });
}