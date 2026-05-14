// liblsl.cs — C# P/Invoke wrapper for the Lab Streaming Layer (LSL) native library.
//
// This file exposes the subset of the LSL C API used by this project.
// The native binary (liblsl64.dll on Windows, liblsl64.so on Linux,
// liblsl64.dylib on macOS) must be placed in Assets/Plugins/LSL/ before
// building or running in the Unity Editor.
//
// The official liblsl release and full C# wrapper can be found at:
//   https://github.com/sccn/liblsl
//   https://github.com/labstreaminglayer/liblsl-Csharp

using System;
using System.Runtime.InteropServices;

namespace LSL
{
    // -----------------------------------------------------------------------
    // Channel-format constants (mirrors lsl_channel_format_t in lsl.h)
    // -----------------------------------------------------------------------
    public enum channel_format_t
    {
        cf_undefined = 0,
        cf_float32   = 1,
        cf_double64  = 2,
        cf_string    = 3,
        cf_int32     = 4,
        cf_int16     = 5,
        cf_int8      = 6,
        cf_int64     = 7,
    }

    // -----------------------------------------------------------------------
    // StreamInfo — describes a data stream (name, type, channel count, etc.)
    // -----------------------------------------------------------------------
    public class StreamInfo : IDisposable
    {
        private IntPtr _handle;

        public StreamInfo(string name, string type, int channelCount,
                          double nominalSrate, channel_format_t channelFormat,
                          string sourceId)
        {
            _handle = lsl_create_streaminfo(name, type, channelCount,
                                            nominalSrate, (int)channelFormat,
                                            sourceId);
        }

        internal StreamInfo(IntPtr handle)
        {
            _handle = handle;
        }

        internal IntPtr Handle => _handle;

        public void Dispose()
        {
            if (_handle != IntPtr.Zero)
            {
                lsl_destroy_streaminfo(_handle);
                _handle = IntPtr.Zero;
            }
        }

        [DllImport("liblsl64")]
        private static extern IntPtr lsl_create_streaminfo(
            string name, string type, int channelCount,
            double nominalSrate, int channelFormat, string sourceId);

        [DllImport("liblsl64")]
        private static extern void lsl_destroy_streaminfo(IntPtr info);
    }

    // -----------------------------------------------------------------------
    // StreamOutlet — pushes samples into a stream that remote inlets can pull
    // -----------------------------------------------------------------------
    public class StreamOutlet : IDisposable
    {
        private IntPtr _handle;

        public StreamOutlet(StreamInfo info, int chunkSize = 0, int maxBuffered = 360)
        {
            _handle = lsl_create_outlet(info.Handle, chunkSize, maxBuffered);
        }

        public void push_sample(float[] data)
        {
            lsl_push_sample_f(_handle, data);
        }

        public void Dispose()
        {
            if (_handle != IntPtr.Zero)
            {
                lsl_destroy_outlet(_handle);
                _handle = IntPtr.Zero;
            }
        }

        [DllImport("liblsl64")]
        private static extern IntPtr lsl_create_outlet(IntPtr info, int chunkSize, int maxBuffered);

        [DllImport("liblsl64")]
        private static extern void lsl_destroy_outlet(IntPtr outlet);

        [DllImport("liblsl64")]
        private static extern int lsl_push_sample_f(IntPtr outlet, float[] data);
    }

    // -----------------------------------------------------------------------
    // StreamInlet — pulls samples from a remote outlet
    // -----------------------------------------------------------------------
    public class StreamInlet : IDisposable
    {
        private IntPtr _handle;

        public StreamInlet(StreamInfo info, int maxBuffered = 360, int maxChunklen = 0)
        {
            _handle = lsl_create_inlet(info.Handle, maxBuffered, maxChunklen, 1);
            lsl_open_stream(_handle, 5.0);
        }

        /// <summary>
        /// Pull a float sample.  Returns the timestamp, or 0 if no sample was
        /// available within <paramref name="timeout"/> seconds.
        /// </summary>
        public double pull_sample(float[] data, double timeout = 0.0)
        {
            return lsl_pull_sample_f(_handle, data, data.Length, timeout, out _);
        }

        public void Dispose()
        {
            if (_handle != IntPtr.Zero)
            {
                lsl_destroy_inlet(_handle);
                _handle = IntPtr.Zero;
            }
        }

        [DllImport("liblsl64")]
        private static extern IntPtr lsl_create_inlet(IntPtr info, int maxBuffered,
                                                      int maxChunklen, int recover);

        [DllImport("liblsl64")]
        private static extern void lsl_open_stream(IntPtr inlet, double timeout);

        [DllImport("liblsl64")]
        private static extern void lsl_destroy_inlet(IntPtr inlet);

        [DllImport("liblsl64")]
        private static extern double lsl_pull_sample_f(IntPtr inlet, float[] buffer,
                                                       int bufferElements,
                                                       double timeout, out int ec);
    }

    // -----------------------------------------------------------------------
    // Helper — stream resolution
    // -----------------------------------------------------------------------
    public static class LSL
    {
        /// <summary>
        /// Resolve all streams with the given property equal to the given value.
        /// Blocks for up to <paramref name="timeout"/> seconds.
        /// Returns an array of matching StreamInfo objects (caller owns them).
        /// </summary>
        public static StreamInfo[] resolve_stream(string prop, string value,
                                                  int minimum = 1,
                                                  double timeout = 5.0)
        {
            IntPtr[] buf = new IntPtr[256];
            int found = lsl_resolve_byprop(buf, buf.Length, prop, value, minimum, timeout);
            StreamInfo[] result = new StreamInfo[found];
            for (int i = 0; i < found; i++)
                result[i] = new StreamInfo(buf[i]);
            return result;
        }

        [DllImport("liblsl64")]
        private static extern int lsl_resolve_byprop(IntPtr[] buffer, int bufferLen,
                                                     string prop, string value,
                                                     int minimum, double timeout);
    }
}
