/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $LibGen {
  const $LibGen();

  /// Directory path: lib/image
  $LibImageGen get image => const $LibImageGen();
}

class $LibImageGen {
  const $LibImageGen();

  /// File path: lib/image/airtel.jpg
  AssetGenImage get airtel => const AssetGenImage('lib/image/airtel.jpg');

  /// File path: lib/image/crdb.jpg
  AssetGenImage get crdb => const AssetGenImage('lib/image/crdb.jpg');

  /// File path: lib/image/logo.jpg
  AssetGenImage get logo => const AssetGenImage('lib/image/logo.jpg');

  /// File path: lib/image/nmb.jpg
  AssetGenImage get nmb => const AssetGenImage('lib/image/nmb.jpg');

  /// File path: lib/image/ramadhan.jpg
  AssetGenImage get ramadhan => const AssetGenImage('lib/image/ramadhan.jpg');

  /// File path: lib/image/sadik.jpg
  AssetGenImage get sadik => const AssetGenImage('lib/image/sadik.jpg');

  /// File path: lib/image/vodacom.jpg
  AssetGenImage get vodacom => const AssetGenImage('lib/image/vodacom.jpg');

  /// File path: lib/image/yas.jpg
  AssetGenImage get yas => const AssetGenImage('lib/image/yas.jpg');

  /// List of all assets
  List<AssetGenImage> get values => [
    airtel,
    crdb,
    logo,
    nmb,
    ramadhan,
    sadik,
    vodacom,
    yas,
  ];
}

class Assets {
  const Assets._();

  static const $LibGen lib = $LibGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName, {this.size, this.flavors = const {}});

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
