$api    = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1/videos'
$apiKey = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$headers = @{
    'apikey'        = $apiKey
    'Authorization' = "Bearer $apiKey"
    'Content-Type'  = 'application/json'
    'Prefer'        = 'resolution=ignore-duplicates,return=minimal'
}
$niche = 'Escape Tsunami Brainrot'

$records = [System.Collections.Generic.List[hashtable]]::new()

function Add($cid, $cn, $vid, $title, $views) {
    $script:records.Add(@{
        channel_id   = $cid
        channel_name = $cn
        niche        = $script:niche
        title        = $title
        video_id     = $vid
        url          = "https://www.youtube.com/shorts/$vid"
        views        = [long]$views
    })
}

# Adrsh Roblox
$c = '67394108-1b21-412c-9cab-cb9f15c02864'; $n = 'Adrsh Roblox'
Add $c $n 'vqHQEG9b5fA' 'Dad Tricked the Police 😳' 3800000
Add $c $n 'LpGR68RUqnE' 'Bro Really Drew THIS 😭' 635000
Add $c $n '0WeQbcuFArg' 'He Forgot His Wife 💀' 1700000
Add $c $n 'RoMmD_lhRiE' 'The Last Banana' 6300000
Add $c $n '8Qj5WXOZUp0' 'Fake Girlfriend Gone Wrong 😭' 1400000
Add $c $n 'fTwOgLFnFdk' "This Experiment Shouldn't Exist 💀" 320000
Add $c $n 'd2U48vkZELk' 'The Lion Who Chose Not to Kill🥹' 1500000
Add $c $n 'wSLekZ8hGUA' 'Sky King One Last Flight😭' 2500000
Add $c $n 'Bn9Heqm4Pv8' 'Why You Should NEVER Kill Spiders 🕷️' 656000
Add $c $n 'mhpO_UHeOT4' 'He Sold His Childhood… For THIS 😳🐶' 175000
Add $c $n '7Z7_hi0hZBQ' 'This Thief Is a MasterChef 😂' 267000
Add $c $n 'qyeEatR5r30' 'Groom Saves Drowning Boy Mid-Wedding 😳' 1200000
Add $c $n 'CQcGY84XQKs' 'If You Could Create Unlimited Money 🤯' 172000
Add $c $n 'ZohvZVSYFBk' 'She Fell… But Waited Silently 😨' 3400000
Add $c $n 'Iy0nlqm7ZjM' 'Anything… Not Everything 💀' 7400000
Add $c $n 'fnNDj_SZQKk' "A Father's Last Hope🙁" 3100000
Add $c $n '5BdkqxPMeQ4' 'The Mandela Effect' 183000
Add $c $n 'KLozDpqu1ro' 'The Doctor Who Saved a Boy…😳' 8200000
Add $c $n 'B8cTJH0yafs' 'The Reason You Quit Too Soon 💀' 228000
Add $c $n 'XEdnoEejZLk' 'Russian Sleep Experiment🇷🇺💤' 1200000
Add $c $n '9v1O9tmmouw' 'Biggest Save of the Year 😂🔥' 1000000
Add $c $n 'jISMMQtohHE' 'This Man Wanted Fame… But Did THIS 😳' 126000
Add $c $n 'IKIbK1X6YcY' 'Why Humans Fear the Dark?' 120000
Add $c $n '5UqCBTSdm5M' '#dublagem' 104000
Add $c $n 'Oj1PKuXPJiQ' 'Are We Living in a Simulation? 😳' 103000
Add $c $n 'l4vWHq8eUoA' 'You Wake Up on a Ladder in the Sky…🤯' 295000

