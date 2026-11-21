// Phosphor 2.1 MIT font adapter: Flutter 3.47 makes IconData final.
// Font assets and codepoints are provided by phosphor_flutter; no icons are redrawn.
import 'package:flutter/widgets.dart';

enum PhosphorIconsStyle { regular, bold }

@staticIconProvider
abstract final class PhosphorIcons {
  static const windowsLogo = IconData(
    0xe692,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  );
  static const linuxLogo = IconData(
    0xeb02,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  );
  static IconData archive([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe00c,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe00c,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData arrowLeft([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe058,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe058,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData arrowRight([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe06c,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe06c,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData arrowsClockwise([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe094,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe094,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData arrowSquareOut([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe5de,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe5de,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData arrowUpRight([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe092,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe092,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData bookOpen([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe0e6,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe0e6,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData campfire([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe9d8,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe9d8,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData caretRight([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe13a,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe13a,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData check([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe182,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe182,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData checkCircle([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe184,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe184,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData circleDashed([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe602,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe602,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData copy([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe1ca,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe1ca,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData desktopTower([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe562,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe562,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData downloadSimple([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe20c,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe20c,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData eye([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe220,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe220,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData eyeSlash([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe224,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe224,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData fileArrowDown([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe232,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe232,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData floppyDisk([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe248,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe248,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData folderOpen([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe256,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe256,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData gearSix([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe272,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe272,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData globeHemisphereWest([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe28c,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe28c,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData info([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe2ce,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe2ce,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData magnifyingGlass([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe30c,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe30c,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData mountains([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe7ae,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe7ae,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData play([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe3d0,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe3d0,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData plugsConnected([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xeb5a,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xeb5a,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData plus([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe3d4,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe3d4,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData puzzlePiece([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe596,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe596,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData slidersHorizontal([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe434,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe434,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData squaresFour([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe464,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe464,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData steamLogo([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xead4,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xead4,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData stop([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe46c,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe46c,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData terminalWindow([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xeae8,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xeae8,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData trash([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe4a6,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe4a6,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData treeEvergreen([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe6dc,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe6dc,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
  static IconData warning([
    PhosphorIconsStyle style = PhosphorIconsStyle.regular,
  ]) => style == PhosphorIconsStyle.bold
      ? const IconData(
          0xe4e0,
          fontFamily: 'PhosphorBold',
          fontPackage: 'phosphor_flutter',
        )
      : const IconData(
          0xe4e0,
          fontFamily: 'PhosphorRegular',
          fontPackage: 'phosphor_flutter',
        );
}
