import Toybox.Application.WatchFaceConfig;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

//! Orchestrates drawing: cached dial bitmap (dial plus the current page's static
//! background), the page content, hands, page indicator, and seconds via partial
//! updates when the skin allows it.
class FaceView extends WatchUi.WatchFace {
    private var _awake as Boolean = true;
    private var _partialAllowed as Boolean = false;
    private var _fullRefresh as Boolean = true;
    private var _width as Number = 0;
    private var _height as Number = 0;
    private var _skin as Skin?;
    private var _skinId as String = "";
    private var _renderer as AnalogRenderer?;
    private var _pageRenderer as PageRenderer?;
    private var _pages as PageManager = new PageManager();
    private var _health as HealthCache?;
    private var _dialBuffer as BufferedBitmap?;
    private var _faceBuffer as BufferedBitmap?;
    private var _selectedUid as Number?;
    private var _staticPageIndex as Number = -1;
    private var _effect as WeatherEffect?;
    private var _effectCategory as Number = -1;
    private var _effectTimer as Timer.Timer?;
    private var _effectLastMs as Number = 0;
    private var _effectBudgetHit as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        _partialAllowed = (WatchUi.WatchFace has :onPartialUpdate);
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        HitRegions.configure(_width, _height);
        _renderer = new AnalogRenderer(_width, _height);
        _pageRenderer = new PageRenderer(_width, _height);
        _health = new HealthCache();
        _pages.restore();
        reloadSettings();
    }

    //! Re-read settings, rebuild pages, reload the skin if it changed, redraw the static layer.
    function reloadSettings() as Void {
        Settings.reload();
        _pages.rebuild();
        var id = Settings.getSkinId();
        var skin = _skin;
        if (skin == null || !id.equals(_skinId)) {
            loadSkin(id);
        } else {
            skin.applyOverrides(Settings.getAccentOverride(), Settings.getDataColorOverride());
        }
        redrawStatic();
        _fullRefresh = true;
    }

    private function loadSkin(id as String) as Void {
        var skin = SkinRegistry.load(id);
        skin.applyOverrides(Settings.getAccentOverride(), Settings.getDataColorOverride());
        _skin = skin;
        _skinId = id;
        _dialBuffer = createBuffer(skin.getDialPalette());
        if (_faceBuffer == null && _partialAllowed) {
            _faceBuffer = createBuffer(null);
            if (_faceBuffer == null) {
                _partialAllowed = false;
            }
        }
    }

    //! Dial plus the current page's static background into the cached bitmap.
    private function redrawStatic() as Void {
        var skin = _skin;
        var renderer = _renderer;
        var pageRenderer = _pageRenderer;
        var dial = _dialBuffer;
        _staticPageIndex = _pages.getIndex();
        if (skin == null || renderer == null || pageRenderer == null || dial == null) {
            return;
        }
        var target = dial.getDc();
        renderer.drawDial(target, skin);
        pageRenderer.drawStatic(target, skin, _pages.getCurrentPage());
    }

    private function createBuffer(palette as Array<Number>?) as BufferedBitmap? {
        if (!(Graphics has :createBufferedBitmap)) {
            return null;
        }
        try {
            if (palette != null) {
                return Graphics.createBufferedBitmap({:width => _width, :height => _height, :palette => palette}).get() as BufferedBitmap;
            }
            return Graphics.createBufferedBitmap({:width => _width, :height => _height}).get() as BufferedBitmap;
        } catch (e) {
            return null;
        }
    }

    function onUpdate(dc as Dc) as Void {
        var skin = _skin;
        var renderer = _renderer;
        var pageRenderer = _pageRenderer;
        var health = _health;
        if (skin == null || renderer == null || pageRenderer == null || health == null) {
            return;
        }
        dc.clearClip();
        var time = System.getClockTime();
        var now = Time.now().value();
        var page = _pages.getCurrentPage();
        var type = page.getType();
        if (type == PageTypes.WEATHER) {
            WeatherCache.refreshIfDue(now);
        } else if (type == PageTypes.HEALTH) {
            health.refreshIfDue(now);
        }
        if (_staticPageIndex != _pages.getIndex()) {
            redrawStatic();
        }

        var face = _faceBuffer;
        var target = (face != null) ? face.getDc() : dc;
        drawFace(target, skin, renderer, pageRenderer, page, health, now);
        pageRenderer.getGeneric().getSlotRenderer().drawPageIndicator(target, skin, _pages.getIndex(), _pages.getPageCount());
        renderer.drawHourMinute(target, skin, time.hour, time.min);
        if (face != null) {
            dc.drawBitmap(0, 0, face);
        }

        Probe.onFrame(self, now);
        _fullRefresh = true;
        if (secondsVisible()) {
            if (!_awake && _partialAllowed) {
                onPartialUpdate(dc);
            } else {
                renderer.drawSeconds(dc, skin, time.sec);
            }
        }
        _fullRefresh = false;
    }

    //! Everything except hands and page indicator: static layer, weather effect, page content.
    private function drawFace(target as Dc, skin as Skin, renderer as AnalogRenderer, pageRenderer as PageRenderer, page as Page, health as HealthCache, now as Number) as Void {
        var dial = _dialBuffer;
        if (dial != null) {
            target.drawBitmap(0, 0, dial);
        } else {
            renderer.drawDial(target, skin);
            pageRenderer.drawStatic(target, skin, page);
        }
        if (page.getType() == PageTypes.WEATHER) {
            syncEffect(skin);
            drawEffect(target);
        } else {
            disposeEffect();
        }
        pageRenderer.draw(target, skin, page, _pages, _selectedUid, now, health);
    }

    //! Create or replace the overlay for the current condition, run its timer while awake.
    private function syncEffect(skin as Skin) as Void {
        if (!Settings.getEffectsEnabled()) {
            disposeEffect();
            return;
        }
        var category = WeatherCache.category;
        if (_effect == null || category != _effectCategory) {
            disposeEffect();
            _effect = EffectRegistry.create(category, _width, _height, skin);
            _effectCategory = category;
        }
        if (_awake) {
            startEffectTimer();
        }
    }

    //! Draw the overlay and enforce the frame budget: over budget once halves the particles.
    private function drawEffect(target as Dc) as Void {
        var effect = _effect;
        if (effect == null) {
            return;
        }
        var started = System.getTimer();
        effect.draw(target);
        var elapsed = System.getTimer() - started;
        if (!_effectBudgetHit && effect.getFps() > 0 && elapsed > effect.getBudgetMs()) {
            effect.halveParticles();
            _effectBudgetHit = true;
            System.println("effects: frame draw " + elapsed + " ms exceeded " + effect.getBudgetMs() + " ms, particles halved to " + effect.getParticleCount());
        }
    }

    private function disposeEffect() as Void {
        stopEffectTimer();
        _effect = null;
        _effectCategory = -1;
    }

    private function startEffectTimer() as Void {
        var effect = _effect;
        if (effect == null) {
            return;
        }
        if (_effectTimer != null || effect.getFps() <= 0 || !(Toybox has :Timer)) {
            return;
        }
        effect.unfreeze();
        var timer = new Timer.Timer();
        _effectTimer = timer;
        _effectLastMs = System.getTimer();
        timer.start(method(:onEffectTick), 1000 / effect.getFps(), true);
    }

    private function stopEffectTimer() as Void {
        var timer = _effectTimer;
        if (timer != null) {
            timer.stop();
            _effectTimer = null;
        }
    }

    //! Timer tick while awake: advance the simulation and ask for a redraw.
    function onEffectTick() as Void {
        var effect = _effect;
        if (effect == null || !_awake) {
            stopEffectTimer();
            return;
        }
        var now = System.getTimer();
        var dt = now - _effectLastMs;
        _effectLastMs = now;
        if (dt < 0 || dt > 1000) {
            dt = 1000 / effect.getFps();
        }
        effect.step(dt);
        WatchUi.requestUpdate();
    }

    //! Low power animation is only allowed on AMOLED when the user opted in: one step per
    //! second and a full face redraw, which the system power budget still governs.
    private function lowPowerEffectAllowed() as Boolean {
        return _effect != null && !Settings.getEffectsOnWristRaiseOnly() && Effects.isAmoled() && _pages.getCurrentPage().getType() == PageTypes.WEATHER;
    }

    //! Once per second in low power mode. Restores the area under the previous
    //! seconds hand from the face buffer, then draws the new hand inside a clip.
    function onPartialUpdate(dc as Dc) as Void {
        var skin = _skin;
        var renderer = _renderer;
        var face = _faceBuffer;
        if (skin == null || renderer == null || face == null || !_partialAllowed) {
            return;
        }
        if (!_awake && lowPowerEffectAllowed()) {
            var effect = _effect;
            var pageRenderer = _pageRenderer;
            var health = _health;
            if (effect != null && pageRenderer != null && health != null) {
                effect.unfreeze();
                effect.step(1000);
                effect.freeze();
                var time = System.getClockTime();
                var target = face.getDc();
                drawFace(target, skin, renderer, pageRenderer, _pages.getCurrentPage(), health, Time.now().value());
                pageRenderer.getGeneric().getSlotRenderer().drawPageIndicator(target, skin, _pages.getIndex(), _pages.getPageCount());
                renderer.drawHourMinute(target, skin, time.hour, time.min);
                dc.setClip(0, 0, _width, _height);
                dc.drawBitmap(0, 0, face);
                _fullRefresh = true;
            }
        }
        if (!_awake && effectiveSecondsMode() != SkinDefs.SECONDS_ALWAYS) {
            return;
        }
        if (!_fullRefresh) {
            dc.drawBitmap(0, 0, face);
        }
        var second = System.getClockTime().sec;
        var clip = renderer.computeSecondsClip(skin, second);
        dc.setClip(clip[0], clip[1], clip[2], clip[3]);
        renderer.drawSeconds(dc, skin, second);
    }

    private function effectiveSecondsMode() as Number {
        var skin = _skin;
        var mode = SkinDefs.SECONDS_MODES[Settings.getSecondsHandMode()];
        if (mode != null) {
            return mode;
        }
        return (skin != null) ? skin.secondsHandMode : SkinDefs.SECONDS_NEVER;
    }

    private function secondsVisible() as Boolean {
        var mode = effectiveSecondsMode();
        if (mode == SkinDefs.SECONDS_NEVER) {
            return false;
        }
        if (mode == SkinDefs.SECONDS_AWAKE_ONLY) {
            return _awake;
        }
        return _awake || _partialAllowed;
    }

    //! Low power: stop the effect timer and freeze the scene so the static face shows the last frame.
    function onEnterSleep() as Void {
        _awake = false;
        stopEffectTimer();
        var effect = _effect;
        if (effect != null) {
            effect.freeze();
        }
        WatchUi.requestUpdate();
    }

    //! High power: resume the effect timer at the skin's frame rate.
    function onExitSleep() as Void {
        _awake = true;
        var effect = _effect;
        if (effect != null) {
            effect.unfreeze();
            startEffectTimer();
        }
        WatchUi.requestUpdate();
    }

    //! Called after onPowerBudgetExceeded: stop drawing seconds while asleep.
    function disablePartialUpdates() as Void {
        _partialAllowed = false;
    }

    function nextPage() as Void {
        _pages.next();
        redrawStatic();
        if (_pages.getCurrentPage().getType() != PageTypes.WEATHER) {
            disposeEffect();
        }
        _fullRefresh = true;
    }

    function isAwake() as Boolean {
        return _awake;
    }

    function getCurrentPageType() as Number {
        return _pages.getCurrentPage().getType();
    }

    //! Editor: complication id of the slot under a tap, or null. Only generic pages have slots.
    function getTappedComplicationUid(x as Number, y as Number) as Number? {
        var pageRenderer = _pageRenderer;
        if (pageRenderer == null || _pages.getCurrentPage().getType() != PageTypes.GENERIC) {
            return null;
        }
        var index = pageRenderer.getGeneric().getSlotRenderer().hitTest(x, y);
        if (index == null) {
            return null;
        }
        return _pages.uidFor(index);
    }

    //! Editor: drawable and bounding box for the complication being edited.
    function getComplicationHighlight(ref as ComplicationRef) as ComplicationDrawableRef? {
        var skin = _skin;
        var pageRenderer = _pageRenderer;
        var uid = ref.uniqueIdentifier;
        if (skin == null || pageRenderer == null || uid == null) {
            return null;
        }
        var page = SettingsKeys.pageForUid(uid);
        var slot = SettingsKeys.slotForUid(uid);
        if (slot < 0 || slot >= SettingsKeys.SLOTS_PER_PAGE) {
            return null;
        }
        _pages.setIndex(page);
        if (_pages.getCurrentPage().getType() != PageTypes.GENERIC) {
            return null;
        }
        redrawStatic();
        _selectedUid = uid;
        WatchUi.requestUpdate();
        var slots = pageRenderer.getGeneric().getSlotRenderer();
        var drawable = new SlotHighlightDrawable(slots, skin, slot, _pages.getCurrentPage().getSource(slot));
        return new WatchUi.ComplicationDrawableRef({:drawable => drawable, :boundingBox => drawable.getBoundingBox()});
    }

    //! Editor: configuration changed. A null type means editing ended.
    function onEditorChanged(type as WatchFaceConfigType?) as Void {
        if (type != WatchUi.WATCH_FACE_CONFIG_TYPE_COMPLICATION) {
            _selectedUid = null;
        }
        reloadSettings();
        WatchUi.requestUpdate();
    }
}