# Haro
$c = '1c64955c-2501-45cc-8684-0dcd6d490b6b'; $n = 'Haro'
Add $c $n 'NT2BX1_nji4' 'Roblox Sound Recreated with Instrument that will hit you with Nostalgia' 76000
Add $c $n 'hV-fVHdsH_Y' 'Funniest Roblox Face Verification' 138000
Add $c $n 'ZYYJHqFVKt8' 'Roblox Sounds with so much Nostalgia' 108000
Add $c $n '29xXn6r_6pk' 'Roblox Real Life Sound that Brings Back so much Nostalgia' 19000000
Add $c $n '04xsnwOApjg' 'Roblox Real Life Moments #roblox #foryou' 101000
Add $c $n 'YGapMST8PAI' 'Roblox Real Life Sound' 480000
Add $c $n 'g3qEtdtBhjA' 'Genius Roblox Spelling Moments #roblox #foryou' 104000
Add $c $n 'xb1Y2N8Mtww' 'Funniest Impress Huzz Moments  #roblox' 162000
Add $c $n 'ezsoAxYbSiY' 'Fastest Roblox Spelling Moments #roblox #foryou' 115000
Add $c $n 'PFtfSnPhERQ' 'Roblox Real Life 99 Nights in the Forest #roblox #foryou' 50000
Add $c $n 'rcrmNaun7JI' 'Fastest Roblox Spelling Moments #roblox #foryou' 131000
Add $c $n 'UgqHs_gZmlw' 'Crazy Fast Spelling Moments on Roblox #roblox #foryou' 2100000
Add $c $n 'njTpQFuHZ9M' 'Fastest Roblox Spelling Moments #roblox #foryou' 233000
Add $c $n 'QCbBp9fLbwM' 'Fastest Roblox Spelling Moments' 5600000
Add $c $n 'abX5xcHLyeA' 'Best Roblox Boat Ried Moments #roblox #foryou' 63000
Add $c $n 'TrmFUYomN5E' 'Best Roblox Real Life Sound #roblox #foryou' 625000
Add $c $n '_yx5q0nhp4Y' 'Funniest Roblox Penguin Knockouts #roblox #foryou' 67000
Add $c $n 'ruDjuT17sZM' 'Best Roblox Spelling Moments #roblox #foryou' 1300000
Add $c $n 'Ui61Gr-5Ipo' 'Best Roblox sound recreation #roblox #foryou' 144000
Add $c $n 'bKNSnaBK1lY' 'Best Roblox Rizz Moments #roblox #foryou' 238000
Add $c $n 'ZS7H1xFImY4' 'Roblox Cutest Moments' 160000
Add $c $n 'GeHB9b0dOP8' 'Best Roblox Sound in Real Life #roblox #foryou' 307000
Add $c $n 'FG45dpWjnlw' 'Ranking Best Roblox Draw Me Moments' 73000

