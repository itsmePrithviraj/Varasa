---
name: Varasa
description: Restored illustrated heritage community using the original Varasa artwork and compositions.
colors:
  ink: "#622A0F"
  terracotta: "#903A36"
  parchment: "#FFEEDB"
  paper: "#FFFCF7"
  white: "#FFFFFF"
  story-cream: "#FFF9F2"
  story-ink: "#33251E"
  muted-clay: "#D1A487"
  category-clay: "#E0BFA8"
  auth-red: "#BD3032"
  error: "#AB2323"
typography:
  display:
    fontFamily: "CinzelDecorative"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1.1
  headline:
    fontFamily: "CinzelDecorative"
    fontSize: "24px"
    fontWeight: 700
  game-title:
    fontFamily: "CormorantGaramond"
    fontSize: "32px"
    fontWeight: 700
  category-title:
    fontFamily: "CormorantGaramond"
    fontSize: "25px"
    fontWeight: 700
  story-author:
    fontFamily: "Itim"
    fontSize: "18px"
  story-body:
    fontFamily: "Itim"
    fontSize: "17px"
    lineHeight: 1.45
  supporting:
    fontFamily: "Itim"
    fontSize: "16px"
  body-large:
    fontSize: "16px"
    lineHeight: 1.5
  body-medium:
    fontSize: "14px"
    lineHeight: 1.5
rounded:
  auth-button: "8px"
  field: "12px"
  story-media: "16px"
  map-preview: "18px"
  contribution: "20px"
  story-category: "22px"
  map-controls: "24px"
spacing:
  compact: "8px"
  small: "12px"
  field: "16px"
  group: "20px"
  section: "24px"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.white}"
    padding: "14px 24px"
  button-auth:
    backgroundColor: "{colors.auth-red}"
    textColor: "{colors.white}"
    rounded: "{rounded.auth-button}"
  input:
    backgroundColor: "{colors.white}"
    rounded: "{rounded.field}"
    padding: "16px"
  story-card:
    backgroundColor: "{colors.story-cream}"
    textColor: "{colors.story-ink}"
    rounded: "{rounded.story-category}"
    padding: "12px 16px 14px"
  category-banner:
    backgroundColor: "{colors.category-clay}"
    rounded: "{rounded.story-category}"
    padding: "16px 20px"
  bottom-navigation:
    height: "82px"
  map-controls:
    backgroundColor: "{colors.parchment}"
    rounded: "{rounded.map-controls}"
  map-preview:
    backgroundColor: "{colors.parchment}"
    rounded: "{rounded.map-preview}"
---

# Design System: Varasa

## Overview

**Creative North Star: "Living traditions"**

Varasa restores the original supplied interface: shaped parchment headers, curved illustrated navigation, cream social stories, floral login, arch game cards and an ornamental profile. The five images in `.impeccable/references/` and the original project assets govern this identity. The owner rejected the intervening generic composition; keeping only its palette and logo is insufficient.

Artwork defines the structure as well as the decoration. Preserve its silhouettes and pair decorative cultural headings with the warm handwritten voice of social stories. Backend and repository improvements remain behind this interface. This document records the current restoration, not whole-surface approval or a new visual direction.

**Key Characteristics:**
- Original shaped PNG artwork retained as structural chrome.
- White canvas, cream stories, parchment framing and brown ink.
- CinzelDecorative headings, CormorantGaramond titles and Itim social copy.
- Curved illustrated mobile navigation with a prominent plus and avatar.
- Honest demo, loading, error and unavailable-game states.

**Evidence and limits:** Source inspected in `apps/varasa/lib/core/theme/varasa_theme.dart`, `core/widgets/heritage_chrome.dart`, `app/varasa_shell.dart` and feature widgets. Inspected `.impeccable/review/phone-home.png`, `phone-games.png`, `phone-heritage.png`, `phone-profile.png` and `phone-login.png` against supplied references. These are Flutter renderer captures using loaded fonts and precached assets, not physical-device screenshots. The capture test also defines a wide home capture and small-screen/text-scale checks. The coordinating validation pass reports 9 Flutter tests, 10 backend tests, web JavaScript build and Android debug APK build passing; consult `docs/VALIDATION.md` for execution evidence. Physical-device runtime, connected Firebase authentication/OAuth, live map tiles and complete accessibility remain unverified. A build does not certify those behaviors. No Flutter design detector is available; this is manual source/capture extraction. Frontmatter `px` means Flutter logical pixels before text scaling. Sidecar browser samples are illustrative translations, not authoritative app renders.

## Colors

Warm parchment frames a white canvas. Cream separates stories; brown ink anchors controls and copy. Exact reusable authored values appear in the frontmatter; raster artwork contains additional colors that are not flattened into palette tokens.

