//
//  ViewController.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController


@end

//for (NSString *familyName in [UIFont familyNames]) {
    //NSLog(@"字体家族: [%@]---------", familyName);
    //for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
        //NSLog(@"--[%@]-----", fontName);
    //}
//}


/*
 Family: 【Academy Engraved LET】--------
 -- Font: 【AcademyEngravedLetPlain】--------
 Family: 【Al Nile】--------
 -- Font: 【AlNile】--------
 -- Font: 【AlNile-Bold】--------
 Family: 【American Typewriter】--------
 -- Font: 【AmericanTypewriter】--------
 -- Font: 【AmericanTypewriter-Light】--------
 -- Font: 【AmericanTypewriter-Semibold】--------
 -- Font: 【AmericanTypewriter-Bold】--------
 -- Font: 【AmericanTypewriter-Condensed】--------
 -- Font: 【AmericanTypewriter-CondensedLight】--------
 -- Font: 【AmericanTypewriter-CondensedBold】--------
 Family: 【Apple Color Emoji】--------
 -- Font: 【AppleColorEmoji】--------
 Family: 【Apple SD Gothic Neo】--------
 -- Font: 【AppleSDGothicNeo-Regular】--------
 -- Font: 【AppleSDGothicNeo-Thin】--------
 -- Font: 【AppleSDGothicNeo-UltraLight】--------
 -- Font: 【AppleSDGothicNeo-Light】--------
 -- Font: 【AppleSDGothicNeo-Medium】--------
 -- Font: 【AppleSDGothicNeo-SemiBold】--------
 -- Font: 【AppleSDGothicNeo-Bold】--------
 Family: 【Apple Symbols】--------
 -- Font: 【AppleSymbols】--------
 Family: 【Arial】--------
 -- Font: 【ArialMT】--------
 -- Font: 【Arial-ItalicMT】--------
 -- Font: 【Arial-BoldMT】--------
 -- Font: 【Arial-BoldItalicMT】--------
 Family: 【Arial Hebrew】--------
 -- Font: 【ArialHebrew】--------
 -- Font: 【ArialHebrew-Light】--------
 -- Font: 【ArialHebrew-Bold】--------
 Family: 【Arial Rounded MT Bold】--------
 -- Font: 【ArialRoundedMTBold】--------
 Family: 【Avenir】--------
 -- Font: 【Avenir-Book】--------
 -- Font: 【Avenir-Roman】--------
 -- Font: 【Avenir-BookOblique】--------
 -- Font: 【Avenir-Oblique】--------
 -- Font: 【Avenir-Light】--------
 -- Font: 【Avenir-LightOblique】--------
 -- Font: 【Avenir-Medium】--------
 -- Font: 【Avenir-MediumOblique】--------
 -- Font: 【Avenir-Heavy】--------
 -- Font: 【Avenir-HeavyOblique】--------
 -- Font: 【Avenir-Black】--------
 -- Font: 【Avenir-BlackOblique】--------
 Family: 【Avenir Next】--------
 -- Font: 【AvenirNext-Regular】--------
 -- Font: 【AvenirNext-Italic】--------
 -- Font: 【AvenirNext-UltraLight】--------
 -- Font: 【AvenirNext-UltraLightItalic】--------
 -- Font: 【AvenirNext-Medium】--------
 -- Font: 【AvenirNext-MediumItalic】--------
 -- Font: 【AvenirNext-DemiBold】--------
 -- Font: 【AvenirNext-DemiBoldItalic】--------
 -- Font: 【AvenirNext-Bold】--------
 -- Font: 【AvenirNext-BoldItalic】--------
 -- Font: 【AvenirNext-Heavy】--------
 -- Font: 【AvenirNext-HeavyItalic】--------
 Family: 【Avenir Next Condensed】--------
 -- Font: 【AvenirNextCondensed-Regular】--------
 -- Font: 【AvenirNextCondensed-Italic】--------
 -- Font: 【AvenirNextCondensed-UltraLight】--------
 -- Font: 【AvenirNextCondensed-UltraLightItalic】--------
 -- Font: 【AvenirNextCondensed-Medium】--------
 -- Font: 【AvenirNextCondensed-MediumItalic】--------
 -- Font: 【AvenirNextCondensed-DemiBold】--------
 -- Font: 【AvenirNextCondensed-DemiBoldItalic】--------
 -- Font: 【AvenirNextCondensed-Bold】--------
 -- Font: 【AvenirNextCondensed-BoldItalic】--------
 -- Font: 【AvenirNextCondensed-Heavy】--------
 -- Font: 【AvenirNextCondensed-HeavyItalic】--------
 Family: 【Baskerville】--------
 -- Font: 【Baskerville】--------
 -- Font: 【Baskerville-Italic】--------
 -- Font: 【Baskerville-SemiBold】--------
 -- Font: 【Baskerville-SemiBoldItalic】--------
 -- Font: 【Baskerville-Bold】--------
 -- Font: 【Baskerville-BoldItalic】--------
 Family: 【Bodoni 72】--------
 -- Font: 【BodoniSvtyTwoITCTT-Book】--------
 -- Font: 【BodoniSvtyTwoITCTT-BookIta】--------
 -- Font: 【BodoniSvtyTwoITCTT-Bold】--------
 Family: 【Bodoni 72 Oldstyle】--------
 -- Font: 【BodoniSvtyTwoOSITCTT-Book】--------
 -- Font: 【BodoniSvtyTwoOSITCTT-BookIt】--------
 -- Font: 【BodoniSvtyTwoOSITCTT-Bold】--------
 Family: 【Bodoni 72 Smallcaps】--------
 -- Font: 【BodoniSvtyTwoSCITCTT-Book】--------
 Family: 【Bodoni Ornaments】--------
 -- Font: 【BodoniOrnamentsITCTT】--------
 Family: 【Bradley Hand】--------
 -- Font: 【BradleyHandITCTT-Bold】--------
 Family: 【Chalkboard SE】--------
 -- Font: 【ChalkboardSE-Regular】--------
 -- Font: 【ChalkboardSE-Light】--------
 -- Font: 【ChalkboardSE-Bold】--------
 Family: 【Chalkduster】--------
 -- Font: 【Chalkduster】--------
 Family: 【Charter】--------
 -- Font: 【Charter-Roman】--------
 -- Font: 【Charter-Italic】--------
 -- Font: 【Charter-Bold】--------
 -- Font: 【Charter-BoldItalic】--------
 -- Font: 【Charter-Black】--------
 -- Font: 【Charter-BlackItalic】--------
 Family: 【Cochin】--------
 -- Font: 【Cochin】--------
 -- Font: 【Cochin-Italic】--------
 -- Font: 【Cochin-Bold】--------
 -- Font: 【Cochin-BoldItalic】--------
 Family: 【Copperplate】--------
 -- Font: 【Copperplate】--------
 -- Font: 【Copperplate-Light】--------
 -- Font: 【Copperplate-Bold】--------
 Family: 【Courier New】--------
 -- Font: 【CourierNewPSMT】--------
 -- Font: 【CourierNewPS-ItalicMT】--------
 -- Font: 【CourierNewPS-BoldMT】--------
 -- Font: 【CourierNewPS-BoldItalicMT】--------
 Family: 【Damascus】--------
 -- Font: 【Damascus】--------
 -- Font: 【DamascusLight】--------
 -- Font: 【DamascusMedium】--------
 -- Font: 【DamascusSemiBold】--------
 -- Font: 【DamascusBold】--------
 Family: 【Devanagari Sangam MN】--------
 -- Font: 【DevanagariSangamMN】--------
 -- Font: 【DevanagariSangamMN-Bold】--------
 Family: 【Didot】--------
 -- Font: 【Didot】--------
 -- Font: 【Didot-Italic】--------
 -- Font: 【Didot-Bold】--------
 Family: 【DIN Alternate】--------
 -- Font: 【DINAlternate-Bold】--------
 Family: 【DIN Condensed】--------
 -- Font: 【DINCondensed-Bold】--------
 Family: 【Euphemia UCAS】--------
 -- Font: 【EuphemiaUCAS】--------
 -- Font: 【EuphemiaUCAS-Italic】--------
 -- Font: 【EuphemiaUCAS-Bold】--------
 Family: 【Farah】--------
 -- Font: 【Farah】--------
 Family: 【Futura】--------
 -- Font: 【Futura-Medium】--------
 -- Font: 【Futura-MediumItalic】--------
 -- Font: 【Futura-Bold】--------
 -- Font: 【Futura-CondensedMedium】--------
 -- Font: 【Futura-CondensedExtraBold】--------
 Family: 【FZKai-Z03S】--------
 -- Font: 【FZKTJW--GB1-0】--------
 Family: 【Galvji】--------
 -- Font: 【Galvji】--------
 -- Font: 【Galvji-Bold】--------
 Family: 【Geeza Pro】--------
 -- Font: 【GeezaPro】--------
 -- Font: 【GeezaPro-Bold】--------
 Family: 【Georgia】--------
 -- Font: 【Georgia】--------
 -- Font: 【Georgia-Italic】--------
 -- Font: 【Georgia-Bold】--------
 -- Font: 【Georgia-BoldItalic】--------
 Family: 【Gill Sans】--------
 -- Font: 【GillSans】--------
 -- Font: 【GillSans-Italic】--------
 -- Font: 【GillSans-Light】--------
 -- Font: 【GillSans-LightItalic】--------
 -- Font: 【GillSans-SemiBold】--------
 -- Font: 【GillSans-SemiBoldItalic】--------
 -- Font: 【GillSans-Bold】--------
 -- Font: 【GillSans-BoldItalic】--------
 -- Font: 【GillSans-UltraBold】--------
 Family: 【Grantha Sangam MN】--------
 -- Font: 【GranthaSangamMN-Regular】--------
 -- Font: 【GranthaSangamMN-Bold】--------
 Family: 【Helvetica】--------
 -- Font: 【Helvetica】--------
 -- Font: 【Helvetica-Oblique】--------
 -- Font: 【Helvetica-Light】--------
 -- Font: 【Helvetica-LightOblique】--------
 -- Font: 【Helvetica-Bold】--------
 -- Font: 【Helvetica-BoldOblique】--------
 Family: 【Helvetica Neue】--------
 -- Font: 【HelveticaNeue】--------
 -- Font: 【HelveticaNeue-Italic】--------
 -- Font: 【HelveticaNeue-UltraLight】--------
 -- Font: 【HelveticaNeue-UltraLightItalic】--------
 -- Font: 【HelveticaNeue-Thin】--------
 -- Font: 【HelveticaNeue-ThinItalic】--------
 -- Font: 【HelveticaNeue-Light】--------
 -- Font: 【HelveticaNeue-LightItalic】--------
 -- Font: 【HelveticaNeue-Medium】--------
 -- Font: 【HelveticaNeue-MediumItalic】--------
 -- Font: 【HelveticaNeue-Bold】--------
 -- Font: 【HelveticaNeue-BoldItalic】--------
 -- Font: 【HelveticaNeue-CondensedBold】--------
 -- Font: 【HelveticaNeue-CondensedBlack】--------
 Family: 【Hiragino Maru Gothic ProN】--------
 -- Font: 【HiraMaruProN-W4】--------
 Family: 【Hiragino Mincho ProN】--------
 -- Font: 【HiraMinProN-W3】--------
 -- Font: 【HiraMinProN-W6】--------
 Family: 【Hiragino Sans】--------
 -- Font: 【HiraginoSans-W3】--------
 -- Font: 【HiraginoSans-W4】--------
 -- Font: 【HiraginoSans-W5】--------
 -- Font: 【HiraginoSans-W6】--------
 -- Font: 【HiraginoSans-W7】--------
 -- Font: 【HiraginoSans-W8】--------
 Family: 【Hoefler Text】--------
 -- Font: 【HoeflerText-Regular】--------
 -- Font: 【HoeflerText-Italic】--------
 -- Font: 【HoeflerText-Black】--------
 -- Font: 【HoeflerText-BlackItalic】--------
 Family: 【Impact】--------
 -- Font: 【Impact】--------
 Family: 【Kailasa】--------
 -- Font: 【Kailasa】--------
 -- Font: 【Kailasa-Bold】--------
 Family: 【Kefa III】--------
 -- Font: 【KefaIII-Regular】--------
 -- Font: 【KefaIII-Light】--------
 -- Font: 【KefaIII-Bold】--------
 -- Font: 【KefaIII-ExtraBold】--------
 Family: 【Khmer Sangam MN】--------
 -- Font: 【KhmerSangamMN】--------
 Family: 【Kohinoor Bangla】--------
 -- Font: 【KohinoorBangla-Regular】--------
 -- Font: 【KohinoorBangla-Light】--------
 -- Font: 【KohinoorBangla-Semibold】--------
 Family: 【Kohinoor Devanagari】--------
 -- Font: 【KohinoorDevanagari-Regular】--------
 -- Font: 【KohinoorDevanagari-Light】--------
 -- Font: 【KohinoorDevanagari-Semibold】--------
 Family: 【Kohinoor Gujarati】--------
 -- Font: 【KohinoorGujarati-Regular】--------
 -- Font: 【KohinoorGujarati-Light】--------
 -- Font: 【KohinoorGujarati-Bold】--------
 Family: 【Kohinoor Telugu】--------
 -- Font: 【KohinoorTelugu-Regular】--------
 -- Font: 【KohinoorTelugu-Light】--------
 -- Font: 【KohinoorTelugu-Medium】--------
 Family: 【Lao Sangam MN】--------
 -- Font: 【LaoSangamMN】--------
 Family: 【Malayalam Sangam MN】--------
 -- Font: 【MalayalamSangamMN】--------
 -- Font: 【MalayalamSangamMN-Bold】--------
 Family: 【Marker Felt】--------
 -- Font: 【MarkerFelt-Thin】--------
 -- Font: 【MarkerFelt-Wide】--------
 Family: 【Menlo】--------
 -- Font: 【Menlo-Regular】--------
 -- Font: 【Menlo-Italic】--------
 -- Font: 【Menlo-Bold】--------
 -- Font: 【Menlo-BoldItalic】--------
 Family: 【Mishafi】--------
 -- Font: 【DiwanMishafi】--------
 Family: 【Mukta Mahee】--------
 -- Font: 【MuktaMahee-Regular】--------
 -- Font: 【MuktaMahee-Light】--------
 -- Font: 【MuktaMahee-Bold】--------
 Family: 【Myanmar Sangam MN】--------
 -- Font: 【MyanmarSangamMN】--------
 -- Font: 【MyanmarSangamMN-Bold】--------
 Family: 【Noteworthy】--------
 -- Font: 【Noteworthy-Light】--------
 -- Font: 【Noteworthy-Bold】--------
 Family: 【Noto Nastaliq Urdu】--------
 -- Font: 【NotoNastaliqUrdu】--------
 -- Font: 【NotoNastaliqUrdu-Bold】--------
 Family: 【Noto Sans Kannada】--------
 -- Font: 【NotoSansKannada-Regular】--------
 -- Font: 【NotoSansKannada-Light】--------
 -- Font: 【NotoSansKannada-Bold】--------
 Family: 【Noto Sans Myanmar】--------
 -- Font: 【NotoSansMyanmar-Regular】--------
 -- Font: 【NotoSansMyanmar-Light】--------
 -- Font: 【NotoSansMyanmar-Bold】--------
 Family: 【Noto Sans Oriya】--------
 -- Font: 【NotoSansOriya】--------
 -- Font: 【NotoSansOriya-Bold】--------
 Family: 【Noto Sans Syriac】--------
 -- Font: 【NotoSansSyriac-Regular】--------
 -- Font: 【NotoSansSyriac-Regular_Thin】--------
 -- Font: 【NotoSansSyriac-Regular_ExtraLight】--------
 -- Font: 【NotoSansSyriac-Regular_Light】--------
 -- Font: 【NotoSansSyriac-Regular_Medium】--------
 -- Font: 【NotoSansSyriac-Regular_SemiBold】--------
 -- Font: 【NotoSansSyriac-Regular_Bold】--------
 -- Font: 【NotoSansSyriac-Regular_ExtraBold】--------
 -- Font: 【NotoSansSyriac-Regular_Black】--------
 Family: 【Optima】--------
 -- Font: 【Optima-Regular】--------
 -- Font: 【Optima-Italic】--------
 -- Font: 【Optima-Bold】--------
 -- Font: 【Optima-BoldItalic】--------
 -- Font: 【Optima-ExtraBlack】--------
 Family: 【Palatino】--------
 -- Font: 【Palatino-Roman】--------
 -- Font: 【Palatino-Italic】--------
 -- Font: 【Palatino-Bold】--------
 -- Font: 【Palatino-BoldItalic】--------
 Family: 【Papyrus】--------
 -- Font: 【Papyrus】--------
 -- Font: 【Papyrus-Condensed】--------
 Family: 【Party LET】--------
 -- Font: 【PartyLetPlain】--------
 Family: 【PingFang HK】--------
 -- Font: 【PingFangHK-Regular】--------
 -- Font: 【PingFangHK-Ultralight】--------
 -- Font: 【PingFangHK-Thin】--------
 -- Font: 【PingFangHK-Light】--------
 -- Font: 【PingFangHK-Medium】--------
 -- Font: 【PingFangHK-Semibold】--------
 Family: 【PingFang MO】--------
 -- Font: 【PingFangMO-Regular】--------
 -- Font: 【PingFangMO-Ultralight】--------
 -- Font: 【PingFangMO-Thin】--------
 -- Font: 【PingFangMO-Light】--------
 -- Font: 【PingFangMO-Medium】--------
 -- Font: 【PingFangMO-Semibold】--------
 Family: 【PingFang SC】--------
 -- Font: 【PingFangSC-Regular】--------
 -- Font: 【PingFangSC-Ultralight】--------
 -- Font: 【PingFangSC-Thin】--------
 -- Font: 【PingFangSC-Light】--------
 -- Font: 【PingFangSC-Medium】--------
 -- Font: 【PingFangSC-Semibold】--------
 Family: 【PingFang TC】--------
 -- Font: 【PingFangTC-Regular】--------
 -- Font: 【PingFangTC-Ultralight】--------
 -- Font: 【PingFangTC-Thin】--------
 -- Font: 【PingFangTC-Light】--------
 -- Font: 【PingFangTC-Medium】--------
 -- Font: 【PingFangTC-Semibold】--------
 Family: 【Rockwell】--------
 -- Font: 【Rockwell-Regular】--------
 -- Font: 【Rockwell-Italic】--------
 -- Font: 【Rockwell-Bold】--------
 -- Font: 【Rockwell-BoldItalic】--------
 Family: 【Savoye LET】--------
 -- Font: 【SavoyeLetPlain】--------
 Family: 【Sinhala Sangam MN】--------
 -- Font: 【SinhalaSangamMN】--------
 -- Font: 【SinhalaSangamMN-Bold】--------
 Family: 【Snell Roundhand】--------
 -- Font: 【SnellRoundhand】--------
 -- Font: 【SnellRoundhand-Bold】--------
 -- Font: 【SnellRoundhand-Black】--------
 Family: 【STIX Two Math】--------
 -- Font: 【STIXTwoMath-Regular】--------
 Family: 【STIX Two Text】--------
 -- Font: 【STIXTwoText】--------
 -- Font: 【STIXTwoText-Italic】--------
 -- Font: 【STIXTwoText_Medium】--------
 -- Font: 【STIXTwoText-Italic_Medium-Italic】--------
 -- Font: 【STIXTwoText_SemiBold】--------
 -- Font: 【STIXTwoText-Italic_SemiBold-Italic】--------
 -- Font: 【STIXTwoText_Bold】--------
 -- Font: 【STIXTwoText-Italic_Bold-Italic】--------
 Family: 【Symbol】--------
 -- Font: 【Symbol】--------
 Family: 【Tamil Sangam MN】--------
 -- Font: 【TamilSangamMN】--------
 -- Font: 【TamilSangamMN-Bold】--------
 Family: 【Thonburi】--------
 -- Font: 【Thonburi】--------
 -- Font: 【Thonburi-Light】--------
 -- Font: 【Thonburi-Bold】--------
 Family: 【Times New Roman】--------
 -- Font: 【TimesNewRomanPSMT】--------
 -- Font: 【TimesNewRomanPS-ItalicMT】--------
 -- Font: 【TimesNewRomanPS-BoldMT】--------
 -- Font: 【TimesNewRomanPS-BoldItalicMT】--------
 Family: 【Trebuchet MS】--------
 -- Font: 【TrebuchetMS】--------
 -- Font: 【TrebuchetMS-Italic】--------
 -- Font: 【TrebuchetMS-Bold】--------
 -- Font: 【Trebuchet-BoldItalic】--------
 Family: 【Verdana】--------
 -- Font: 【Verdana】--------
 -- Font: 【Verdana-Italic】--------
 -- Font: 【Verdana-Bold】--------
 -- Font: 【Verdana-BoldItalic】--------
 Family: 【Zapf Dingbats】--------
 -- Font: 【ZapfDingbatsITC】--------
 Family: 【Zapfino】--------
 -- Font: 【Zapfino】--------
 */
