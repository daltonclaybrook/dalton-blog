---
layout: single
title:  "Distractions"
date:   2021-01-10 00:00:00 -0500
categories: gameboy
tags: gameboy emulator projects
---
If you read my [last post](/gameboy/2021/01/04/a-project-for-the-new-year.html), you know I've made an ambitious plan to build a new programming language and compiler for the Game Boy in 2021. I also set a goal for myself to post regularly in order to stay accountable. While I appear to be holding strong on my second goal (see: this post), I've already gotten a bit distracted from my main goal.

Last week, I read a [post on Reddit](https://www.reddit.com/r/EmuDev/comments/kqwgot/gameboy_emulator_my_experience/gi64jrc/) that listed one person's challenges with developing a Game Boy emulator. I also have attempted to build a Game Boy emulator in the past, and [the project](https://github.com/daltonclaybrook/GameBoy) has gone a bit stagnant, but this post caught my attention. Some of the challenges they faced are the same challenges I was facing when I was last working on it. For example:

> Blargg tests: The CPL test isn't very comprehensive, it can pass when your implementation is totally wrong **The CPU instructions tests may pass individually, but when run as suite of all of them, can infinitely loop.** MBC1 implementation is required for the suite, but not for individual tests.

The [Blargg test ROMs](https://github.com/retrio/gb-test-roms) are a collection of ROM images used to validate the correctness of an emulator implementation. This particular bullet point caught my eye because this very problem (in bold) was occurring for me in my emulator! All the individual tests for CPU instructions were passing, but the aggregate test suite would get stuck in an endless loop. I knew I had not implemented [MBC1](http://bgb.bircd.org/pandocs.htm#mbc1max2mbyteromandor32kbyteram) yet, but I had assumed it was not required for such a simple test ROM.

{% include image.html url="/assets/images/emulator/loop.png" description="My emulator, stuck in an endless loop" topMargin="-3" %}

At this point, I realized I had inadvertently [nerd-sniped](https://xkcd.com/356/) myself. I had no choice but to drop everything and implement MBC1 as the post author had suggested. I won't go into detail about the implementation in this post, but you can [read my code here](https://github.com/daltonclaybrook/GameBoy/blob/master/GameBoyKit/Memory/MBC/MBC1.swift) if you are interested. You will notice the stark contrast between this type of cartridge and my implementation for "ROM only," also know as "MBC0" [located here](https://github.com/daltonclaybrook/GameBoy/blob/master/GameBoyKit/Memory/ROM.swift). You can also find a note about Memory Bank Controllers in my [last post](/gameboy/2021/01/04/a-project-for-the-new-year.html).

After implementing MBC1, hooking it up, and running the suite again, this is what I saw:

{% include image.html url="/assets/images/emulator/pass.png" description="It worked!" topMargin="-3" %}

This achievement has really energized me to continue working on my emulator. Though, there's still a ton of work left to do before I will be able to play real games on it. For example, the Pokémon Gold/Silver cartridge contains a ROM chip, an MBC3 chip, a battery, and a real-time clock, all of which have to be emulated. But just as you have to walk before you can run, you have to play Tetris before you can play Pokémon.
