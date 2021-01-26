---
layout: single
title:  "The Game Boy Boot ROM"
date:   2021-01-25 00:00:00 -0500
categories: gameboy
tags: gameboy emulator projects
---
Last week, I shared a tweet teasing some of the progress I've made on my Game Boy emulator. After a few exciting breakthroughs, I'm pleased to say it's finally in a playable state.

{% twitter https://twitter.com/daltonclaybrook/status/1351332502623973383 %}

I'm excited to share more of my progress in the next few weeks, but for this post, I'd like to do something a little different. I'd like to talk about how the original Game Boy boot ROM works.

---

You're probably already familiar with the boot ROM even if you don't know it by that name. It is the short sequence that occurs every time you turn on the Game Boy. The Nintendo logo glides in from the top of the screen, it stops in the middle, and then you hear a short, playful chime. 🎵 _ba-ding_ 🎵

In addition to setting the tone for your imminent gaming session, this sequence has a few technically important purposes and one interesting legal one. Let's walk through exactly what is going on in this 256-byte program.

## Set the stage

First off, the ROM sets the _stack pointer_ to the correct value (`0xFFFE`). In computing, the "stack" is a region of memory where functions can store their local state. Bytes are added to the stack in reverse order, and the stack pointer is decremented each time a byte is _pushed_ onto the stack, so that's why this number starts high.

Next, the ROM loops through the VRAM region of memory and loads "0" into each memory location. Due to *[hardware knowledge missing]*, these bytes may be non-zero after the Game Boy powers on, so the boot ROM must clear all of these bytes. Otherwise, the screen might display random undesired tiles and other visual artifacts.

After that, the ROM configures the onboard sound controller. It turns the controller on, selects the appropriate wave pattern for the tones, applies the correct volume envelope, and finally sets the master volume for left and right audio channels.

>Fun fact: Are you surprised to hear that the Game Boy has stereo audio? Although the device only has one speaker, the Game Boy supports stereo audio over the 3.5 mm headphone jack.

After configuring the sound controller, the boot ROM sets the color palette for the background tilemap. The chosen color palette consists of four colors: white, black, black, black. In practice, I would assume only the first two colors are actually used since the other two are duplicates.

Next, the ROM loads the data for the Nintendo logo from the cartridge ROM into VRAM. That's right, every official Game Boy cartridge contains a copy of the Nintendo logo in its "header" at locations `0x104`...`0x133`. The reason for this will become apparent later on. This is why when you power up the Game Boy with no cartridge plugged in, you will see a black box instead of the logo. After copying the logo data, the boot ROM loads the registered trademark symbol (®) into VRAM as well, but this data is loaded from the boot ROM, not the cartridge.

If you read an [earlier post of mine](/gameboy/2021/01/04/a-project-for-the-new-year.html), you might remember that the Game Boy GPU works by displaying a mosaic of 8x8 tiles rather than drawing individual pixels. This arrangement of background tiles is what occurs next in the boot sequence. The ROM loops through the tilemap and loads pointers to tiles in VRAM so that the Nintendo logo and registered trademark symbol are positioned correctly on the map.

Everything that has happened so far has been purely configuration, and there are only a couple of things left to do before the logo starts scrolling. The boot ROM sets the "Scroll Y" register to 100, causing the background map to be shifted up by that many pixels so the Nintendo logo will be positioned above the top edge of the screen. Finally, the ROM turns on the display.

## Start the show

At this point, the GPU is finally drawing pixels to the screen. The boot ROM waits for a bit before decrementing the Scroll Y register, causing the logo to shift downwards by one pixel on the screen. It waits again, then decrements again. This cycle is repeated 100 times until the Scroll Y register is 0 and the Nintendo logo is positioned in the center of the screen.

It's now time to play the chime. The boot ROM loads the frequency (or pitch) of the first note into the appropriate audio channel register and starts the channel. The channel has been preconfigured to turn itself off after a number of cycles, so this is not something the ROM must do explicitly. The ROM waits for a bit, loads the frequency of the second note into the same register, and starts the channel again. From the user's perspective, the sequence is now completely finished.

## Red tape

I mentioned earlier that the boot ROM loads the Nintendo logo from the cartridge and not from the ROM itself. What is the purpose of this? Is the boot ROM too small to contain the logo along with everything else it needs? Interestingly, the boot ROM actually *does* contain its own copy of the logo data. So why then does the cartridge need to provide it? It turns out, this is the legal detail I was referring to at the start of the post. After the chime is played, the boot ROM runs a procedure to compare the logo in the cartridge to the one stored in the ROM, one byte at a time. If any of these bytes are different between the two—meaning the logo is malformed or missing from the cartridge—the boot ROM locks up the system and the game will not play. Nintendo might not be able to prevent developers from producing and selling unauthorized cartridges, but they *can* prevent them from using their registered trademarks without permission, and merely including their logo in an unauthorized game constitutes a trademark violation.

After this comparison is finished, only two tasks remain. The ROM computes an 8-bit [checksum](https://en.wikipedia.org/wiki/Checksum) of the data stored in the cartridge header and compares the checksum to the byte stored in `0x14D` on the cartridge. If these values don't match, the system locks up, just like with the logo check. This is most likely done to verify the integrity of the data stored in the cartridge, rather than for legal reasons. Finally, the boot ROM disables itself by writing "1" to a special register at location `0xFF50`. Previously mapped to the boot ROM, the memory region `0x000`...`0x100` is remapped to the first 256 bytes in the cartridge ROM.

By the time the cartridge takes over execution, the boot ROM is completely inaccessible. Historically, this has made it quite tricky for Game Boy researchers to know exactly what the boot ROM was doing. It wasn't until 2003 that a researcher called neviksti was able to decipher the contents by physically de-capping the ROM chip inside the Game Boy. Using a microscope, he painstakingly read and recorded the contents of the boot ROM bit-by-bit. We have him and many others to thank for the vast assortment of information now publicly available about this iconic device.

## Resources

- [Gameboy Bootstrap ROM](https://gbdev.gg8.se/wiki/articles/Gameboy_Bootstrap_ROM)
- [Pan Docs](https://gbdev.io/pandocs/)
- [The Ultimate Game Boy Talk](https://www.youtube.com/watch?v=HyzD8pNlpwI)
