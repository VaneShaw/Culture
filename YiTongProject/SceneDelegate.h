//
//  SceneDelegate.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <UIKit/UIKit.h>

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow * window;

@end

/*
 //默认字体
 
 字体家族: [Academy Engraved LET]---------
 --[AcademyEngravedLetPlain]-----
 字体家族: [Al Nile]---------
 --[AlNile]-----
 --[AlNile-Bold]-----
 字体家族: [American Typewriter]---------
 --[AmericanTypewriter]-----
 --[AmericanTypewriter-Light]-----
 --[AmericanTypewriter-Semibold]-----
 --[AmericanTypewriter-Bold]-----
 --[AmericanTypewriter-Condensed]-----
 --[AmericanTypewriter-CondensedLight]-----
 --[AmericanTypewriter-CondensedBold]-----
 字体家族: [Apple Color Emoji]---------
 --[AppleColorEmoji]-----
 字体家族: [Apple SD Gothic Neo]---------
 --[AppleSDGothicNeo-Regular]-----
 --[AppleSDGothicNeo-Thin]-----
 --[AppleSDGothicNeo-UltraLight]-----
 --[AppleSDGothicNeo-Light]-----
 --[AppleSDGothicNeo-Medium]-----
 --[AppleSDGothicNeo-SemiBold]-----
 --[AppleSDGothicNeo-Bold]-----
 字体家族: [Apple Symbols]---------
 --[AppleSymbols]-----
 字体家族: [Arial]---------
 --[ArialMT]-----
 --[Arial-ItalicMT]-----
 --[Arial-BoldMT]-----
 --[Arial-BoldItalicMT]-----
 字体家族: [Arial Hebrew]---------
 --[ArialHebrew]-----
 --[ArialHebrew-Light]-----
 --[ArialHebrew-Bold]-----
 字体家族: [Arial Rounded MT Bold]---------
 --[ArialRoundedMTBold]-----
 字体家族: [Avenir]---------
 --[Avenir-Book]-----
 --[Avenir-Roman]-----
 --[Avenir-BookOblique]-----
 --[Avenir-Oblique]-----
 --[Avenir-Light]-----
 --[Avenir-LightOblique]-----
 --[Avenir-Medium]-----
 --[Avenir-MediumOblique]-----
 --[Avenir-Heavy]-----
 --[Avenir-HeavyOblique]-----
 --[Avenir-Black]-----
 --[Avenir-BlackOblique]-----
 字体家族: [Avenir Next]---------
 --[AvenirNext-Regular]-----
 --[AvenirNext-Italic]-----
 --[AvenirNext-UltraLight]-----
 --[AvenirNext-UltraLightItalic]-----
 --[AvenirNext-Medium]-----
 --[AvenirNext-MediumItalic]-----
 --[AvenirNext-DemiBold]-----
 --[AvenirNext-DemiBoldItalic]-----
 --[AvenirNext-Bold]-----
 --[AvenirNext-BoldItalic]-----
 --[AvenirNext-Heavy]-----
 --[AvenirNext-HeavyItalic]-----
 字体家族: [Avenir Next Condensed]---------
 --[AvenirNextCondensed-Regular]-----
 --[AvenirNextCondensed-Italic]-----
 --[AvenirNextCondensed-UltraLight]-----
 --[AvenirNextCondensed-UltraLightItalic]-----
 --[AvenirNextCondensed-Medium]-----
 --[AvenirNextCondensed-MediumItalic]-----
 --[AvenirNextCondensed-DemiBold]-----
 --[AvenirNextCondensed-DemiBoldItalic]-----
 --[AvenirNextCondensed-Bold]-----
 --[AvenirNextCondensed-BoldItalic]-----
 --[AvenirNextCondensed-Heavy]-----
 --[AvenirNextCondensed-HeavyItalic]-----
 字体家族: [Baskerville]---------
 --[Baskerville]-----
 --[Baskerville-Italic]-----
 --[Baskerville-SemiBold]-----
 --[Baskerville-SemiBoldItalic]-----
 --[Baskerville-Bold]-----
 --[Baskerville-BoldItalic]-----
 字体家族: [Bodoni 72]---------
 --[BodoniSvtyTwoITCTT-Book]-----
 --[BodoniSvtyTwoITCTT-BookIta]-----
 --[BodoniSvtyTwoITCTT-Bold]-----
 字体家族: [Bodoni 72 Oldstyle]---------
 --[BodoniSvtyTwoOSITCTT-Book]-----
 --[BodoniSvtyTwoOSITCTT-BookIt]-----
 --[BodoniSvtyTwoOSITCTT-Bold]-----
 字体家族: [Bodoni 72 Smallcaps]---------
 --[BodoniSvtyTwoSCITCTT-Book]-----
 字体家族: [Bodoni Ornaments]---------
 --[BodoniOrnamentsITCTT]-----
 字体家族: [Bradley Hand]---------
 --[BradleyHandITCTT-Bold]-----
 字体家族: [Chalkboard SE]---------
 --[ChalkboardSE-Regular]-----
 --[ChalkboardSE-Light]-----
 --[ChalkboardSE-Bold]-----
 字体家族: [Chalkduster]---------
 --[Chalkduster]-----
 字体家族: [Charter]---------
 --[Charter-Roman]-----
 --[Charter-Italic]-----
 --[Charter-Bold]-----
 --[Charter-BoldItalic]-----
 --[Charter-Black]-----
 --[Charter-BlackItalic]-----
 字体家族: [Cochin]---------
 --[Cochin]-----
 --[Cochin-Italic]-----
 --[Cochin-Bold]-----
 --[Cochin-BoldItalic]-----
 字体家族: [Copperplate]---------
 --[Copperplate]-----
 --[Copperplate-Light]-----
 --[Copperplate-Bold]-----
 字体家族: [Courier New]---------
 --[CourierNewPSMT]-----
 --[CourierNewPS-ItalicMT]-----
 --[CourierNewPS-BoldMT]-----
 --[CourierNewPS-BoldItalicMT]-----
 字体家族: [Damascus]---------
 --[Damascus]-----
 --[DamascusLight]-----
 --[DamascusMedium]-----
 --[DamascusSemiBold]-----
 --[DamascusBold]-----
 字体家族: [Devanagari Sangam MN]---------
 --[DevanagariSangamMN]-----
 --[DevanagariSangamMN-Bold]-----
 字体家族: [Didot]---------
 --[Didot]-----
 --[Didot-Italic]-----
 --[Didot-Bold]-----
 字体家族: [DIN Alternate]---------
 --[DINAlternate-Bold]-----
 字体家族: [DIN Condensed]---------
 --[DINCondensed-Bold]-----
 字体家族: [Euphemia UCAS]---------
 --[EuphemiaUCAS]-----
 --[EuphemiaUCAS-Italic]-----
 --[EuphemiaUCAS-Bold]-----
 字体家族: [Farah]---------
 --[Farah]-----
 字体家族: [Futura]---------
 --[Futura-Medium]-----
 --[Futura-MediumItalic]-----
 --[Futura-Bold]-----
 --[Futura-CondensedMedium]-----
 --[Futura-CondensedExtraBold]-----
 字体家族: [Galvji]---------
 --[Galvji]-----
 --[Galvji-Bold]-----
 字体家族: [Geeza Pro]---------
 --[GeezaPro]-----
 --[GeezaPro-Bold]-----
 字体家族: [Georgia]---------
 --[Georgia]-----
 --[Georgia-Italic]-----
 --[Georgia-Bold]-----
 --[Georgia-BoldItalic]-----
 字体家族: [Gill Sans]---------
 --[GillSans]-----
 --[GillSans-Italic]-----
 --[GillSans-Light]-----
 --[GillSans-LightItalic]-----
 --[GillSans-SemiBold]-----
 --[GillSans-SemiBoldItalic]-----
 --[GillSans-Bold]-----
 --[GillSans-BoldItalic]-----
 --[GillSans-UltraBold]-----
 字体家族: [Grantha Sangam MN]---------
 --[GranthaSangamMN-Regular]-----
 --[GranthaSangamMN-Bold]-----
 字体家族: [Helvetica]---------
 --[Helvetica]-----
 --[Helvetica-Oblique]-----
 --[Helvetica-Light]-----
 --[Helvetica-LightOblique]-----
 --[Helvetica-Bold]-----
 --[Helvetica-BoldOblique]-----
 字体家族: [Helvetica Neue]---------
 --[HelveticaNeue]-----
 --[HelveticaNeue-Italic]-----
 --[HelveticaNeue-UltraLight]-----
 --[HelveticaNeue-UltraLightItalic]-----
 --[HelveticaNeue-Thin]-----
 --[HelveticaNeue-ThinItalic]-----
 --[HelveticaNeue-Light]-----
 --[HelveticaNeue-LightItalic]-----
 --[HelveticaNeue-Medium]-----
 --[HelveticaNeue-MediumItalic]-----
 --[HelveticaNeue-Bold]-----
 --[HelveticaNeue-BoldItalic]-----
 --[HelveticaNeue-CondensedBold]-----
 --[HelveticaNeue-CondensedBlack]-----
 字体家族: [Hiragino Maru Gothic ProN]---------
 --[HiraMaruProN-W4]-----
 字体家族: [Hiragino Mincho ProN]---------
 --[HiraMinProN-W3]-----
 --[HiraMinProN-W6]-----
 字体家族: [Hiragino Sans]---------
 --[HiraginoSans-W3]-----
 --[HiraginoSans-W4]-----
 --[HiraginoSans-W5]-----
 --[HiraginoSans-W6]-----
 --[HiraginoSans-W7]-----
 --[HiraginoSans-W8]-----
 字体家族: [Hoefler Text]---------
 --[HoeflerText-Regular]-----
 --[HoeflerText-Italic]-----
 --[HoeflerText-Black]-----
 --[HoeflerText-BlackItalic]-----
 字体家族: [Impact]---------
 --[Impact]-----
 字体家族: [Kailasa]---------
 --[Kailasa]-----
 --[Kailasa-Bold]-----
 字体家族: [Kefa]---------
 --[Kefa-Regular]-----
 字体家族: [Khmer Sangam MN]---------
 --[KhmerSangamMN]-----
 字体家族: [Kohinoor Bangla]---------
 --[KohinoorBangla-Regular]-----
 --[KohinoorBangla-Light]-----
 --[KohinoorBangla-Semibold]-----
 字体家族: [Kohinoor Devanagari]---------
 --[KohinoorDevanagari-Regular]-----
 --[KohinoorDevanagari-Light]-----
 --[KohinoorDevanagari-Semibold]-----
 字体家族: [Kohinoor Gujarati]---------
 --[KohinoorGujarati-Regular]-----
 --[KohinoorGujarati-Light]-----
 --[KohinoorGujarati-Bold]-----
 字体家族: [Kohinoor Telugu]---------
 --[KohinoorTelugu-Regular]-----
 --[KohinoorTelugu-Light]-----
 --[KohinoorTelugu-Medium]-----
 字体家族: [Lao Sangam MN]---------
 --[LaoSangamMN]-----
 字体家族: [Malayalam Sangam MN]---------
 --[MalayalamSangamMN]-----
 --[MalayalamSangamMN-Bold]-----
 字体家族: [Marker Felt]---------
 --[MarkerFelt-Thin]-----
 --[MarkerFelt-Wide]-----
 字体家族: [Menlo]---------
 --[Menlo-Regular]-----
 --[Menlo-Italic]-----
 --[Menlo-Bold]-----
 --[Menlo-BoldItalic]-----
 字体家族: [Mishafi]---------
 --[DiwanMishafi]-----
 字体家族: [Mukta Mahee]---------
 --[MuktaMahee-Regular]-----
 --[MuktaMahee-Light]-----
 --[MuktaMahee-Bold]-----
 字体家族: [Myanmar Sangam MN]---------
 --[MyanmarSangamMN]-----
 --[MyanmarSangamMN-Bold]-----
 字体家族: [Noteworthy]---------
 --[Noteworthy-Light]-----
 --[Noteworthy-Bold]-----
 字体家族: [Noto Nastaliq Urdu]---------
 --[NotoNastaliqUrdu]-----
 --[NotoNastaliqUrdu-Bold]-----
 字体家族: [Noto Sans Kannada]---------
 --[NotoSansKannada-Regular]-----
 --[NotoSansKannada-Light]-----
 --[NotoSansKannada-Bold]-----
 字体家族: [Noto Sans Myanmar]---------
 --[NotoSansMyanmar-Regular]-----
 --[NotoSansMyanmar-Light]-----
 --[NotoSansMyanmar-Bold]-----
 字体家族: [Noto Sans Oriya]---------
 --[NotoSansOriya]-----
 --[NotoSansOriya-Bold]-----
 字体家族: [Noto Sans Syriac]---------
 --[NotoSansSyriac-Regular]-----
 --[NotoSansSyriac-Regular_Thin]-----
 --[NotoSansSyriac-Regular_ExtraLight]-----
 --[NotoSansSyriac-Regular_Light]-----
 --[NotoSansSyriac-Regular_Medium]-----
 --[NotoSansSyriac-Regular_SemiBold]-----
 --[NotoSansSyriac-Regular_Bold]-----
 --[NotoSansSyriac-Regular_ExtraBold]-----
 --[NotoSansSyriac-Regular_Black]-----
 字体家族: [Optima]---------
 --[Optima-Regular]-----
 --[Optima-Italic]-----
 --[Optima-Bold]-----
 --[Optima-BoldItalic]-----
 --[Optima-ExtraBlack]-----
 字体家族: [Palatino]---------
 --[Palatino-Roman]-----
 --[Palatino-Italic]-----
 --[Palatino-Bold]-----
 --[Palatino-BoldItalic]-----
 字体家族: [Papyrus]---------
 --[Papyrus]-----
 --[Papyrus-Condensed]-----
 字体家族: [Party LET]---------
 --[PartyLetPlain]-----
 字体家族: [PingFang HK]---------
 --[PingFangHK-Regular]-----
 --[PingFangHK-Ultralight]-----
 --[PingFangHK-Thin]-----
 --[PingFangHK-Light]-----
 --[PingFangHK-Medium]-----
 --[PingFangHK-Semibold]-----
 字体家族: [PingFang MO]---------
 --[PingFangMO-Regular]-----
 --[PingFangMO-Ultralight]-----
 --[PingFangMO-Thin]-----
 --[PingFangMO-Light]-----
 --[PingFangMO-Medium]-----
 --[PingFangMO-Semibold]-----
 字体家族: [PingFang SC]---------
 --[PingFangSC-Regular]-----
 --[PingFangSC-Ultralight]-----
 --[PingFangSC-Thin]-----
 --[PingFangSC-Light]-----
 --[PingFangSC-Medium]-----
 --[PingFangSC-Semibold]-----
 字体家族: [PingFang TC]---------
 --[PingFangTC-Regular]-----
 --[PingFangTC-Ultralight]-----
 --[PingFangTC-Thin]-----
 --[PingFangTC-Light]-----
 --[PingFangTC-Medium]-----
 --[PingFangTC-Semibold]-----
 字体家族: [Rockwell]---------
 --[Rockwell-Regular]-----
 --[Rockwell-Italic]-----
 --[Rockwell-Bold]-----
 --[Rockwell-BoldItalic]-----
 字体家族: [Savoye LET]---------
 --[SavoyeLetPlain]-----
 字体家族: [Sinhala Sangam MN]---------
 --[SinhalaSangamMN]-----
 --[SinhalaSangamMN-Bold]-----
 字体家族: [Snell Roundhand]---------
 --[SnellRoundhand]-----
 --[SnellRoundhand-Bold]-----
 --[SnellRoundhand-Black]-----
 字体家族: [STIX Two Math]---------
 --[STIXTwoMath-Regular]-----
 字体家族: [STIX Two Text]---------
 --[STIXTwoText]-----
 --[STIXTwoText-Italic]-----
 --[STIXTwoText_Medium]-----
 --[STIXTwoText-Italic_Medium-Italic]-----
 --[STIXTwoText_SemiBold]-----
 --[STIXTwoText-Italic_SemiBold-Italic]-----
 --[STIXTwoText_Bold]-----
 --[STIXTwoText-Italic_Bold-Italic]-----
 字体家族: [Symbol]---------
 --[Symbol]-----
 字体家族: [Tamil Sangam MN]---------
 --[TamilSangamMN]-----
 --[TamilSangamMN-Bold]-----
 字体家族: [Thonburi]---------
 --[Thonburi]-----
 --[Thonburi-Light]-----
 --[Thonburi-Bold]-----
 字体家族: [Times New Roman]---------
 --[TimesNewRomanPSMT]-----
 --[TimesNewRomanPS-ItalicMT]-----
 --[TimesNewRomanPS-BoldMT]-----
 --[TimesNewRomanPS-BoldItalicMT]-----
 字体家族: [Trebuchet MS]---------
 --[TrebuchetMS]-----
 --[TrebuchetMS-Italic]-----
 --[TrebuchetMS-Bold]-----
 --[Trebuchet-BoldItalic]-----
 字体家族: [Verdana]---------
 --[Verdana]-----
 --[Verdana-Italic]-----
 --[Verdana-Bold]-----
 --[Verdana-BoldItalic]-----
 字体家族: [Zapf Dingbats]---------
 --[ZapfDingbatsITC]-----
 字体家族: [Zapfino]---------
 --[Zapfino]-----
 
 
 */
