import 'dart:io';

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:camerawesome/src/orchestrator/models/models.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// This is the builder for your camera interface
/// Using the [state] you can do anything you need without having to think about the camera flow
/// On app start we are in [PreparingCameraState]
/// Then depending on the initialCaptureMode you set you will be [PhotoCameraState] or [VideoCameraState]
/// Starting a video will push a [VideoRecordingCameraState]
/// Stopping the video will push back the [VideoCameraState]
/// ----
/// If you need to call specific function for a state use the 'when' function.
typedef CameraLayoutBuilder = Widget Function(
  CameraState state,

  /// [previewSize] not clipped
  PreviewSize previewSize,

  /// [previewRect] size might be different than [previewSize] if it has been
  /// clipped. It is often clipped in 1:1 ratio. Use it to show elements
  /// relative to the preview (inside or outside for instance)
  Rect previewRect,
);

/// Callback when a video or photo has been saved and user click on thumbnail
typedef OnMediaTap = Function(MediaCapture mediaCapture)?;

/// Used to set a permission result callback
typedef OnPermissionsResult = void Function(bool result);

/// Analysis image stream listener
typedef OnImageForAnalysis = Future Function(AnalysisImage image);

/// This is the entry point of the CameraAwesome plugin
/// You can either
/// - build your custom layout
/// or
/// - use our built in interface
/// with the awesome factory
class CameraAwesomeBuilder extends StatefulWidget {
  /// [front] or [back] camera
  final Sensors sensor;

  final FlashMode flashMode;

  final bool mirrorFrontCamera;

  /// Must be a value between 0.0 (no zoom) and 1.0 (max zoom)
  final double zoom;

  /// Ratio 1:1 is not supported yet on Android
  final CameraAspectRatios aspectRatio;

  /// choose if you want to persist user location in image metadata or not
  final ExifPreferences? exifPreferences;

  /// TODO: DOC
  final AwesomeFilter? filter;

  /// check this for more details
  /// https://api.flutter.dev/flutter/painting/BoxFit.html
  // one of fitWidth, fitHeight, contain, cover
  // currently only work for Android, this do nothing on iOS
  final CameraPreviewFit previewFit;

  /// Enable audio while video recording
  final bool enableAudio;

  /// Path builders when taking photos or recording videos
  final SaveConfig saveConfig;

  /// Called when the preview of the last captured media is tapped
  final OnMediaTap onMediaTap;

  // Widgets
  final Widget? progressIndicator;

  /// UI Builder
  final CameraLayoutBuilder builder;

  final OnImageForAnalysis? onImageForAnalysis;

  /// only for Android
  final AnalysisConfig? imageAnalysisConfig;

  /// Useful for drawing things based on AI Analysis above the CameraPreview for instance
  final CameraLayoutBuilder? previewDecoratorBuilder;

  final OnPreviewTap Function(CameraState)? onPreviewTapBuilder;
  final OnPreviewScale Function(CameraState)? onPreviewScaleBuilder;

  /// Theme of the camera UI, used in the built-in interface.
  ///
  /// You can also use it in your own UI with [AwesomeThemeProvider].
  /// You might need to wrap your UI in a [Builder] to get a [context].
  final AwesomeTheme theme;

  /// Add padding to the preview to adjust where you want to position it.
  /// See also [previewAlignment].
  final EdgeInsets previewPadding;

  /// Set alignment of the preview to adjust its position.
  /// See also [previewPadding].
  final Alignment previewAlignment;

  const CameraAwesomeBuilder._({
    required this.sensor,
    required this.flashMode,
    required this.zoom,
    required this.mirrorFrontCamera,
    required this.aspectRatio,
    required this.exifPreferences,
    required this.enableAudio,
    required this.progressIndicator,
    required this.saveConfig,
    required this.onMediaTap,
    required this.builder,
    required this.previewFit,
    required this.filter,
    this.onImageForAnalysis,
    this.imageAnalysisConfig,
    this.onPreviewTapBuilder,
    this.onPreviewScaleBuilder,
    this.previewDecoratorBuilder,
    required this.theme,
    this.previewPadding = EdgeInsets.zero,
    this.previewAlignment = Alignment.center,
  });

