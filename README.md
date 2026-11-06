# Alt Ledger

Remembers what each of your characters carries and how much gold they have. When you hover an item, the tooltip shows which of your **other** characters hold a copy that could actually reach you: unbound items, and on Retail, warbound ones too.

Supports Retail, WoW Forever, Classic Era, Anniversary and Mists of Pandaria Classic.

## Which characters count

A count only helps if the item can get to you, so the characters shown depend on the client:

| Client | Characters shown | Why |
|---|---|---|
| Retail | Every character in the same **region** (NA, EU, KR, TW, CN), any realm or faction, plus the Warband bank | The Warband bank moves unbound and warbound items and gold across realms. NA and EU are separate warbands. |
| WoW Forever | Same **ruleset** and faction | Forever has rulesets instead of realms, and characters can't change ruleset. |
| Other classic clients | Same **realm** (and connected realms) and faction | Mail and trade only reach that far. |

You can override this in settings (**Characters shown**). `/ledger scope` prints what the current client decided.

## What it tracks

- **Bags** (including the Retail reagent bag), **bank** (Retail bank tabs, or the classic bank, bank bags and reagent bank), **mailbox** and **equipped** gear.
- **Warband bank** contents and gold on Retail.
- **Gold** per character.

The bank and Warband bank are recorded when you open them; the game doesn't report them otherwise. Every item is stored as either *free* (could reach another character) or *bound*. Tooltips only use free counts.

## Commands

`/ledger` (or `/ledger gold`) lists gold for every character in scope. `/ledger options` · `/ledger scope` · `/ledger forget Name-Realm` · `/ledger debug`

## Potential improvements

- **Guild bank contents.** Record each guild's bank tabs when the guild bank is opened (`GUILDBANKBAGSLOTS_CHANGED`) and the guild's gold, then show them on tooltips as their own row, scoped like characters (Retail guilds are realm-bound, so same realm or connected realm). Only tabs the character can view are readable, so each tab needs its own "last seen" time.
- **Auction house and void storage.** Owned auctions (`C_AuctionHouse.GetOwnedAuctions`) and void storage, as more locations.
- **Mail expiry.** Warn when a character's mailbox has items about to return or be deleted.
- **A window.** Search items across characters and sort characters by gold, instead of tooltips and slash output only.
- **Gold over time.** Daily snapshots per character to chart income.
- **Stale data.** Show how old a character's record is, and flag characters not logged in for a long time.

## Development

- Dependencies: AceEvent-3.0 only (plus LibStub and CallbackHandler). Settings, tooltips and timers are native.
- `luacheck .` must report zero warnings.
- `busted` runs the specs in `spec/` (scope rules, holder and gold aggregation, and the locale master list).
- `Localization/enUS.lua` is the master phrase list. CI uploads it to CurseForge before packaging (`npm run upload-locale`; `node uploadLocale.js --dry-run` to check). Every `L["..."]` the code uses must be listed there; a spec enforces this. The upload needs `## X-Curse-Project-ID:` in the TOC once the CurseForge project exists.