# BradeyRoblox
$c = '20c2f302-9806-4a47-a9e0-8c178ed29152'; $n = 'BradeyRoblox'
Add $c $n 'v2ClIz-ZjZw' 'Hide and seek in Sammys secret spot🤯' 1000000
Add $c $n 'g_gTO71ZcDg' 'Sammy spawns Secret base🤯' 14000000
Add $c $n 'bduBZHbKlK8' 'Sammy was nice to him 🥺' 9300000
Add $c $n 'MTQFyjKFBWk' 'Sammy opens Secret door 🤯' 13000000
Add $c $n 'D0F78RjLenI' 'Sammy spawns Cyber brainrot🤯' 5800000
Add $c $n 'rZMpEW01RvM' 'Sammys Girl left Sammy🥺' 8600000
Add $c $n 'MI3BB26Hbtk' 'She destroyed Sammys brainrots😲' 5100000
Add $c $n '7DLIq3XoCVo' 'Sammy gives bacon ADMIN powers🤯' 1800000
Add $c $n 'Wa-HpEw-N6I' 'Sammy Admin Powers vs Troll🤯' 4200000
Add $c $n 'mLQOs6HwDuM' 'Sammys Girl did something Crazy🤯' 8500000
Add $c $n 'R89imA_1uFI' 'Sammy helps kind bacon🥺' 2700000
Add $c $n 'LIdPdaImbNc' 'Sammy gives bacon Big Surprise🤯' 2900000
Add $c $n '3CkVMyIGBe8' 'Sammy used his Admin Powers🤯' 5900000
Add $c $n 'jmLhUwNrrSI' 'Sammy helps bacon with Easter Event🤯' 1600000
Add $c $n '0C97a1Jl-Ck' 'Sammy surprised us🤯' 1900000
Add $c $n 'RzQQZB2I6Ts' 'Sammy used ADMIN Commands 🤯' 4400000
Add $c $n '-8D92UDJu7Y' 'Steal a brainrot Troll vs Pro🤯' 1100000
Add $c $n 'eH9_EjFNIJQ' 'Sammy was testing them😳' 2900000
Add $c $n 'W7tM1GRQFVI' 'Sammy gives bacon Best brainrot🤯' 6100000
Add $c $n 'siP-cKeNI04' 'Brainrot clutch moment🤯' 1800000
Add $c $n 'KbB20vVVQsQ' 'Sammy vs troller moment🤯' 4600000
Add $c $n 'tQZ6jVU2eMM' 'Bacons are nice😊' 1200000
Add $c $n 'gQn9EKwF2Fk' 'Sammy helps Bacon🤯' 4000000
Add $c $n 'HOt-66uFRqg' 'Sammy undercover as Bacon💀' 1400000
Add $c $n 'VQQiM3H8AmU' 'Hacker vs Sammy moment🤯' 1700000
Add $c $n '4XvcQm0qm0g' "Troller didn't Know Sammy is my Friend💀" 771000
Add $c $n 'MphdFwjb87k' 'Sammy did something crazy 🤯' 2300000
Add $c $n 'pvNurEkgtL8' 'Hide and seek for OP brainrot🤯' 3400000
Add $c $n 'hiEAVuBkz0s' 'Sammy joins to help🤯' 1300000
Add $c $n 'A_mJIOMN6Mc' 'Sammys Girl Stole my Strawberry Elephant 🤯' 1800000

