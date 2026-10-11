# Varasa

Varasa is a four-person final-year project combining a cultural social community with traditional folk games. The owner asked for a consolidated rebuild in `Development/Projects/Varasa`, a uniform collaboration structure across macOS and Windows, and substantial improvements without losing the original vision or similar UI.

Primary activities: share stories and media about traditions; discover people and cultural content; learn about folk games; eventually play the original Unity Challas Aath game inside the mobile app.

The existing implementation establishes the visual identity: Varasa logo and artwork, warm parchment and brown colors, CinzelDecorative display headings, a social feed, a cultural collection and Forgotten Gems. This pass refines that established identity, not a replacement brand.

Confirmed constraints: preserve historical copies; testing explicitly authorized on 10 October 2026; provide logs and runnable commands for the owner to validate later. Unity source is on another computer, and the owner explicitly asked to leave integration for now.

Implementation assumptions: Chrome is the shared development target on Mac and Windows; Android and iOS are mobile deployment targets. The local demo is explicitly temporary and sample-based. Connected mode uses Firebase. These are documented engineering decisions rather than inferred evidence of the original team's deployment plan.

This pass is not a production launch. Flutter analysis, local tests and rendered-screen checks have been performed; see docs/VALIDATION.md for exact scope. Physical-device and production-connected behavior remain unverified. Existing cultural descriptions are preserved student-project content, pending an editorial source review.

## Confirmed restoration direction — 11 October 2026

The owner rejected the intermediate generic UI. Their five saved screenshots in `.impeccable/references/` govern the restored design: shaped parchment headers, curved illustrated navigation, cream social stories, floral login frame, arch game carousel, illustrated collection rows, ornamental profile and floating map access. Use original project assets and preserve this composition; backend improvements remain behind repository contracts. Flutter renderer captures are evidence of layout only, not native-device or live-map certification.