  /// Use the camera with the built-in interface.
  ///
  /// You need to provide a [SaveConfig] to define if you want to take
  /// photos, videos or both and where to save them.
  ///
  /// You can initiate the camera with a few parameters:
  /// - which [sensor] to use ([front] or [back])
  /// - which [flashMode] to use
  /// - how much zoom you want (0.0 = no zoom, 1.0 = max zoom)
  /// - [enableAudio] when recording a video or not
  /// - [exifPreferences] to indicate if you want to save GPS location when
  /// taking photos
  ///
  /// If you want to customize the UI of the camera, you have several options:
  /// - use a [progressIndicator] and define what to do when the preview of the
  /// last media taken is tapped thanks to [onMediaTap]
  /// - use [topActionsBuilder], [bottomActionsBuilder], and
  /// [middleContentBuilder] which let you build entirely the UI similarly to
  /// how the built-in UI is done. Check [AwesomeCameraLayout] for more details.
  /// - build your UI entirely thanks to the [custom] constructor.
  ///
  /// If you want to do image analysis (for AI for instance), you can set the
  /// [imageAnaysisConfig] and listen to the stream of images with
  /// [onImageForAnalysis].
  CameraAwesomeBuilder.awesome({
    Sensors sensor = Sensors.back,
    FlashMode flashMode = FlashMode.none,
    double zoom = 0.0,
    bool mirrorFrontCamera = false,
    CameraAspectRatios aspectRatio = CameraAspectRatios.ratio_4_3,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required SaveConfig saveConfig,
    Function(MediaCapture)? onMediaTap,
    AwesomeFilter? filter,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
    OnPreviewTap Function(CameraState)? onPreviewTapBuilder,
    OnPreviewScale Function(CameraState)? onPreviewScaleBuilder,
    CameraPreviewFit? previewFit,
    CameraLayoutBuilder? previewDecoratorBuilder,
    AwesomeTheme? theme,
    Widget Function(CameraState state)? topActionsBuilder,
    Widget Function(CameraState state)? bottomActionsBuilder,
    Widget Function(CameraState state)? middleContentBuilder,
    EdgeInsets previewPadding = EdgeInsets.zero,
    Alignment previewAlignment = Alignment.center,
  }) : this._(
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          mirrorFrontCamera: mirrorFrontCamera,
          aspectRatio: aspectRatio,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: (cameraModeState, previewSize, previewRect) {
            return AwesomeCameraLayout(
              state: cameraModeState,
              onMediaTap: onMediaTap,
              topActions: topActionsBuilder?.call(cameraModeState),
              bottomActions: bottomActionsBuilder?.call(cameraModeState),
              middleContent: middleContentBuilder?.call(cameraModeState),
            );
          },
          filter: filter,
          saveConfig: saveConfig,
          onMediaTap: onMediaTap,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
          onPreviewTapBuilder: onPreviewTapBuilder,
          onPreviewScaleBuilder: onPreviewScaleBuilder,
          previewFit: previewFit ?? CameraPreviewFit.cover,
          previewDecoratorBuilder: previewDecoratorBuilder,
          theme: theme ?? AwesomeTheme(),
          previewPadding: previewPadding,
          previewAlignment: previewAlignment,
        );

  /// 🚧 Experimental
  ///
  /// Documentation on its way, API might change
  CameraAwesomeBuilder.custom({
    Sensors sensor = Sensors.back,
    FlashMode flashMode = FlashMode.none,
    double zoom = 0.0,
    bool mirrorFrontCamera = false,
    CameraAspectRatios aspectRatio = CameraAspectRatios.ratio_4_3,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required CameraLayoutBuilder builder,
    required SaveConfig saveConfig,
    AwesomeFilter? filter,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
    OnPreviewTap Function(CameraState)? onPreviewTapBuilder,
    OnPreviewScale Function(CameraState)? onPreviewScaleBuilder,
    CameraPreviewFit? previewFit,
    AwesomeTheme? theme,
    EdgeInsets previewPadding = EdgeInsets.zero,
    Alignment previewAlignment = Alignment.center,
  }) : this._(
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          mirrorFrontCamera: mirrorFrontCamera,
          aspectRatio: aspectRatio,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: builder,
          saveConfig: saveConfig,
          onMediaTap: null,
          filter: filter,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
          onPreviewTapBuilder: onPreviewTapBuilder,
          onPreviewScaleBuilder: onPreviewScaleBuilder,
          previewFit: previewFit ?? CameraPreviewFit.cover,
          previewDecoratorBuilder: null,
          theme: theme ?? AwesomeTheme(),
          previewPadding: previewPadding,
          previewAlignment: previewAlignment,
        );

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetBuilder();
  }
}