# Puddles
$c = 'ac85f624-aa80-4f14-92dc-78cbf84161a7'; $n = 'Puddles'
Add $c $n 'MA6Hg5xn9Lo' 'triple t is gone from roblox again 🥺💔' 13000
Add $c $n 'e2RxyJ7PAfI' 'Roblox Shirts in 2026.. 😂💀' 583000
Add $c $n '6eigYklPo9A' 'Old vs New Roblox Games.. 🤔😲' 24000
Add $c $n 'y_I9kADKZcA' 'Countries With The Most Roblox Players.. 🤔😲' 811000
Add $c $n 'K3Khjfb9fTA' 'Roblox Youtubers Who Went To Jail.. 🤔😲' 57000
Add $c $n 'x5NbGOoUuF8' 'Countries That Banned Roblox.. 🤔😲' 1700000
Add $c $n 'kq0Em1ujRBk' 'TOP 10 BEST Roblox Streamers.. 🤔😲' 530000
Add $c $n 'e4kQCC0t3DI' 'Roblox Games Throughout The Years.. (2026) 🤔😲' 809000
Add $c $n '-afEv7P85V8' 'TOP 10 Roblox Games That REFUSE To Die.. 🤔😰' 1800000
Add $c $n 'gBWZatZySFw' 'Roblox Users That Passed Away.. 😢😰' 43000
Add $c $n 'BN-53ln3B1Y' 'Roblox Games That Everybody Forgot About.. 🤔😰' 54000
Add $c $n 'rcCO7xuJwpk' 'TOP 10 Most Followed Roblox Players.. 🤔😰' 1000000
Add $c $n 'Kn0M1HLuBzs' 'TOP 10 BEST Weapons in 99 Nights.. 🤔😰' 158000
Add $c $n 'wlQL62Gu8i4' 'TOP 10 BEST Roblox Developers.. 🤔😰' 831000
Add $c $n 'V830f6iaqnA' 'TOP 10 Most HATED Roblox Games.. 🤔😰' 1100000
Add $c $n 'ycLyetTBF6E' 'Roblox Games That Copied Other Games.. 🤔😰' 260000
Add $c $n 'BR2oM01hcVA' 'TOP 10 Most Feared Roblox Hackers.. 🤔😰' 861000
Add $c $n 'qfzvkWG8mUM' 'Most Loved Roblox Youtubers in 2026.. 😂💀' 462000
Add $c $n 'SBB9HGhQjF0' 'Roblox Games That Were Forgotten.. 🤔😰' 137000
Add $c $n 'ies-q1E9-Sk' 'TOP 10 Roblox Games With The Most Visits.. 🤔😰' 332000
Add $c $n 'NSfshTeUZms' 'TOP 10 Roblox Games That Earn The Most.. 🤔😰' 180000
Add $c $n 'gMV1udFcdz4' 'Roblox Games That Are Slowly Dying.. 🤔😰' 116000
Add $c $n 'qjTouUEz79c' 'TOP Roblox Games That Became Forgotten.. 🤔😰' 215000
Add $c $n 'ALeeTtb7ThY' 'TOP 10 Most POPULAR Roblox Youtubers.. 🤔😰' 240000
Add $c $n 'Gq3nDji6f2c' 'TOP 10 DANGEROUS Entities in 99 Nights.. 🤔😰' 370000
Add $c $n 'ahTYSgjSdrs' 'TOP 10 BRAINROT Roblox Games.. 🤔😰' 398000
Add $c $n 'osglvWzwUnw' 'TOP 10 BIGGEST Roblox Groups.. 🤔😰' 316000
Add $c $n 'yiN956w4Uak' 'TOP 10 RICHEST Roblox Players.. 🤔😰' 1100000
Add $c $n 'qn8s9IsPt30' 'TOP 10 OLDEST Roblox Youtubers.. 🤔😰' 2800000
Add $c $n 'OK-D9pWOJ9A' 'TOP 10 Roblox Games That Will NEVER Die.. 🤔😰' 3900000
Add $c $n 'RZZ5-ijkcGI' 'TOP 10 BEST Roblox Avatars.. 🤔😰' 109000
Add $c $n 'JdYu_oxVTdc' 'TOP 10 Most SUCCESSFUL Developers.. 🤔😰' 1500000
Add $c $n 't_cCTYRVDks' 'TOP 10 Most FAMOUS Faces in Roblox History.. 🤔😰' 488000
Add $c $n 'fSPdzLS8Eog' 'TOP 10 Most HATED Roblox Players.. 🤔😰' 196000
Add $c $n '5HuDyLbQdv4' 'TOP 10 OG Roblox Items (2026).. 🤔😰' 132000
Add $c $n 'igj4FY1gtxA' 'Roblox Hairs in 2026.. 😂💀' 46000
Add $c $n 'O_tzhOSv_Ks' 'TOP 10 DEAD Roblox Games.. 🤔😰' 324000
Add $c $n 'sNZzfncPX6U' 'Top 10 Roblox Games Everybody Played.. 🤔😰' 883000
Add $c $n 'wVh3PZpbIOU' 'Roblox Biggest Youtubers In 2026.. 🤔😰' 968000
Add $c $n 'hdJCQOigRYw' 'TOP 10 Roblox Games That Dissapeared.. 🤔😰' 326000
Add $c $n 'TF22zB9LPVE' 'TOP 10 Roblox Youtubers Who Dissapeared.. 🤔😰' 2600000
Add $c $n 'RFBMQdZXXvk' 'TOP 10 OG Roblox Sounds (2026).. 🤔😰' 1500000
Add $c $n 'A8W4_qMZMAk' 'TOP 10 Dangerous Roblox Hackers.. 🤔😰' 2700000
Add $c $n 'm2ISuxeabes' 'TOP 10 Nostalgic Roblox Games.. (2026) 🤔😲' 2400000
Add $c $n 'CFF9SFHWaxM' 'Roblox PLAYER Count In 2026.. 🤔😲' 508000
Add $c $n 'O-o4l6AtdeI' 'Roblox Faces in 2026.. 😂💀' 2200000
Add $c $n 'MUXJVy7rqSg' 'Roblox Avatars In 2026.. 🤔😲' 484000
Add $c $n 'lUesD-PXD8k' 'TOP 10 Roblox Games.. (2026) 🤔😲' 374000

