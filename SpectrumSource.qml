import Quickshell.Services.Pipewire
import QtQuick

// The live spectrum of the default sink. PwAudioSpectrum is not part of
// upstream Quickshell (it comes with the noctalia-qs fork), so this file is
// only ever loaded through a Loader: where the type does not exist the Loader
// fails quietly and the media panel falls back to a synthetic equalizer.
PwAudioSpectrum {
    node: Pipewire.defaultAudioSink
    barCount: 24
    frameRate: 30
}
