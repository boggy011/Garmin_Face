import Toybox.Lang;
import Toybox.Math;

//! Moon phase, illumination, moonrise and moonset from compact analytical series
//! (Montenbruck and Pfleger low precision sun and moon, about one arc minute) and an
//! hourly altitude scan with quadratic interpolation for rise and set. Double precision
//! throughout, Unix seconds (UTC) in and out. Accuracy is a few minutes for rise and set.
module Astronomy {
    const SECONDS_PER_DAY = 86400;
    const UNIX_EPOCH_MJD = 40587.0d;
    const ARCSEC_PER_RAD = 206264.8062d;
    const ARCSEC_PER_REV = 1296000.0d;

    //! Rise of the upper limb including parallax and refraction: sin(+8 arc minutes).
    const MOON_SIN_H0 = 0.0023271d;

    enum {
        PHASE_NEW = 0,
        PHASE_WAXING_CRESCENT = 1,
        PHASE_FIRST_QUARTER = 2,
        PHASE_WAXING_GIBBOUS = 3,
        PHASE_FULL = 4,
        PHASE_WANING_GIBBOUS = 5,
        PHASE_LAST_QUARTER = 6,
        PHASE_WANING_CRESCENT = 7
    }

    //! Phase state of the moon at one instant.
    class MoonPhase {
        //! Elongation moon minus sun in [0, 1) cycles. 0 new, 0.5 full.
        var age as Double;
        //! Illuminated fraction of the disc in [0, 1].
        var illumination as Double;
        var waxing as Boolean;
        var phase as Number;

        function initialize(age as Double, illumination as Double, waxing as Boolean, phase as Number) {
            self.age = age;
            self.illumination = illumination;
            self.waxing = waxing;
            self.phase = phase;
        }
    }

    //! Rise and set of the moon during one local day, as Unix seconds or null.
    class RiseSet {
        var rise as Number?;
        var set as Number?;

        function initialize(rise as Number?, set as Number?) {
            self.rise = rise;
            self.set = set;
        }
    }

    function twoPi() as Double {
        return 6.283185307179586d;
    }

    function frac(x as Double) as Double {
        return x - Math.floor(x).toDouble();
    }

    //! Unix seconds to Modified Julian Date.
    function mjd(unixSeconds as Double) as Double {
        return unixSeconds / 86400.0d + UNIX_EPOCH_MJD;
    }

    //! Julian centuries since J2000 for a Modified Julian Date.
    function centuries(mjd as Double) as Double {
        return (mjd - 51544.5d) / 36525.0d;
    }

    //! Mean obliquity of the ecliptic in radians.
    function obliquity(t as Double) as Double {
        return (23.43929111d - 0.013004167d * t) * (3.141592653589793d / 180.0d);
    }

    //! Geocentric ecliptic longitude of the sun in radians.
    function sunLongitude(t as Double) as Double {
        var m = twoPi() * frac(0.993133d + 99.997361d * t);
        var dl = 6893.0d * Math.sin(m) + 72.0d * Math.sin(2.0d * m);
        return twoPi() * frac(0.7859453d + m / twoPi() + (6191.2d * t + dl) / ARCSEC_PER_REV);
    }

    //! Geocentric ecliptic longitude and latitude of the moon in radians as [lon, lat].
    function moonLonLat(t as Double) as Array<Double> {
        var l0 = frac(0.606433d + 1336.855225d * t);
        var l = twoPi() * frac(0.374897d + 1325.552410d * t);
        var ls = twoPi() * frac(0.993133d + 99.997361d * t);
        var d = twoPi() * frac(0.827361d + 1236.853086d * t);
        var f = twoPi() * frac(0.259086d + 1342.227825d * t);
        var dl = 22640.0d * Math.sin(l) - 4586.0d * Math.sin(l - 2.0d * d) + 2370.0d * Math.sin(2.0d * d)
            + 769.0d * Math.sin(2.0d * l) - 668.0d * Math.sin(ls) - 412.0d * Math.sin(2.0d * f)
            - 212.0d * Math.sin(2.0d * l - 2.0d * d) - 206.0d * Math.sin(l + ls - 2.0d * d)
            + 192.0d * Math.sin(l + 2.0d * d) - 165.0d * Math.sin(ls - 2.0d * d) - 125.0d * Math.sin(d)
            - 110.0d * Math.sin(l + ls) + 148.0d * Math.sin(l - ls) - 55.0d * Math.sin(2.0d * f - 2.0d * d);
        var s = f + (dl + 412.0d * Math.sin(2.0d * f) + 541.0d * Math.sin(ls)) / ARCSEC_PER_RAD;
        var h = f - 2.0d * d;
        var n = -526.0d * Math.sin(h) + 44.0d * Math.sin(l + h) - 31.0d * Math.sin(-l + h) - 23.0d * Math.sin(ls + h)
            + 11.0d * Math.sin(-ls + h) - 25.0d * Math.sin(-2.0d * l + f) + 21.0d * Math.sin(-l + f);
        var lon = twoPi() * frac(l0 + dl / ARCSEC_PER_REV);
        var lat = ((18520.0d * Math.sin(s) + n) / ARCSEC_PER_RAD) as Double;
        return [lon, lat] as Array<Double>;
    }

