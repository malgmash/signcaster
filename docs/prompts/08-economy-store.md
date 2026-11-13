# 08 Coins, stars and the QB store (M8)

| | |
| --- | --- |
| Branch | `feat/economy-store` |
| Best with | Either agent |
| Needs | M7 merged |

## Prompt

```text
Add coins, stars and the QB locker room store to Signcaster. Follow AGENTS.md.

Read first:
- docs/GAME_DESIGN.md: "Rewards and store"
- docs/DATA_FORMATS.md: "Store catalog", "Economy config", "Save file" (wallet, owned_items, equipped)
- docs/EVENTS.md: "Economy and store"
- docs/adr/0004-privacy-and-fair-play.md

Goal: coins earned in play buy cosmetic items in the locker room, and equipped items visibly change the QB.

Do this:
1. economy.gd: wallet with add and spend, coins per success, fast bonus and perfect level bonus from economy.json. Emit coins_changed with a reason. Keep data in memory and expose to_dict and from_dict for SaveSystem (M10 writes it to disk).
2. store.gd: load catalogs from Config, check unlock rules, buy_item (emit item_purchased or purchase_failed with the exact reasons from EVENTS.md), equip_item (emit item_equipped), owned and equipped queries.
3. Game facade: buy_item and equip_item forward to Store.
4. Locker room scene in game/skins/qb/store/: grid of item cards (name, art, price with coin icon, Buy, Equipped, or "Unlocks at ..." states), coins counter in the corner, preview of the QB wearing the selected item.
5. Apply equipped items in the QB skin (helmet, jersey, cleats, football, stadium, celebration).
6. Level complete screen: stars earned, coins earned with a short count-up animation, buttons for Next, Retry and Store.
7. Validator: confirm scripts/validate_content.py rejects gameplay keys on store items (add a test case file under scripts/tests/ if needed).
8. Tests: spend more than balance fails, locked items fail, buying twice fails, equip requires ownership, bonuses add up correctly for a perfect level.

Rules:
- Cosmetic only. No item may touch timers, scoring or difficulty.
- No real-money purchases, ever.

Before editing, give me a plan and the list of art placeholders you need. Wait for my OK.

When done, tell me how to earn coins quickly in a debug build (a debug-only cheat key is fine if it is compiled out of release builds).
```

## After the agent finishes

- [ ] Earn coins, buy the retro jersey, see it on the QB in the next drive.
- [ ] Try to buy a locked item. The message should be clear and friendly.
- [ ] Check that store items have no gameplay fields: `python scripts/validate_content.py`.
