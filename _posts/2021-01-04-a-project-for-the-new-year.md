---
layout: single
title:  "A project for the new year"
date:   2021-01-04 09:15:53 -0500
categories: gameboy
---
The [Game Boy Color](https://en.wikipedia.org/wiki/Game_Boy_Color) was released in October of 1998, nearly ten years after the release of the original Game Boy. I don't remember exactly when I got mine, but it must have been around that time because it was my saving grace on the long road trips my family would take to Utah. I would play Pokémon Blue for hours upon hours, occasionally struggling to see the screen (it had no built-in light). I remember getting worried as the power light began to dim, signaling the end-of-life for the two AA batteries it depended on, and saving my game after every minuscule achievement out of paranoia. I remember the thrill of catching an elusive Pokémon or beating a gym leader and the sting of a blackout.

I'm in my 30's now and I still love the Game Boy, and as I have continued to learn more about it, it has only become more fascinating to me. Admittedly, these days I'm spending less time gaming and more time hacking and learning. I still have my original Game Boy Color from all those years ago, but I've made a few modifications to it, the most significant of which is swapping the unlit LCD for a backlit one. If I could show my modded Game Boy to my 10-year-old self, I know it would blow his mind. 🤯 In addition to my hardware mods, I've also dabbled a bit in the world of Game Boy software. In doing so, I have learned quite a bit about how games were built and about the technical capabilities—and limitations—of the device.

## A few facts about the Game Boy

At the heart of all Game Boy models is a single chip—or [SoC](https://en.wikipedia.org/wiki/System_on_a_chip)—the Sharp LR35902. This is a custom chip designed and manufactured specifically for the Game Boy that is a hybrid of the [Intel 8080](https://en.wikipedia.org/wiki/Intel_8080) and the [Zilog Z80](https://en.wikipedia.org/wiki/Zilog_Z80). Interestingly, the Sharp chip is a bit of a Frankenstein chip since the instruction set is not a strict superset of either the 8080 or Z80, and it contains a few additional instructions not found in the other two. These are 8-bit chips, and considering the Game Boy Color was manufactured until 2003, that makes the Game Boy the last 8-bit gaming system in common use.

The Game Boy has a 16-bit address space enabling it to address 64 KB of memory (`0x0000` - `0xFFFF`). The first 32 KB is used to access the ROM directly from the game cartridge. You might be wondering, "Does this mean that games must be 32 KB or smaller?" Fortunately, the answer is "No." Larger game cartridges include a special chip called a Memory Bank Controller that allows the Game Boy to leverage a technique called [bank switching](https://en.wikipedia.org/wiki/Bank_switching) to change the particular bank of memory the CPU is currently able to address in the ROM. A game can switch the current memory bank by writing magic values to a special memory address within the ROM address space. In theory, this means the ROM storage capacity is only limited by what will fit inside the cartridge, but in practice, the biggest games max out around 2 MB.

The RAM is divided into two sections, the Work RAM (WRAM) and Video RAM (VRAM). The WRAM is used by games to store runtime state such as a player's current location, remaining ammo, etc. The VRAM is special-purpose memory used by the Pixel Processing Unit (PPU) to draw the screen. The following describes the process of drawing pixels to the screen:

**Copy tile data into a special section of VRAM**
Each tile is 8x8 pixels and has a color depth of four colors. However, rather than referring to specific colors, each pixel refers to an index in a color palette. You can use these palettes to change the colors of a tile without having to copy a different tile into VRAM. This might be done, for example, to create a fade-to-black effect.

**Specify which tiles are displayed in the background map**
The VRAM contains space for two 32x32-tile background maps (BG maps). Rather than pixels, these BG maps contain pointers to tiles in the Tile Data section described above. For example, if I wanted to draw a strip of grass, I might have one 8x8 "grass" tile loaded into Tile Data at index 3. A slice of my BG map would then contain `[... 3, 3, 3, 3 ...]` representing the locations of the grass tiles in the BG map.

Since a tile is 8x8 pixels, and a BG map is 32x32 tiles, that means the full BG map is 256x256 pixels. But the Game Boy LCD's display resolution is only 160x144 pixels. This overlap is useful for game developers when combined with two special registers known as "Scroll Y" and "Scroll X." Developers write values to these registers to cause the BG map to be shifted by the specified number of pixels when it is drawn to the screen. For example, as the player is walking towards the right side of the screen, the Scroll X register can be incremented and the "camera" will follow the player as they walk.

**Copy sprite data to the OAM table**
Sprite data lives in a region of VRAM known as the Object Attribute Memory table (OAM). Sprites can be characters or other objects that move around or otherwise don't make sense as part of the background. Like the BG map, the OAM doesn't contain raw pixel data but instead refers to the same Tile Data memory as the BG map. In addition to the tile indexes to be displayed, the OAM contains positional information for the sprite and a few other attributes. Also, like the BG map, the OAM uses color palettes to color sprite tiles, but it uses a separate set of palettes known as "Object" palettes. Sprite tile data that refers to the palette color index 0 will draw that pixel as transparent, meaning that sprites tiles can only use three colors instead of four like background tiles. This is probably an appropriate tradeoff given the alternative where sprites are all blocky.

There's a lot more to say about the technical details of the Game Boy. If you're interested in learning more, I highly recommend watching [The Ultimate Game Boy Talk](https://www.youtube.com/watch?v=HyzD8pNlpwI) by Michael Steil.

## Learning to build games in assembly

The bulk of what I know about the Game Boy I learned in April/May of 2019 when I became completely absorbed in learning how to develop games for the platform. To this day, I'm not sure what came over me, but for a period of about five or six weeks, I was completely obsessed. I would come home from work every day and bury my head in the disassembled code files of Pokémon Red trying to understand how they worked. I would translate algorithms from assembly language into English descriptions of their functionality, then try to reproduce those algorithms in a separate project. Not only did I learn how the Game Boy worked, and how programs are written in assembly languages, but I also got a sense of best-practices when developing software in this constrained environment. For example, Pokémon Red uses static memory allocation exclusively. Blocks of memory in WRAM are allocated at compile-time instead of dynamically at runtime. From my learnings, I made a few toy projects, gave a fun after-hours presentation at my company about the Game Boy, and largely ticked the box of personal achievement for the time being.

## Scratching the itch again

Now in 2021, I think I'm ready for a new Game Boy project: *I'd like to try to write a single-purpose programming language and compiler for the Game Boy*. This sounds like a really fun project and I feel confident I know enough about the Game Boy to have a chance at success. I have a decent grasp of Game Boy assembly language and I'm familiar with some optimizations that can be made to account for the constrained resources of the device. I'm also familiar with a lot of the "boilerplate" code that usually goes into Game Boy programs such as the [DMA transfer procedure](http://bgb.bircd.org/pandocs.htm#lcdoamdmatransfers). The following are some goals/ideas for the language:

- First and foremost, *the language should be nice to use* (unlike assembly). I'm a Swift developer by trade, and I have some experience with Rust as well. Both of these languages are delightful to use and still manage to be decently performant in their compiled/optimized forms. Rust in particular prides itself on having a very thin [runtime system](https://en.wikipedia.org/wiki/Runtime_system). A tiny runtime is absolutely essential for a language that targets the Game Boy.
- *It should be very clear to the developer when they're making a choice that will have negative performance/memory consequences*. Rust does a pretty good job of this with its [borrowing mechanism](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html) and by preventing implicit and costly cloning of complex objects.
- *It should have a standard library that provides access to the full range of functionality of the Game Boy through a simple API*. This library will be responsible for implementing all the boilerplate code typically required in a Game Boy game. Where the language will be thin and flexible, the stdlib will be large and opinionated.
- *It should have a cool name!* 😝 Okay, this one isn't super critical, but it's fun to think about. I've toyed around with a few ideas, but not much has stuck. One idea is _Foil_, which is symbolic for a couple of reasons: A [Foil](https://en.wikipedia.org/wiki/Foil_(fencing)) is a sword used in fencing and the Game Boy chip is manufactured by Sharp. Get it? Sword... Sharp... Also, "Foil" can refer to a special kind of rare and shiny Pokémon card aka "Holofoil" or "Holographic."

Admittedly, one topic that I _don't_ know much about is compiler development. I'm vaguely aware of the constituent components of a compiler, but I'm not familiar with the various algorithms typically used to implement those components. Fortunately, I'm not deterred by this lack of understanding; if anything, I'd say I'm more energized by it. Even simply building my first working compiler for any target will be a huge accomplishment.

Of course, this project idea is still in the very early stages. One possibility is that I will eventually hit a roadblock and discover that my end goal of building a working compiler for the Game Boy is impossible due to factors beyond my control. I shared this concern with my friend [Jason](https://twitter.com/jasonbrennan) recently and he suggested I change my definition of success for the project. Instead of making product-focused goals, I should make learning-focused ones. Here are a few ideas:

- Learn how compilers work and learn how to build one
- Learn even more about how the Game Boy works
- Learn about the technical feasibility/practicality of building a new programming language/compiler specifically for the Game Boy

I've already made a bit of progress towards goal #1. I've been taking the [Compilers: Theory and Practice](https://www.udacity.com/course/compilers-theory-and-practice--ud168) course on Udacity and I am really enjoying it. I also intend to write and publish additional blog posts at a high frequency—maybe weekly or biweekly—to document my progress. Hopefully, this and subsequent posts will help keep me accountable and focused on achieving these goals.

Maybe you intend to pick up a project of your own in this new year, or perhaps this post has inspired you to do so. I love hearing about the things others are interested in. Our unique interests and goals are critical parts of what make us who we are and contribute to our personal fulfillment. Even writing/talking about them can be quite satisfying, as I've learned writing this. If you do have something exciting in the works, I'd love to hear about it. Let's be accountabilibuddies!

Happy New Year,

Dalton

## Resources

- [Game Boy - Wikipedia](https://en.wikipedia.org/wiki/Game_Boy)
- [The Ultimate Game Boy Talk - Michael Steil](https://www.youtube.com/watch?v=HyzD8pNlpwI)
- [Pan Docs](http://bgb.bircd.org/pandocs.htm)
- [Pokémon Red/Blue Disassembly](https://github.com/pret/pokered)
- [Compilers: Theory and Practice - Udacity](https://www.udacity.com/course/compilers-theory-and-practice--ud168)
- [SDCC - Wikipedia](https://en.wikipedia.org/wiki/Small_Device_C_Compiler)
