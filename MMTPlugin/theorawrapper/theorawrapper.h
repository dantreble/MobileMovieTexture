// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the THEORAWRAPPER_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// THEORAWRAPPER_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#if defined _WIN32 || defined __CYGWIN__
	#ifdef THEORAWRAPPER_EXPORTS
		#ifdef __GNUC__
			#define THEORAWRAPPER_API __attribute__((dllexport))
		#else
			#define THEORAWRAPPER_API __declspec(dllexport) // Note: actually gcc seems to also supports this syntax.
		#endif
	#else
		#ifdef __GNUC__
			#define THEORAWRAPPER_API __attribute__((dllimport))
		#else
			#define THEORAWRAPPER_API __declspec(dllimport) // Note: actually gcc seems to also supports this syntax.
		#endif
	#endif
	#define DLL_LOCAL
#else
	#if __GNUC__ >= 4
		#define THEORAWRAPPER_API __attribute__ ((visibility("default")))
		//#define DLL_LOCAL  __attribute__ ((visibility("hidden")))
	#else
		#define DLL_PUBLIC
		//#define DLL_LOCAL
	#endif
#endif

struct PlaybackState;
struct IUnityInterfaces;


extern "C"
{
	THEORAWRAPPER_API void *CreateContext();
	THEORAWRAPPER_API void DestroyContext(PlaybackState *state);
	THEORAWRAPPER_API bool OpenStream(PlaybackState *state, char *path, int offset, int size,bool pot, bool scanDuration, int maxSkipFrames);
    THEORAWRAPPER_API void CloseStream(PlaybackState *state);
	THEORAWRAPPER_API int GetPicWidth( PlaybackState *state );
	THEORAWRAPPER_API int GetPicHeight( PlaybackState *state );
	THEORAWRAPPER_API int GetPicX( PlaybackState *state );
	THEORAWRAPPER_API int GetPicY( PlaybackState *state );
    THEORAWRAPPER_API int GetYStride( PlaybackState *state );    
    THEORAWRAPPER_API int GetYHeight( PlaybackState *state );
    THEORAWRAPPER_API int GetUVStride( PlaybackState *state );
    THEORAWRAPPER_API int GetUVHeight( PlaybackState *state );
	THEORAWRAPPER_API bool HasFinished( PlaybackState *state );
	THEORAWRAPPER_API double GetDecodedFrameTime(PlaybackState *state);
    THEORAWRAPPER_API double GetUploadedFrameTime(PlaybackState *state);
    THEORAWRAPPER_API double GetTargetDecodeFrameTime(PlaybackState *state);
	THEORAWRAPPER_API void SetTargetDisplayDecodeTime(PlaybackState *state, double targetTime);
	THEORAWRAPPER_API double GetVideoFPS(PlaybackState *state);
	THEORAWRAPPER_API float GetAspectRatio(PlaybackState *state);
	THEORAWRAPPER_API double Seek (PlaybackState *state, double time, bool waitKeyFrame);
	THEORAWRAPPER_API double GetDuration(PlaybackState *state);
    THEORAWRAPPER_API void UploadReadyPlaybackStates ();
    //THEORAWRAPPER_API void SetGraphicsDevice (void* device, int deviceType, int eventType);
#if defined (iOS)
	THEORAWRAPPER_API void MMTUnityRenderEvent (int eventID);
	THEORAWRAPPER_API void MMTUnitySetGraphicsDevice (void* device, int deviceType, int eventType);
#else
    //THEORAWRAPPER_API void UnityRenderEvent (int eventID);
    THEORAWRAPPER_API void UnitySetGraphicsDevice (void* device, int deviceType, int eventType);
#endif
	THEORAWRAPPER_API void *GetNativeHandle( PlaybackState *state , int plane);
	THEORAWRAPPER_API void *GetNativeTextureContext( PlaybackState *state );
	THEORAWRAPPER_API void SetPostProcessingLevel( PlaybackState *state, int level );


}