# BlueRblx
$c = 'e21a498e-1ebf-49f4-adf5-ed01eb68cb58'; $n = 'BlueRblx'
Add $c $n 'r4m4Y_QB-Aw' 'Roblox Admin Moment😭 #roblox' 459
Add $c $n 'uUI9XqwK3Ps' 'roblox wallhop challenge🤯🙏 #roblox' 309000
Add $c $n 'bFCqLdw_0MM' 'Roblox speed Challenge🤯 #roblox' 156000
Add $c $n 'XWn_NA1PDrI' '💀Roblox Revenge #roblox' 77000
Add $c $n 'Rd5xuACbHRE' 'roblox progression challenge' 91000
Add $c $n 'qXE7TwSxcGg' 'roblox HACKER moment💔😭 #roblox' 257000
Add $c $n 'ErTQ4QQdSvY' 'Roblox jump Challenge💀 #roblox' 1400000
Add $c $n 'AD4Zt627pJc' 'old roblox💖 #roblox' 118000
Add $c $n 'qJ_0wWBfYSU' 'Roblox Wallhop clutch 😱#roblox' 415000
Add $c $n '8vSvxg0R-VU' 'Roblox Wallhop Challenge😭 #roblox' 6500000
Add $c $n 'GgZKDbxu0sY' 'I found SPEED Secret BASE😭🙏#roblox' 2300000
Add $c $n '9lK9QubDCBY' 'Shark Troll Base😭🙏#roblox' 133000
Add $c $n 'LY3NCLJptnc' 'Hidden Owl Troll Base😨 #roblox' 837000
Add $c $n '1NjZ3Q8fhtE' 'Hidden Polar Bear Troll 💀 #roblox' 168000
Add $c $n 'hmOexW7aFVU' 'Hidden 67 Troll PT.2 #roblox' 9300
Add $c $n '8CI7g5hJ7Ew' 'Lightning Troll Button😭 #roblox' 112000
Add $c $n 'iJFjz7sckBg' 'Freddy Troll Base😭🙏 #roblox' 159000
Add $c $n 'U2hREbHk-qM' 'Hidden Bat Troll😂 #roblox' 135000
Add $c $n '2hL24aadXN8' 'Revenge Troll Base😭 #roblox' 112000
Add $c $n 'Bf0xpkMYDrc' 'Hidden Ram Troll 😭🙏#roblox #customuse @customuse3D' 4000000
Add $c $n 'pnu7sOgVk1s' 'Hidden Deer Troll PT.2💀 #roblox' 585000
Add $c $n 'CcHDlCzydHk' 'Cultist Troll Base😭 #roblox' 257000
Add $c $n 'zXVt-FSPId4' 'Hidden 67 Troll😂 #roblox' 222000
Add $c $n '2hCRKawII5U' 'Black Deer Troll Base🤯 #roblox' 182000
Add $c $n '_sOK6BtZ994' 'Wolf Troll Base😨 #roblox' 136000
Add $c $n 'TWP1myoC1zA' 'Brown Bear Troll Base😭 #roblox' 444000
Add $c $n 'fmsHlai_95k' '67 Button Troll😭💀 #roblox' 1500000
Add $c $n 'nfe_3N1MVQ4' 'Polar Bear Trolling😭🙏#roblox' 1700000
Add $c $n 'YAtlMR_CCv0' 'Ram Trolling Base😨 #roblox' 873000
Add $c $n 'k4Vf4JrR7j8' 'Trolling Deer From 99 Nights😭🙏#roblox' 1400000
Add $c $n '-dxFC9y0LvU' '67 Troll Base💀🙏 #roblox' 25000000
Add $c $n 'sCCdPnw_ZGU' 'Owl base Troll😭🙏 #roblox' 51000

