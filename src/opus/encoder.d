module opus.encoder;

const int OPUS_OK = 0;

enum Application {
  VOIP = 2048,
  AUDIO = 2049,
  LOWDELAY = 2051,
}

enum Bandwidth {
  NARROWBAND = 1101,
  MEDIUMBAND = 1102,
  WIDEBAND = 1103,
  SUPERWIDEBAND = 1104,
  FULLBAND = 1105,
}

enum CTL {
  SET_BITRATE_REQUEST = 4002,
  SET_BANDWIDTH_REQUEST = 4008,
  SET_INBAND_FEC_REQUEST = 4012,
  SET_PACKET_LOSS_PERC_REQUEST = 4014,
}

extern (C) {
  struct OpusEncoder {};

  OpusEncoder* opus_encoder_create(int, int, int, int*);
  void opus_encoder_destroy(OpusEncoder*);
  int opus_encode(OpusEncoder*, const short*, int, ubyte*, int);
  int opus_encoder_ctl(OpusEncoder*, int request, ...);
}

class Encoder {
  OpusEncoder* encoder;

  private {
    int sampleRate;
    int channels;
    Application app;
  }

  this(int sampleRate=48000, int channels=2, Application app = Application.VOIP) {
    this.sampleRate = sampleRate;
    this.channels = channels;
    this.app = app;

    int error;
    this.encoder = opus_encoder_create(sampleRate, channels, app, &error);
    assert(error == OPUS_OK);
  }

  ubyte[] encode(const short[] pcm, int frameSize) {
    ubyte[] data;
    data.length = (frameSize * this.channels) * 2;
    int size = opus_encode(this.encoder, &pcm[0], frameSize, &data[0], cast(int)data.length);
    return data[0..size];
  }

  void setBitrate(int kbps) {
    assert(opus_encoder_ctl(this.encoder, CTL.SET_BITRATE_REQUEST, kbps * 1024) == OPUS_OK);
  }

  void setBandwidth(Bandwidth bw) {
    assert(opus_encoder_ctl(this.encoder, CTL.SET_BANDWIDTH_REQUEST, cast(int)bw) == OPUS_OK);
  }

  void setInbandFEC(bool enabled) {
    assert(opus_encoder_ctl(this.encoder, CTL.SET_INBAND_FEC_REQUEST, cast(int)enabled) == OPUS_OK);
  }

  void setPacketLossPercent(int percent) {
    assert(opus_encoder_ctl(this.encoder, CTL.SET_PACKET_LOSS_PERC_REQUEST, percent) == OPUS_OK);
  }

  ~this() {
    opus_encoder_destroy(this.encoder);
  }
}

unittest {
  Encoder enc = new Encoder();
  enc.setInbandFEC(true);
  enc.setPacketLossPercent(30);
  enc.setBandwidth(Bandwidth.FULLBAND);
  enc.setBitrate(128);
  enc.destroy();
}
