import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class ShowExerciseYT extends StatefulWidget {
  final String url;
  final String nomeEsercizio;

  const ShowExerciseYT(this.url, this.nomeEsercizio, {super.key});

  @override
  State<ShowExerciseYT> createState() => _ShowExerciseYTState();
}

class _ShowExerciseYTState extends State<ShowExerciseYT> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController.fromVideoId(
      videoId: YoutubePlayerController.convertUrlToId(widget.url)!,
      autoPlay: true,
      params: const YoutubePlayerParams(
        loop: true,
        showVideoAnnotations: false,
        showFullscreenButton: false,
        playsInline: true,
        showControls: false,
        strictRelatedVideos: false,
        mute: true,
        enableCaption: false,
        pointerEvents: PointerEvents.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tutorial: ${widget.nomeEsercizio}'), // Titolo dell'AppBar
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 500) {
            return _buildWideContainers();
          } else {
            return _buildNormalContainer();
          }
        },
      ),
    );
  }

  Widget _buildNormalContainer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Torna indietro
                  },
                  child: const Text('Indietro'),
                ),
                const SizedBox(width: 16.0), // Spazio tra i pulsanti
                ElevatedButton(
                  onPressed: () {
                    _controller.loadVideo(widget.url); // Rivedi video
                  },
                  child: const Text('Rivedi video'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideContainers() {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Torna indietro
                      },
                      child: const Text('Indietro'),
                    ),
                    const SizedBox(width: 16.0), // Spazio tra i pulsanti
                    ElevatedButton(
                      onPressed: () {
                        _controller.loadVideo(widget.url); // Rivedi video
                      },
                      child: const Text('Rivedi video'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