# RobloxNoobReal
$c = '6153cfa0-1f4e-4c03-8601-1c32c08af47a'; $n = 'RobloxNoobReal'
Add $c $n 'iFSOB0ppK4I' 'Squidgame in Rivals 🤨' 6100
Add $c $n 'YAobgctUvJk' 'I Became a LITERAL Dinosaur 🦖' 8200
Add $c $n 'Usl0zPPfz9w' 'My Most EXPENSIVE Brainrot 🤑' 10000
Add $c $n '01ja_FtMZxc' "Bro Couldn't Resist The Lava 💀" 3700
Add $c $n 'JPJsz61eAcc' 'I ALMOST Got Hit Off… 😬' 14000
Add $c $n 'jnn1MYtL1Ac' 'Stealing As Many Brainrots As I Can 😈' 9000
Add $c $n 'shc67Tqo1cQ' 'Rivals in a MUSEUM 🤨' 7100
Add $c $n 'UhE2Yz-c9Ic' "Knockout But I'm TINY 😭" 55000
Add $c $n 'QvJV1ua0RDE' 'How I Became RICH 🤫' 10000
Add $c $n 'mcdyNSrc9Uo' 'NEW Map In Rivals… 🤨' 12000
Add $c $n 'GfqfOReo_mM' 'Winning as a Bowling Ball' 16000
Add $c $n '5iZE-_Eta6g' 'How to Get SLAVES in Steal a Brainrot 😳' 11000
Add $c $n 'MNL7toksYB8' 'NEW Gamemode In Rivals 😁' 10000
Add $c $n 'hzQoxzajm-Q' 'DOMINATING Knockout Snooker 😏' 25000
Add $c $n 'tDD2HiyqIz4' 'Stealing Triple T in Steal a Brainrot 🤫' 19000
Add $c $n '66IaxvDd0Eg' 'Playing Bridge On Rivals… 😈' 20000
Add $c $n 'GBF0Kqg6AJo' 'Playing Polar Portals Gone WRONG… 😳' 28000
Add $c $n 'E5Gr1P9JJOc' 'Stealing My FIRST Brainrot 😰' 17000
Add $c $n 'yJrJUhTrgNM' 'Playing Roblox Rivals Again 😈' 15000
Add $c $n '7osYOnmz0dY' 'Hot Potato Gone WRONG… 😱' 38000
Add $c $n 'Q_7LRHsf_yU' 'I Thought I Could Predict… 😭' 90000
Add $c $n 'NSJlADHdS-g' 'Playing Knockout Using FULL FORCE… 💥' 181000
Add $c $n 'UIviPOx8B60' 'Trying Knockout Doomsday… 😬' 205000
Add $c $n 'uLTu8B7NLoU' 'I Gave Him What He DESERVED… 😈' 288000
Add $c $n 'c88oCEHfhXc' 'Predicting in Knockout Polar Portals… 😳' 263000
Add $c $n 'YUHBw1KMz5w' 'NEW Knockout Gamemode… 🤔' 376000
Add $c $n 'Fru7RQeAH8U' 'BLOWN Up By A Potato… 😱' 169000
Add $c $n 'gXYA56MwvQ0' 'CHOSEN To Be Juggernaut… 😈' 83000
Add $c $n 'qzQqSkipM5k' 'This Guy BROKE Knockout… 😱' 1400000
Add $c $n '6gn8_qrkbiw' 'First Time Playing Rivals… 😳' 31000
Add $c $n 'lifRwmvHsb0' 'Playing Knockout Gone WRONG… 😭' 479000
Add $c $n 'tF2hqkN1yMY' 'Playing Knockout Color Tiles 😈' 386000
Add $c $n 'R0sittRo0rw' 'Knockout With Hot Potato 💥' 2400000
Add $c $n 'nI-19KmUOHg' 'How Did I NOT Fall? 😳' 422000
Add $c $n 'o2CypPmiGpI' 'Knockout but with a TWIST… 🤨' 81000
Add $c $n 'KiMiIxFGM9w' "I'm back playing Knockout… 😳" 220000
Add $c $n 'JtDzryOpYvg' 'You Guys ASKED For This… 😈' 1000000
Add $c $n 'qYPA5JIgTjw' 'Playing Knockout AGAIN… 😬' 144000
Add $c $n 'qTILGN2PpGU' 'My First Time Playing Knockout… 😳' 237000