class _CameraWidgetBuilder extends State<CameraAwesomeBuilder>
    with WidgetsBindingObserver {
  late CameraContext _cameraContext;
  final _cameraPreviewKey = GlobalKey<AwesomeCameraPreviewState>();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraContext.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CameraAwesomeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.paused:        
        break;
      case AppLifecycleState.inactive:
        final currentCapture = cameraContext.mediaCaptureController.value
        if(currentCapture != null && currentCapture.isVideo && currentCapture.status == MediaCaptureStatus.capturing) {
          _cameraContext.state.when(
            onVideoRecordingMode: (mode) => mode.pauseRecording(currentCapture),
          );
        }
        else {
          _cameraContext.state
            .when(onVideoRecordingMode: (mode) => mode.stopRecording());
        }
        break;
      case AppLifecycleState.detached:
        _cameraContext.state
            .when(onVideoRecordingMode: (mode) => mode.stopRecording());
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraContext = CameraContext.create(
      SensorConfig(
        sensor: widget.sensor,
        flash: widget.flashMode,
        currentZoom: widget.zoom,
        mirrorFrontCamera: widget.mirrorFrontCamera,
        aspectRatio: widget.aspectRatio,
      ),
      filter: widget.filter ?? AwesomeFilter.None,
      initialCaptureMode: widget.saveConfig.initialCaptureMode,
      saveConfig: widget.saveConfig,
      onImageForAnalysis: widget.onImageForAnalysis,
      analysisConfig: widget.imageAnalysisConfig,
      exifPreferences:
          widget.exifPreferences ?? ExifPreferences(saveGPSLocation: false),
    );

    // Initial CameraState is always PreparingState
    _cameraContext.state.when(onPreparingCamera: (mode) => mode.start());
  }

  @override
  Widget build(BuildContext context) {
    return AwesomeThemeProvider(
      theme: widget.theme,
      child: StreamBuilder<CameraState>(
        stream: _cameraContext.state$,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.captureMode == null ||
              snapshot.requireData is PreparingCameraState) {
            return widget.progressIndicator ??
                Center(
                  child: Platform.isIOS
                      ? const CupertinoActivityIndicator()
                      : const CircularProgressIndicator(),
                );
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: AwesomeCameraPreview(
                  key: _cameraPreviewKey,
                  previewFit: widget.previewFit,
                  state: snapshot.requireData,
                  padding: widget.previewPadding,
                  alignment: widget.previewAlignment,
                  onPreviewTap:
                      widget.onPreviewTapBuilder?.call(snapshot.requireData) ??
                          OnPreviewTap(
                            onTap: (position, flutterPreviewSize,
                                pixelPreviewSize) {
                              snapshot.requireData.when(
                                onPhotoMode: (photoState) =>
                                    photoState.focusOnPoint(
                                  flutterPosition: position,
                                  pixelPreviewSize: pixelPreviewSize,
                                  flutterPreviewSize: flutterPreviewSize,
                                ),
                                onVideoMode: (videoState) =>
                                    videoState.focusOnPoint(
                                  flutterPosition: position,
                                  pixelPreviewSize: pixelPreviewSize,
                                  flutterPreviewSize: flutterPreviewSize,
                                ),
                                onVideoRecordingMode: (videoRecState) =>
                                    videoRecState.focusOnPoint(
                                  flutterPosition: position,
                                  pixelPreviewSize: pixelPreviewSize,
                                  flutterPreviewSize: flutterPreviewSize,
                                ),
                              );
                            },
                          ),
                  onPreviewScale: widget.onPreviewScaleBuilder
                          ?.call(snapshot.requireData) ??
                      OnPreviewScale(
                        onScale: (scale) {
                          snapshot.requireData.sensorConfig.setZoom(scale);
                        },
                      ),
                  interfaceBuilder: widget.builder,
                  previewDecoratorBuilder: widget.previewDecoratorBuilder,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