    //! Moon right ascension and declination in radians as [ra, dec].
    function moonRaDec(t as Double) as Array<Double> {
        var lonLat = moonLonLat(t);
        var eps = obliquity(t);
        var cb = Math.cos(lonLat[1]);
        var x = cb * Math.cos(lonLat[0]);
        var v = cb * Math.sin(lonLat[0]);
        var w = Math.sin(lonLat[1]);
        var y = Math.cos(eps) * v - Math.sin(eps) * w;
        var z = Math.sin(eps) * v + Math.cos(eps) * w;
        var rho = Math.sqrt(1.0d - z * z);
        var ra = Math.atan2(y, x);
        if (ra < 0.0d) {
            ra += twoPi();
        }
        return [ra, Math.atan2(z, rho)] as Array<Double>;
    }

    //! Local mean sidereal time in radians.
    function siderealTime(mjd as Double, lonDeg as Double) as Double {
        var mjd0 = Math.floor(mjd).toDouble();
        var ut = (mjd - mjd0) * 24.0d;
        var t = (mjd0 - 51544.5d) / 36525.0d;
        var gmst = 6.697374558d + 1.0027379093d * ut + (8640184.812866d + (0.093104d - 0.0000062d * t) * t) * t / 3600.0d;
        var hours = 24.0d * frac((gmst + lonDeg / 15.0d) / 24.0d);
        return hours * (twoPi() / 24.0d);
    }

    //! Sine of the moon's altitude at a Modified Julian Date for an observer.
    function moonSinAltitude(mjd as Double, latRad as Double, lonDeg as Double) as Double {
        var raDec = moonRaDec(centuries(mjd));
        var tau = siderealTime(mjd, lonDeg) - raDec[0];
        return (Math.sin(latRad) * Math.sin(raDec[1]) + Math.cos(latRad) * Math.cos(raDec[1]) * Math.cos(tau)) as Double;
    }

    //! Phase of the moon at a Unix time.
    function moonPhase(unixSeconds as Number) as MoonPhase {
        var t = centuries(mjd(unixSeconds.toDouble()));
        var elongation = moonLonLat(t)[0] - sunLongitude(t);
        var age = frac(elongation / twoPi());
        var illumination = ((1.0d - Math.cos(age * twoPi())) / 2.0d) as Double;
        var waxing = age < 0.5d;
        return new MoonPhase(age, illumination, waxing, phaseIndex(age));
    }

    //! Eight phase buckets of one sixteenth of a cycle around each principal phase.
    function phaseIndex(age as Double) as Number {
        var index = Math.floor(age * 8.0d + 0.5d).toNumber() % 8;
        return index;
    }

    //! Moonrise and moonset during the local day that starts at localMidnightUnix (UTC seconds of
    //! local 00:00). Uses two hour steps with quadratic interpolation (Montenbruck and Pfleger).
    function moonRiseSet(localMidnightUnix as Number, latDeg as Double, lonDeg as Double) as RiseSet {
        var latRad = latDeg * (3.141592653589793d / 180.0d);
        var mjdStart = mjd(localMidnightUnix.toDouble());
        var rise = null as Number?;
        var set = null as Number?;
        var hour = 0.0d;
        var yMinus = moonSinAltitude(mjdStart, latRad, lonDeg) - MOON_SIN_H0;
        while (hour < 24.0d && (rise == null || set == null)) {
            var y0 = moonSinAltitude(mjdStart + (hour + 1.0d) / 24.0d, latRad, lonDeg) - MOON_SIN_H0;
            var yPlus = moonSinAltitude(mjdStart + (hour + 2.0d) / 24.0d, latRad, lonDeg) - MOON_SIN_H0;
            var a = 0.5d * (yPlus + yMinus) - y0;
            var b = 0.5d * (yPlus - yMinus);
            var c = y0;
            var xe = -b / (2.0d * a);
            var ye = (a * xe + b) * xe + c;
            var disc = b * b - 4.0d * a * c;
            var roots = 0;
            var z1 = 0.0d;
            var z2 = 0.0d;
            if (disc >= 0.0d) {
                var dx = 0.5d * Math.sqrt(disc) / absDouble(a);
                z1 = xe - dx;
                z2 = xe + dx;
                if (absDouble(z1) <= 1.0d) {
                    roots += 1;
                }
                if (absDouble(z2) <= 1.0d) {
                    roots += 1;
                }
                if (z1 < -1.0d) {
                    z1 = z2;
                }
            }
            if (roots == 1) {
                if (yMinus < 0.0d) {
                    rise = eventTime(localMidnightUnix, hour + 1.0d + z1);
                } else {
                    set = eventTime(localMidnightUnix, hour + 1.0d + z1);
                }
            } else if (roots == 2) {
                if (ye < 0.0d) {
                    rise = eventTime(localMidnightUnix, hour + 1.0d + z2);
                    set = eventTime(localMidnightUnix, hour + 1.0d + z1);
                } else {
                    rise = eventTime(localMidnightUnix, hour + 1.0d + z1);
                    set = eventTime(localMidnightUnix, hour + 1.0d + z2);
                }
            }
            yMinus = yPlus;
            hour += 2.0d;
        }
        return new RiseSet(rise, set);
    }

    function eventTime(localMidnightUnix as Number, hours as Double) as Number {
        return localMidnightUnix + Math.round(hours * 3600.0d).toNumber();
    }

    function absDouble(x as Double) as Double {
        return (x < 0.0d) ? -x : x;
    }
}
