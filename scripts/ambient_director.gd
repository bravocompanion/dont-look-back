extends Node

@onready var ambient_audio: AudioStreamPlayer = $AmbientAudio

var time_until_knock: float = 4.5
var knock_stream: AudioStreamWAV

func _ready() -> void:
    knock_stream = _build_knock_stream()
    ambient_audio.stream = knock_stream

func _process(delta: float) -> void:
    time_until_knock -= delta
    if time_until_knock > 0.0:
        return

    ambient_audio.pitch_scale = randf_range(0.88, 1.08)
    ambient_audio.play()
    time_until_knock = randf_range(6.0, 12.0)

func _build_knock_stream() -> AudioStreamWAV:
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 22050
    stream.stereo = false

    var duration: float = 0.22
    var sample_count: int = int(float(stream.mix_rate) * duration)
    var data: PackedByteArray = PackedByteArray()
    data.resize(sample_count * 2)

    for i: int in range(sample_count):
        var t: float = float(i) / float(stream.mix_rate)
        var envelope: float = exp(-t * 22.0)
        var tone: float = sin(TAU * 92.0 * t) * 0.75 + sin(TAU * 146.0 * t) * 0.25
        var sample: int = clampi(int(tone * envelope * 11000.0), -32768, 32767)
        var encoded: int = sample
        if encoded < 0:
            encoded += 65536
        data[i * 2] = encoded & 255
        data[i * 2 + 1] = (encoded >> 8) & 255

    stream.data = data
    return stream
