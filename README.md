# iBeacon Scanning test application

This application demonstrate some features of iBeacon scanning :

* application wake up in the vicinity of an iBeacon (`CLBeaconRegion`)
* detect if we enter or exit a `CLBeaconRegion`
* continuous ranging of multiple iBeacons sharing the same proximity UUID

These features work in foreground **and in background** mode of the application.

## Background mode

The application demonstrates how to request extra background running time before the app is suspended by the system. The remaining time countdown can be reset in background by running specific tasks, if such tasks are checked in the "Background modes" Xcode capabilities of the target. Here, we use some Speech Synthesizer methodes, encapsulated in AVAudioSessions, with Audio and Play capabilities allowed in background mode.

# LICENSE

The MIT License (MIT)

Copyright (c) 2014 Edouard FISCHER

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

