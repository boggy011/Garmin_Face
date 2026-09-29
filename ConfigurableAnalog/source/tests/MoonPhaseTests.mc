import Toybox.Lang;
import Toybox.Test;

(:test)
function testMoonPhaseLitSide(logger as Logger) as Boolean {
    var r = 20;
    Test.assertMessage(!MoonPhase.isLit(10, 0, r, 0.0, true), "new moon: nothing lit");
    Test.assertMessage(!MoonPhase.isLit(-10, 0, r, 0.0, true), "new moon: nothing lit on the left either");
    Test.assertMessage(MoonPhase.isLit(10, 0, r, 1.0, true), "full moon: right lit");
    Test.assertMessage(MoonPhase.isLit(-10, 0, r, 1.0, true), "full moon: left lit");
    Test.assertMessage(MoonPhase.isLit(10, 0, r, 0.5, true), "first quarter: right half lit");
    Test.assertMessage(!MoonPhase.isLit(-10, 0, r, 0.5, true), "first quarter: left half dark");
    Test.assertMessage(!MoonPhase.isLit(10, 0, r, 0.5, false), "last quarter: right half dark");
    Test.assertMessage(MoonPhase.isLit(-10, 0, r, 0.5, false), "last quarter: left half lit");
    Test.assertMessage(MoonPhase.isLit(15, 0, r, 0.25, true), "waxing crescent: limb lit");
    Test.assertMessage(!MoonPhase.isLit(5, 0, r, 0.25, true), "waxing crescent: inside the terminator dark");
    Test.assertMessage(MoonPhase.isLit(-5, 0, r, 0.75, true), "waxing gibbous: past the centre still lit");
    Test.assertMessage(!MoonPhase.isLit(-15, 0, r, 0.75, true), "waxing gibbous: far left dark");
    Test.assertMessage(!MoonPhase.isLit(0, 25, r, 1.0, true), "outside the disc is never lit");
    return true;
}