# Gohanrobloxeditz
$c = 'e0a201bd-f7c0-4323-bc66-7239287e4e67'; $n = 'Gohanrobloxeditz'
Add $c $n 'GEHGnDahgps' '3 mistakes we all did as bloxfruit noobs #bloxfruits' 6000
Add $c $n '_FMcI5ileHk' 'Looking for raids in 2026 be like #bloxfruits' 6100
Add $c $n 'nOSg7Y5CNQk' 'what does an admin fishing rod do in Bloxfruit #bloxfruits' 11000
Add $c $n 'C_ygtTV_CS0' 'How to fix the new Bloxfruit aura Glitch #bloxfruits' 2200

# AvocadoBoyRoblox
$c = '495027ee-0e8d-4f5e-ba64-a68d4d1e6142'; $n = 'AvocadoBoyRoblox'
Add $c $n 'HsoAQXcfD0k' "I'm 2 days into college LYRIC PRANK 18 🤣🤣" 37000
Add $c $n 'oRe73nPlPNo' 'You Got Me Jumping LYRIC PRANK 9 🤣🤣' 3700
Add $c $n 'pW6blkZ-fF8' 'You Got Me Jumping LYRIC PRANK 8 🤣🤣' 160000
Add $c $n 'NxPcGQour7w' 'You Got Me Jumping LYRIC PRANK 7 🤣🤣' 107000
Add $c $n 'hQ6d07yVfDc' 'You Got Me Jumping LYRIC PRANK 6 🤣🤣' 93000
Add $c $n 'dlQ5Q90tRNw' 'You Got Me Jumping LYRIC PRANK 5 🤣🤣' 370000
Add $c $n '93-hqcWsvIM' 'You Got Me Jumping LYRIC PRANK 4 🤣🤣' 258000
Add $c $n 'rPka9Ie4qqc' 'You Got Me Jumping LYRIC PRANK 3 🤣🤣' 1300000
Add $c $n 'CpQ5cwJJgU8' 'You Got Me Jumping LYRIC PRANK 2 🤣🤣' 1800000
Add $c $n 'NWObgFG-xGk' 'You Got Me Jumping LYRIC PRANK 🤣🤣' 3600000
Add $c $n 'VJu6k9QORDI' '7 Year Old LYRIC PRANK 🤣🤣' 2300000
Add $c $n 'MfUX38GhTk4' "I'm 2 days into college LYRIC PRANK 17 🤣🤣" 1700000
Add $c $n '4WffS732b6c' 'Kinda Homeless LYRIC PRANK 11 🤣🤣' 50000
Add $c $n '-B4yv-tIWkg' 'Kinda Homeless LYRIC PRANK 10 🤣🤣' 61000
Add $c $n 'ibrCq5uqgI0' 'Kinda Homeless LYRIC PRANK 9 🤣🤣' 155000
Add $c $n 'jGVhx-qWs58' 'Kinda Homeless LYRIC PRANK 8 🤣🤣' 667000
Add $c $n 'Npbjwc6m2Ak' 'Kinda Homeless LYRIC PRANK 7 🤣🤣' 45000
Add $c $n 'h-jUEUxNsDY' 'Kinda Homeless LYRIC PRANK 6 🤣🤣' 1400000
Add $c $n 'M625TLWSeJk' 'Kinda Homeless LYRIC PRANK 5 🤣🤣' 60000
Add $c $n 'yAHD9sEShKg' 'Kinda Homeless LYRIC PRANK 4 🤣🤣' 142000
Add $c $n 'toLHgWIsSY4' 'Kinda Homeless LYRIC PRANK 3 🤣🤣' 36000
Add $c $n '69pVCJprB5c' 'Kinda Homeless LYRIC PRANK 2 🤣🤣' 124000
Add $c $n 'VTfFHayxEhQ' 'Kinda Homeless LYRIC PRANK 🤣🤣' 695000
Add $c $n 'ybYVkjgK7fQ' "I'm 2 days into college LYRIC PRANK 16 🤣🤣" 134000
Add $c $n 'iT4m8BIMAGU' "I'm 2 days into college LYRIC PRANK 15 🤣🤣" 74000
Add $c $n 'aCTJTmk-KV8' "I'm 2 days into college LYRIC PRANK 14 🤣🤣" 70000
Add $c $n 't6q1EUVbt24' "I'm 2 days into college LYRIC PRANK 13 🤣🤣" 32000
Add $c $n 'yq7SeuA1cJk' "I'm 2 days into college LYRIC PRANK 12 🤣🤣" 59000
Add $c $n 'XwBzKxz7h8Y' "I'm 2 days into college LYRIC PRANK 11 🤣🤣" 45000
Add $c $n 'aRuFNECssno' "I'm 2 days into college LYRIC PRANK 10 🤣🤣" 60000
Add $c $n 'lwy0AjWMLSk' "I'm 2 days into college LYRIC PRANK 9 🤣🤣" 66000
Add $c $n 'NdO1YXiWt4M' "I'm 2 days into college LYRIC PRANK 8 🤣🤣" 60000
Add $c $n 'gPhritD9BHk' 'Hear Me Now LYRIC PRANK 🤣🤣' 37000
Add $c $n 'KWLbUJhZA0Y' 'Lush Life LYRIC PRANK 24 🤣🤣' 95000
Add $c $n 'B-3-SOXpYW0' 'Lush Life LYRIC PRANK 23 🤣🤣' 64000
Add $c $n '5RFXH97PKBA' 'Lush Life LYRIC PRANK 22 🤣🤣' 91000
Add $c $n 'S90YtrEZIe4' 'Lush Life LYRIC PRANK 21 🤣🤣' 46000
Add $c $n 'NvvuCKna1JE' 'Lush Life LYRIC PRANK 20 🤣🤣' 92000
Add $c $n 'V7O8YNyi2hY' 'Lush Life LYRIC PRANK 19 🤣🤣' 502000
Add $c $n 'HF15kadQREM' 'Lush Life LYRIC PRANK 18 🤣🤣' 38000
Add $c $n 'POmmJ3rfjCY' 'Lush Life LYRIC PRANK 17 🤣🤣' 34000
Add $c $n 'zGtEPBQ259Q' "What's Your Favourite Song? PT 3🎤🤣" 47000
Add $c $n 'X14ryNc0610' 'Lush Life LYRIC PRANK 16 🤣🤣' 585000
Add $c $n 'itUvgyQoymI' 'Lush Life LYRIC PRANK 15 🤣🤣' 75000
Add $c $n 'EzyA3ZTL1Go' "I'm 2 days into college LYRIC PRANK 7 🤣🤣" 34000
Add $c $n 'h8g_pHpQD78' 'Lush Life LYRIC PRANK 14 🤣🤣' 121000
Add $c $n 'bCypMtBkFTA' 'Lush Life LYRIC PRANK 13 🤣🤣' 612000
Add $c $n 'GK9b-uwwohI' "I'm 2 days into college LYRIC PRANK 6 🤣🤣" 104000

Write-Host "Total records: $($records.Count)"

$chunkSize = 100
$total = $records.Count
$inserted = 0

for ($i = 0; $i -lt $total; $i += $chunkSize) {
    $chunk = $records[$i..[Math]::Min($i + $chunkSize - 1, $total - 1)]
    $json = ($chunk | ConvertTo-Json -Depth 3 -Compress)
    try {
        Invoke-RestMethod -Method POST -Uri $api -Headers $headers -Body $json | Out-Null
        $inserted += $chunk.Count
        Write-Host "Chunk $([math]::Ceiling(($i+1)/$chunkSize)): $($chunk.Count) inserted (total: $inserted)"
    } catch {
        Write-Host "ERROR chunk $([math]::Ceiling(($i+1)/$chunkSize)): $($_.Exception.Message)"
        Write-Host $_.ErrorDetails.Message
    }
}
Write-Host "Done. $inserted / $total inserted."