### Primary
- **Ink:** actions, active navigation, headings and general foreground; also the seed for Material semantic colors.
- **Muted clay:** inactive navigation artwork and unliked story action artwork.

### Secondary
- **Terracotta:** theme secondary role; generated Material container colors remain framework-owned.
- **Category clay:** illustrated collection banners.
- **Auth red:** rectangular primary login/signup action. The login heading has its own nearby red in source.
- **Error:** theme validation and submission feedback. Auth also defines a darker error foreground locally.

### Neutral
- **White:** scaffold canvas, field fill and selected inverse foregrounds.
- **Story cream / story ink:** social card surface and caption foreground.
- **Parchment:** map panels, standard app bars and image fallbacks; shaped header/navigation colors also come from their assets.
- **Paper:** Material surface role, not the restored scaffold background.

**The Original Artwork Rule.** Preserve the supplied asset colors and silhouettes; do not replace them with generic rectangles or a newly invented ornament system.

## Typography

`CinzelDecorative`, `CormorantGaramond` and `Itim` are bundled and registered in `pubspec.yaml`. CinzelDecorative supplies the heritage display character; CormorantGaramond supplies game, category and contribution titles; Itim supplies story authors, captions, game supporting copy and profile biographies. Ordinary fields, controls and supporting interface copy inherit Flutter Material typography. No custom fallback stack is configured; platform text rendering may differ.

The display role records the Games title's explicit line height. The theme headline role is used for detail headings. Category item titles use CinzelDecorative at 22 logical pixels; contribution headings use CormorantGaramond at 24. The login heading uses system bold at 28 with letter spacing 2. These local roles are not a universal scale to apply indiscriminately.

**The Reading Voice Rule.** Preserve Itim on social copy while leaving forms and utility controls readable in their existing Material text styles.

## Layout

The mobile shell preserves the screenshot composition. Community starts below a 150-pixel shaped header with a centered 32-pixel-high logo. Games, contribution and heritage use the 88-pixel scalloped header with a left-aligned 28-pixel-high logo. Profile supplies its own ornamental header. Header assets use `BoxFit.fill` to retain their transparent contours. The header container caps at 900; ordinary content caps at 760; Games caps at 640.

Community uses 12 horizontal, 8 top and 20 bottom padding. Its centered “All Posts / Following” filter precedes cream cards by 20 pixels. Stories place caption before image; media has aspect ratio 1.65. Profile contributions form two square columns, with rounded imagery or text/attachment fallbacks. Collection categories use illustrated banners, followed by full-width image rows rather than thumbnail lists.

The bottom navigation is 82 pixels high within a bottom SafeArea. At available width >= 900 and height >= 640 × textScale, the shell substitutes a labeled Material navigation rail; textScale samples `MediaQuery.textScalerOf(context).scale(16) / 16`. Tabs remain in a lazily populated IndexedStack. This wide adaptation preserves the art header and centered content instead of introducing a different product composition.

Games uses a PageView with viewport fraction .84 and no end padding, exposing the neighboring arch. Card height follows `(width × .84 × 602 / 329).clamp(450, 620)`, plus `(textScale − 1) × 140` above normal scale. Content scrolls vertically. Auth centers a maximum-520-pixel panel; its background stretches to the scrolling content and the form uses 15% side insets. Form position follows the authored proportional frame, with space to scroll when the keyboard or text scaling reduces room.

The restoration test exercises 390×844 phone captures, 320×640 tabs at 160% text, 1200×900 wide home, and a 320×500 login scroll at 160%. Exception checks and selected captures establish only that scope, not exhaustive fit or accessibility.

## Elevation & Depth

Most depth comes from white space, cream surfaces and the original raster artwork. Story cards have no authored shadow. Cultural map controls use Material elevation 2 and the bottom preview/status panel elevation 5. Dialogs, menus, floating buttons and other Material controls retain framework behavior; there is no custom global shadow scale.

Carousel arrow navigation animates for 250 ms with `Curves.easeOut`. Other interaction feedback largely uses Material defaults; no broader custom motion vocabulary is specified.

## Shapes

The primary shape language is asset-based: `appbarbg.png` for the home drop-shaped header, `gemsappbarbg.png` for the scalloped header, `navbar_bg.png` for the curved navigation surface, `challasbg.png` / `gamebg1.png` for complete game arches, and `background2.png` / `logo_pattern.png` for the profile silhouette and avatar ornament. The floral login frame is `assets/images/background.jpg`.

Preserve these full silhouettes; `BoxFit.fill` is intentional in their source containers. Do not crop arches into ordinary rounded rectangles. Rounded story/category cards, media, contribution tiles and map panels use the specific frontmatter radii. Avatars and the prominent plus remain circular. Other button/menu shapes are framework defaults unless overridden locally.

