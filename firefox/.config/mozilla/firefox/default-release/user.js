// Linked into the Firefox profile (profiles.ini names it). Read at every start.
// Load chrome/userChrome.css (rendered from the active palette by theme/theme).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// No touchpad gestures, as in mango (every action has a key): a two-finger sideways swipe
// scrolls instead of going back or forward, and a pinch does not zoom (ctrl+-/= do).
user_pref("widget.disable-swipe-tracker", true);
user_pref("browser.gesture.swipe.left", "");
user_pref("browser.gesture.swipe.right", "");
user_pref("apz.gtk.touchpad_pinch.enabled", false);
user_pref("browser.gesture.pinch.in", "");
user_pref("browser.gesture.pinch.out", "");