## Components

### Header and navigation
`HeritageHeader` overlays the Varasa logo and contextual actions on the authored header asset. Search has a tooltip; a compact “Demo” or “Local” action opens environment information instead of the rejected full-width development banner. Mobile navigation uses original home/dice/plus/scroll/avatar assets. Its labels are accessible tooltips, not visible text below every icon. Selected icons become ink; inactive artwork is muted clay. The plus is a 50-pixel circle; the avatar uses radius 21 and a selected border. Rail labels remain visible. The community map action floats above this chrome.

### Stories and filters
`PostCard` has a cream rounded surface, 16-pixel bottom margin, author/avatar row, caption, optional image, optional place, optional attachment and illustrated like/discuss/share actions with tooltips. The author uses Itim; the caption uses the story-body role. `All Posts / Following` is a rounded segmented control with an ink selected fill. Following is loaded through its repository query; do not describe it as the old client-filtered bounded window.

`PagedList` provides refresh, loading, retry, empty, “Load more” and end states for feed/profile. It supports two columns for profile. These current states replace the obsolete 300-story-window footer description. Current story detail and repository-driven social actions retain their existing loading/error behavior.

### Games
“FORGOTTEN GEMS” introduces the original arch carousel. The first card keeps the Challas Aath artwork, white CormorantGaramond title and Itim description, parchment availability action and circular information action. Arrow buttons and swipe navigate. Unavailable integration shows “Coming soon” and copy explaining that Unity is not included; the artwork is not evidence of playable integration. The next arch introduces more planned games.

### Authentication
The complete floral frame surrounds the login/signup form. Fields retain labels, validation, autofill and password visibility controls. The red primary action has an 8-pixel radius. Connected mode exposes create-account/sign-in switching, password reset and the white Google action with original icon. Demo mode disables credential fields, shows “ENTER LOCAL DEMO” and explains sample data/reset behavior. The inspected capture demonstrates demo login composition only; connected authentication and OAuth remain unverified.

### Heritage collection
Category banners combine CormorantGaramond uppercase names and contained 100×100 illustrations. Category detail/search results use 112-pixel-tall image rows with a translucent white overlay and centered decorative title. Search, “All heritage” and original article text remain. The reviewed heritage capture shows the Paintings category, not every collection state.

### Profile
The profile owns its parchment silhouette, logo/options row, 122-pixel ornament and circular avatar of radius 40. Username, name and Itim bio precede the white shaped statistics area. **Posts sits above Followers / Following.** While another page may exist or loading is active, its label is “Posts loaded”; first loading may show an ellipsis. This is a loaded-record count, not a backend aggregate. Friends stays under the owner’s “Community & account” expansion with requests, blocks and account/data access. Owner actions are Edit profile / Share profile; other profiles expose relationship actions. Contributions remain a two-column image grid with fallbacks. Profile editing stages photo replacement/removal for save; production upload persistence is not certified by layout captures.

### Cultural map
The community floating action opens a map with parchment controls (back, title, refresh and list/map toggle) at top 12, capped to width 600. A bottom parchment panel, capped to 560, reports loading scope or previews the selected pin with optional image, place, excerpt, close and “View full story.” Pin selection changes its color. The list alternative and retry/load-more states remain available. Tile error feedback starts at top 96 in the map viewport, below the overlay controls; it is not an additional 96-pixel gap below the controls. Attribution stays with the map. No live-map renderer capture or tile/network certification is claimed.

### Utility controls and states
Shared inputs remain white, padded and outlined. Filled, outlined and text buttons retain authored minimum size 48×48, with framework-owned states except local overrides. Errors, unavailable images, pending actions and empty collections must remain explicit. Tooltips and semantics in source do not establish screen-reader quality, focus order or full contrast compliance.

## Do's and Don'ts

### Do:
- Do preserve the original shaped assets and supplied screenshot composition.
- Do keep caption-first cream stories and the illustrated mobile navigation.
- Do preserve Posts above Followers / Following and label incomplete counts as loaded.
- Do keep Friends and account tools in Community & account.
- Do retain functional loading, error, demo and unavailable-game states.
- Do keep wide and large-text adaptations faithful to the same artwork and hierarchy.

### Don't:
- Don't reintroduce the rejected generic cards, rectangular headers or labeled mobile bar.
- Don't crop away the game arches, floral frame or ornamental profile shape.
- Don't replace original article text or claim that Unity is playable.
- Don't treat demo captures, successful builds or browser samples as connected/native runtime verification.
- Don't describe this document as whole-surface visual or accessibility approval.
