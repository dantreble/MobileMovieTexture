// theorawrapper.cpp : Defines the exported functions for the DLL application.
//

#include <string.h>
#include <stdarg.h>

#include "theorawrapper.h"

#include "../theora/lib/decint.h"
#include "oggz/oggz.h"

#if !defined(WIN32)
#define PTHREAD
#else
#include <windows.h>
#endif

#ifdef PTHREAD
#include <pthread.h>
#include <errno.h>
#endif

#if defined(ANDROID)
#include <android/log.h>

static void Log(const char* fmt, ...)
{
	va_list args;
	va_start(args,fmt);
	__android_log_print(ANDROID_LOG_DEBUG, "theorawrapper", fmt, args);
	//vprintf(fmt,args);
	va_end(args);
}

#else

static void Log(const char* fmt, ...)
{
	va_list args;
	va_start(args,fmt);
	vprintf(fmt,args);
	va_end(args);
}

#endif


#include "GfxDevice.h"
#include "MathHelpers.h"
#include "TextureContext.h"

#if SUPPORT_OPENGL
#if defined(ANDROID)
#include <GLES/gl.h>
#endif

#if  defined (iOS)
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES2/glext.h>
#endif

#if  defined (OSX)
#include <OpenGL/gl.h>
#endif

#if defined(WIN32)
#include <GL/gl.h>
#pragma comment(lib, "opengl32.lib")
#endif
#endif

#ifdef SUPPORT_METAL
#include "TextureMetal.h"
#endif

#if SUPPORT_D3D9
#include "TextureD3D9.h"
#endif

#if SUPPORT_D3D11
#include "TextureD3D11.h"
#endif


struct PlaybackState;

const int MAX_PLAYBACK_STATES = 64;
static PlaybackState **g_playBackStates = NULL;

#ifdef PTHREAD
pthread_mutex_t g_playBackStatesMutex;
#else
CRITICAL_SECTION g_playBackStatesMutex;
#endif


static bool AddPlaybackState (PlaybackState *state)
{
    bool ret = false;
    
	if (g_playBackStates == NULL)
	{
		g_playBackStates = new PlaybackState*[MAX_PLAYBACK_STATES];

		for (int i = 0; i < MAX_PLAYBACK_STATES; ++i )
		{
			g_playBackStates[i] = NULL;
		}
        
#ifdef PTHREAD
        pthread_mutex_init(&g_playBackStatesMutex, NULL);
#else
        InitializeCriticalSection(&g_playBackStatesMutex);
#endif
        
	}
    
#ifdef PTHREAD
    pthread_mutex_lock(&g_playBackStatesMutex);
#else
    EnterCriticalSection(&g_playBackStatesMutex);
#endif

	for (int i = 0; i < MAX_PLAYBACK_STATES; ++i )
	{
		if (g_playBackStates[i] == NULL)
		{
			g_playBackStates[i] = state;
			ret = true;
            break;
		}
	}
    
#ifdef PTHREAD
    pthread_mutex_unlock(&g_playBackStatesMutex);
#else
    LeaveCriticalSection(&g_playBackStatesMutex);
#endif

	return ret;
}

static void RemovePlaybackState(PlaybackState *state)
{
	if (g_playBackStates == NULL)
	{
        return;
    }
    
#ifdef PTHREAD
    pthread_mutex_lock(&g_playBackStatesMutex);
#else
    EnterCriticalSection(&g_playBackStatesMutex);
#endif
	
    for (int i = 0; i < MAX_PLAYBACK_STATES; ++i )
	{
        if (g_playBackStates[i] == state)
        {
            g_playBackStates[i] = NULL;
            break;
        }
    }
    
#ifdef PTHREAD
    pthread_mutex_unlock(&g_playBackStatesMutex);
#else
    LeaveCriticalSection(&g_playBackStatesMutex);
#endif
	
}


struct PlaybackState
{
	FILE *m_file;
	long m_fileOffset;
	long m_fileEnd;

	OGGZ *m_oggz;

	/* Ogg and codec state for demux/decode */
	th_info m_thInfo;
	th_comment m_thComment;
	th_setup_info *m_thSetupInfo;
	th_dec_ctx *m_thDecCtx;
	long m_thSerialno;

	bool m_finished;

#ifdef PTHREAD
	pthread_t m_decodeThread; 
	pthread_mutex_t m_upload_mutex;
	pthread_cond_t m_producerCond;
#else
	DWORD m_decodeThreadId;
	HANDLE m_decodeThreadHandle;
	CRITICAL_SECTION m_upload_mutex;
	CONDITION_VARIABLE m_producerCond;
#endif

	volatile bool m_exitThread;

	bool m_waitUpload;
	
	bool m_headerInitialized;

	ogg_int64_t m_currentDecodedFrameTimeMS;
	ogg_int64_t m_currentUploadFrameTimeMS;
	ogg_int64_t m_targetDecodeTimeMS;
	bool m_isKeyFrame;
	bool m_waitKeyFrame;
	ogg_int64_t m_durationMS;
	bool m_pot;
	int m_skippedFrames;
	int m_maxSkippedFrames;

	TextureContext *m_textureContext;

    int m_yStride;
    int m_yHeight;
    int m_uvStride;
    int m_uvHeight;


	static size_t OggzIORead(void * user_handle, void * buf, size_t n)
	{
		PlaybackState *state = (PlaybackState *)user_handle;

		//Clamp n to end of file
		long maxN = state->m_fileEnd - ftell(state->m_file);

		if ( (long)(n) > maxN )
		{
			n = (size_t)maxN;
		}

		
		return fread(buf, 1, n, state->m_file);
	}
	
	static int OggzIOSeek(void * user_handle, long offset, int whence)
	{
		PlaybackState *state = (PlaybackState *)user_handle;

		switch( whence )
		{
		default:
		case SEEK_SET: 
		case SEEK_CUR:
			{
				long fullFileOffset = state->m_fileOffset + offset;

				//Clamp offset
				fullFileOffset = fullFileOffset > state->m_fileEnd ? state->m_fileEnd : fullFileOffset;
				fullFileOffset = fullFileOffset < state->m_fileOffset ? state->m_fileOffset : fullFileOffset;

				return fseek(state->m_file, fullFileOffset, whence);
			}
			break;
		case SEEK_END:
			{
				long fullFileOffset = state->m_fileEnd + offset;
				
				//Clamp offset
				fullFileOffset = fullFileOffset > state->m_fileEnd ? state->m_fileEnd : fullFileOffset;
				fullFileOffset = fullFileOffset < state->m_fileOffset ? state->m_fileOffset : fullFileOffset;

				return fseek(state->m_file, fullFileOffset, SEEK_SET);
			}
			break;
		}
	}

	static long OggzIOTell(void * user_handle)
	{
		PlaybackState *state = (PlaybackState *)user_handle;
		return ftell(state->m_file) - state->m_fileOffset;
	}
    
    bool ThreadRunning()
    {
#ifdef PTHREAD
        return m_decodeThread != NULL;
#else
        return m_decodeThreadHandle != NULL;
#endif
    }
    
    void ClearThread()
    {
#ifdef PTHREAD
        m_decodeThread = NULL;
#else
        m_decodeThreadHandle = NULL;
#endif
    }
    

	void StartDecodeThread()
	{
		if (!ThreadRunning())
		{
#ifdef PTHREAD
			pthread_create(&m_decodeThread,NULL,DecodeThread,this);
#else
			m_decodeThreadHandle = CreateThread( 
				NULL,                   // default security attributes
				0,                      // use default stack size  
				DecodeThread,       // thread function name
				this,          // argument to thread function 
				0,                      // use default creation flags 
				&m_decodeThreadId);   // returns the thread identifier 


			// Check the return value for success.
			// If CreateThread fails, terminate execution. 
			// This will automatically clean up threads and memory. 

			//if (m_decodeThreadHandle == NULL) 
			//{
			//	ErrorHandler(TEXT("CreateThread"));
			//	ExitProcess(3);
			//}
#endif
		}
	}

	void StopDecodeThread()
	{
        if(ThreadRunning())
        {
#ifdef PTHREAD
			pthread_mutex_lock(&m_upload_mutex);
#else
			//WaitForSingleObject( m_upload_mutex, INFINITE);  // no time-out interval
			EnterCriticalSection(&m_upload_mutex);
#endif

			m_exitThread = true;
#ifdef PTHREAD
            pthread_cond_signal(&m_producerCond);
#else
			WakeConditionVariable(&m_producerCond);
#endif

#ifdef PTHREAD
			pthread_mutex_unlock(&m_upload_mutex);
#else
			//ReleaseMutex(m_upload_mutex);
			LeaveCriticalSection(&m_upload_mutex);
#endif

#ifdef PTHREAD
            //pthread_cancel(m_decodeThread); //doesn't work on android
            pthread_join(m_decodeThread,NULL);
#else
			WaitForSingleObject(m_decodeThreadHandle,INFINITE);
#endif

        }
	}


	bool Open(char *path, int offset, int size, bool pot, bool scanDuration, int maxSkippedFrames)
	{
		//Close the last movie, however don't release textures
		Close();	


		//Begin initialisation
		m_fileOffset = offset;
		m_finished = false;
		m_headerInitialized = false;
		m_currentDecodedFrameTimeMS = -1;
		m_currentUploadFrameTimeMS = -3;
		m_targetDecodeTimeMS = -2;
		m_pot = pot;
		m_skippedFrames = 0;
		m_maxSkippedFrames = maxSkippedFrames;

		//Open file
		m_file = fopen(path,"rb");

		if (m_file == NULL)
		{
			//pthread_mutex_unlock(&m_upload_mutex);
			return false;
		}

		if (size==0)
		{
			fseek(m_file,0,SEEK_END);
			size = ftell(m_file);
		}

		fseek(m_file,offset,SEEK_SET);
		m_fileEnd = offset+size;

		m_oggz = oggz_new(OGGZ_READ | OGGZ_AUTO);

		oggz_io_set_read( m_oggz, OggzIORead, this);
		oggz_io_set_seek( m_oggz, OggzIOSeek, this);
		oggz_io_set_tell( m_oggz, OggzIOTell, this);
		
		if (size==0)
		{
			fseek(m_file,0,SEEK_END);
			size = ftell(m_file);
		}

		fseek(m_file,offset,SEEK_SET);
		m_fileEnd = offset+size;

		m_oggz = oggz_new(OGGZ_READ | OGGZ_AUTO);

		oggz_io_set_read( m_oggz, OggzIORead, this);
		oggz_io_set_seek( m_oggz, OggzIOSeek, this);
		oggz_io_set_tell( m_oggz, OggzIOTell, this);

		if (scanDuration)
		{
			long n;

			oggz_seek_units (m_oggz, 0, SEEK_SET);

			while ((n = oggz_read (m_oggz, 102400)) > 0);

			/* We only return an error from our user callback on OOM */
			//if (n == OGGZ_ERR_STOP_ERR || n == OGGZ_ERR_OUT_OF_MEMORY)
			//	exit_out_of_memory ();

			//oggz_info_apply (oit_calc_average, info);

			/* Now we are at the end of the file, calculate the duration */
			m_durationMS = oggz_tell_units (m_oggz);
		}

		// Set the packet reader to get the required initialization data.
		m_headerInitialized = false;
		oggz_set_read_callback (m_oggz, -1, OggzReadPacketForInitializationCallback, this);
		oggz_seek_units (m_oggz, 0, SEEK_SET);

		/* init supporting Theora structures needed in header parsing */
		th_comment_init(&m_thComment);
		th_info_init(&m_thInfo);

		// Initialize the required data.
		while (!m_headerInitialized && oggz_read (m_oggz, 8192) > 0) 
		{
		}

		if (!m_headerInitialized)
		{
			//pthread_mutex_unlock(&m_upload_mutex);
			return false;
		}

		// Set the file position to the start.
		oggz_seek_units (m_oggz, 0, SEEK_SET);
		oggz_set_read_callback (m_oggz, m_thSerialno, OggzReadPacketCallback, this);


		StartDecodeThread();

		
		return true;
	}

	void Close() 
	{
		StopDecodeThread();

	
#ifdef PTHREAD
        pthread_mutex_lock(&m_upload_mutex);
#else
        EnterCriticalSection(&m_upload_mutex);
#endif
        
		if (m_oggz != NULL) 
		{
			oggz_close (m_oggz);
			m_oggz = NULL;
		}

		th_comment_clear(&m_thComment);
		th_info_clear(&m_thInfo);

		if (m_headerInitialized)
		{
			th_decode_free(m_thDecCtx);
			m_thDecCtx = NULL;
		}

		if (m_thSetupInfo != NULL)
		{
			th_setup_free (m_thSetupInfo);
			m_thSetupInfo = NULL;
		}

		if (m_file)
		{
			fclose(m_file);
			m_file = NULL;
        }
        
#ifdef PTHREAD
        pthread_mutex_unlock (&m_upload_mutex);
#else
        LeaveCriticalSection(&m_upload_mutex);
#endif
	}



	PlaybackState()
		: m_file(NULL)
		, m_oggz(NULL)
		, m_thSetupInfo(NULL)
		, m_thDecCtx(NULL)
		, m_exitThread(false)
		, m_skippedFrames(0)
		, m_textureContext(NULL)
		, m_waitKeyFrame(false)
	{
        ClearThread();
        
        m_currentDecodedFrameTimeMS = -1;
		m_currentUploadFrameTimeMS = -3;
		m_targetDecodeTimeMS = -2;
		
#ifdef PTHREAD
        pthread_mutex_init(&m_upload_mutex, NULL);
        pthread_cond_init(&m_producerCond, NULL);
#else
		//m_upload_mutex = CreateMutex( 
		//	NULL,              // default security attributes
		//	FALSE,             // initially not owned
		//	NULL);             // unnamed mutex

		InitializeCriticalSection(&m_upload_mutex);

		//if (m_upload_mutex == NULL) 
		//{
		//	printf("CreateMutex error: %d\n", GetLastError());
		//}
		InitializeConditionVariable (&m_producerCond);

#endif 

		th_comment_init(&m_thComment);
		th_info_init(&m_thInfo);
	}


	~PlaybackState()
	{
		Close();
        
		ReleaseTextures();
        
#ifdef PTHREAD
        pthread_cond_destroy(&m_producerCond);
        pthread_mutex_destroy(&m_upload_mutex);
#else

#endif
	}


    

	void AllocateTextures()
	{
		if ( m_headerInitialized &&
             g_DeviceType != kGfxRendererNull &&
				(m_textureContext == NULL || 
				m_textureContext->m_yStride != m_yStride ||
				m_textureContext->m_yHeight != m_yHeight ||
				m_textureContext->m_uvStride != m_uvStride ||
				m_textureContext->m_uvHeight != m_uvHeight
				)
				)
		{
			//New texture context
			if (m_textureContext != NULL)
			{
				delete m_textureContext;
				m_textureContext = NULL;
			}

			m_textureContext = new TextureContext(m_yStride,m_yHeight,m_uvStride,m_uvHeight);
		}
	}



	void ReleaseTextures()
	{
#ifdef PTHREAD
        pthread_mutex_lock(&m_upload_mutex);
#else
        EnterCriticalSection(&m_upload_mutex);
#endif
		if (m_textureContext != NULL)
		{
			delete m_textureContext;
			m_textureContext = NULL;
		}

		m_currentUploadFrameTimeMS = -3;
        
#ifdef PTHREAD
        pthread_mutex_unlock (&m_upload_mutex);
#else
        LeaveCriticalSection(&m_upload_mutex);
#endif
	}


	void TryUpload( ) 
	{
        
#ifdef PTHREAD
		if ( ( m_waitUpload && pthread_mutex_lock(&m_upload_mutex) == 0 ) ||
			(pthread_mutex_trylock(&m_upload_mutex)==0) )
		{
#else
		
		//if( WaitForSingleObject( m_upload_mutex, m_waitUpload ? INFINITE : 0) == WAIT_OBJECT_0);  
		if(m_waitUpload || TryEnterCriticalSection(&m_upload_mutex))
		{
			if (m_waitUpload)
			{
				EnterCriticalSection(&m_upload_mutex);
			}		
#endif
			if (m_currentDecodedFrameTimeMS > 0 && m_currentDecodedFrameTimeMS != m_currentUploadFrameTimeMS)
			{
				if (m_textureContext == NULL)
				{
					AllocateTextures();
				}

				if (m_textureContext != NULL && m_thDecCtx != NULL && m_textureContext->UploadTextures(m_thDecCtx))
				{
					m_currentUploadFrameTimeMS = m_currentDecodedFrameTimeMS;
				}
			}

            if (m_targetDecodeTimeMS > m_currentDecodedFrameTimeMS)
            {
#ifdef PTHREAD
                pthread_cond_signal(&m_producerCond);
#else
				WakeConditionVariable (&m_producerCond);
#endif
            }
            
            m_waitUpload = false;

#ifdef PTHREAD
            pthread_mutex_unlock (&m_upload_mutex);
#else
			//ReleaseMutex(m_upload_mutex);
			LeaveCriticalSection(&m_upload_mutex);
#endif 
		}		
	}


	static int OggzReadPacketForInitializationCallback (OGGZ* oggz, oggz_packet* packet, long serialno, void* user_data) 
	{
		if (oggz_stream_get_content (oggz, serialno) == OGGZ_CONTENT_THEORA) 
		{

			PlaybackState* state = (PlaybackState*) user_data;
			ogg_packet op = packet->op;

			int theora_decode_result = th_decode_headerin (&(state->m_thInfo), &(state->m_thComment), &(state->m_thSetupInfo), &op);
			if (theora_decode_result == 0 && state->m_thDecCtx == NULL) 
			{
				state->m_thDecCtx = th_decode_alloc(&(state->m_thInfo), state->m_thSetupInfo, state->m_pot);
				
				state->m_yStride = -(state->m_thDecCtx->state.ref_frame_bufs[0][0].stride);
				state->m_yHeight = state->m_thDecCtx->state.ref_frame_bufs[0][0].height;
				state->m_uvStride = -(state->m_thDecCtx->state.ref_frame_bufs[0][1].stride);
				state->m_uvHeight = state->m_thDecCtx->state.ref_frame_bufs[0][1].height;

				if (state->m_pot) 
				{
					state->m_yStride = NextPowerOf2 (state->m_yStride);
					state->m_yHeight = NextPowerOf2 (state->m_yHeight);
					state->m_uvStride = NextPowerOf2 (state->m_uvStride);
					state->m_uvHeight = NextPowerOf2 (state->m_uvHeight);	
				}

				// The header initialization is finished and we can
				// switch to the actual callbacks.
				state->m_thSerialno = serialno;

				state->m_headerInitialized = true;
				oggz_set_read_callback (oggz, -1, NULL, NULL);

				th_setup_free (state->m_thSetupInfo);
				state->m_thSetupInfo = NULL;

				//state->m_thDecCtx->pp_level = 3;

				state->AllocateTextures();
			}
		}

		return (OGGZ_CONTINUE);
	}



	static int OggzReadPacketCallback (OGGZ* oggz, oggz_packet* packet, long serialno, void* user_data) 
	{
		PlaybackState* state = (PlaybackState*) user_data;

		ogg_packet op = packet->op;

		// Decode and wait
		if (th_decode_packetin (state->m_thDecCtx, &op, NULL) >= 0) 
		{
			state->m_currentDecodedFrameTimeMS = oggz_tell_units (state->m_oggz);
			state->m_isKeyFrame = (th_packet_iskeyframe(&op) == 1);

			if (state->m_waitKeyFrame && state->m_isKeyFrame || !state->m_waitKeyFrame)
			{
				if(state->m_waitKeyFrame)
				{
					state->m_waitKeyFrame = false;
				}

				if ((state->m_currentDecodedFrameTimeMS >= state->m_targetDecodeTimeMS) || (state->m_skippedFrames >= state->m_maxSkippedFrames))
				{
					state->m_skippedFrames = 0;
#ifdef PTHREAD
                    pthread_cond_wait(&state->m_producerCond, &state->m_upload_mutex);
#else
					SleepConditionVariableCS(&state->m_producerCond, &state->m_upload_mutex, INFINITE);
#endif
				}
				else
				{
					state->m_skippedFrames++;
				}
				
			}

			if (state->m_exitThread)
			{
#ifdef PTHREAD
				pthread_mutex_unlock(&state->m_upload_mutex);
#else
				//ReleaseMutex(state->m_upload_mutex);
				LeaveCriticalSection(&state->m_upload_mutex);
#endif

#ifdef PTHREAD
				pthread_exit(NULL);
#else
				DecodeThreadFinished(state);
				ExitThread(0);
#endif
			}
		}		

		return (OGGZ_CONTINUE);
	}

	ogg_int64_t SeekInMSKeyFrame(ogg_int64_t time, bool waitKeyFrame)
	{
#ifdef PTHREAD
		pthread_mutex_lock(&m_upload_mutex);
#else
		//WaitForSingleObject( m_upload_mutex, INFINITE);  // no time-out interval
		EnterCriticalSection(&m_upload_mutex);
#endif
		m_finished = false;
		m_currentDecodedFrameTimeMS = -1;
		m_currentUploadFrameTimeMS = -3;
        m_waitKeyFrame = waitKeyFrame;

		ogg_int64_t result = oggz_keyframe_seek_set(m_oggz, &m_thSerialno, 1, time, 0, -1 );

#ifdef PTHREAD
		pthread_mutex_unlock(&m_upload_mutex);
#else
		//ReleaseMutex(m_upload_mutex);
		LeaveCriticalSection(&m_upload_mutex);
#endif

		return result;
	}

	static void DecodeThreadFinished(void *cotext)
	{
        PlaybackState* state = (PlaybackState*)cotext;

		state->m_exitThread = false;
        state->ClearThread();
	}

#ifdef PTHREAD
	static void *DecodeThread ( void* user_data ) 
#else
	static DWORD WINAPI DecodeThread( LPVOID user_data )
#endif
	{
		PlaybackState* state = (PlaybackState*) user_data;

#ifdef PTHREAD
		pthread_mutex_lock(&state->m_upload_mutex);
#else
		//WaitForSingleObject( state->m_upload_mutex, INFINITE);  // no time-out interval
		EnterCriticalSection( &state->m_upload_mutex );
#endif

#ifdef PTHREAD
        pthread_cleanup_push(DecodeThreadFinished,state);
#endif

		while (oggz_read (state->m_oggz, 8192) > 0 && !state->m_exitThread) 
		{
		}

		state->m_finished = true;

#ifdef PTHREAD
		pthread_mutex_unlock(&state->m_upload_mutex);
#else
		//ReleaseMutex(state->m_upload_mutex);
		LeaveCriticalSection(&state->m_upload_mutex);
#endif

#ifdef PTHREAD
		pthread_cleanup_pop(1);
#else
		DecodeThreadFinished(state);
#endif
		
		return NULL;
	}	
 
#ifdef PTHREAD
    static void CheckRet(int ret)
    {
        if (ret != 0)
        {
            int errornumber = errno;
            switch(errornumber)
            {
                case EINTR:
                    Log("problems EINTR");
                    break;
                case EINVAL:
                    Log("problems EINVAL");
                    break;
                
            }
        }
    }
#endif


};





extern "C"
{
	THEORAWRAPPER_API void *CreateContext()
	{
		if (PlaybackState *state = new PlaybackState())
		{
			if (AddPlaybackState(state))
			{
				return state;
			}
			else
			{
				delete state;
			}
		}

		return NULL;
	}

	THEORAWRAPPER_API void DestroyContext(PlaybackState *state)
	{
		if (state)
		{
			RemovePlaybackState(state);
			delete state;
		}
	}

	THEORAWRAPPER_API bool OpenStream(PlaybackState *state, char *path, int offset, int size, bool pot, bool scanDuration, int maxSkippedFrames)
	{
		if (state)
		{
			return state->Open(path,offset,size,pot,scanDuration,maxSkippedFrames);
		}
		else
		{
			return NULL;
		}
	}

	THEORAWRAPPER_API void CloseStream(PlaybackState *state)
	{
		if (state)
		{
			state->Close();
		}
	}

	THEORAWRAPPER_API int GetPicWidth( PlaybackState *state )
	{
		return state ? state->m_thInfo.pic_width : 0;
	}

	THEORAWRAPPER_API int GetPicHeight( PlaybackState *state )
	{
		return state ? state->m_thInfo.pic_height : 0;
	}

	THEORAWRAPPER_API int GetPicX( PlaybackState *state )
	{
		return state ? state->m_thInfo.pic_x : 0;
	}

	THEORAWRAPPER_API int GetPicY( PlaybackState *state )
	{
		return state ? state->m_thInfo.pic_y : 0;
	}

    THEORAWRAPPER_API int GetYStride( PlaybackState *state )
	{
		return state ? state->m_yStride : 0;
	}

    THEORAWRAPPER_API int GetYHeight( PlaybackState *state )
	{
		return state ? state->m_yHeight : 0;
	}
    
    THEORAWRAPPER_API int GetUVStride( PlaybackState *state )
	{
		return state ? state->m_uvStride : 0;
	}
    
    THEORAWRAPPER_API int GetUVHeight( PlaybackState *state )
	{
		return state ? state->m_uvHeight : 0;
	}

	THEORAWRAPPER_API bool HasFinished(PlaybackState *state)
	{
		return state != NULL ? state->m_finished : false;
	}

	THEORAWRAPPER_API double GetDecodedFrameTime(PlaybackState *state)
	{
		return (double)(state->m_currentDecodedFrameTimeMS)/1000.0f;
	}
    
    THEORAWRAPPER_API double GetUploadedFrameTime(PlaybackState *state)
	{
		return (double)(state->m_currentUploadFrameTimeMS)/1000.0f;
	}
    
    THEORAWRAPPER_API double GetTargetDecodeFrameTime(PlaybackState *state)
	{
		return (double)(state->m_targetDecodeTimeMS)/1000.0f;
	}
    

	THEORAWRAPPER_API void SetTargetDisplayDecodeTime(PlaybackState *state, double frameTime)
	{
		if (state != NULL)
		{
			state->m_targetDecodeTimeMS = (ogg_int64_t)(frameTime * 1000.0f);

			if (!state->ThreadRunning())
			{
                state->StartDecodeThread();
			}
            
            //Seems logical to start the decode thread here, but it works out badly timing wise
            //means it is almost always busy when it comes to want to upload
            //better to let it start again after upload
            
			//else
			//{
                //if (state->m_targetDecodeTimeMS > state->m_currentDecodedFrameTimeMS)
                //{
                //    pthread_cond_signal(&state->m_producerCond);
                //}
			//}
		}
	}

	THEORAWRAPPER_API double GetVideoFPS(PlaybackState *state)
	{
		if (state  != NULL && state->m_headerInitialized)
		{
			return (double)(state->m_thInfo.fps_numerator)/(double)(state->m_thInfo.fps_denominator);
		}
		else
		{
			return 0.0;
		}
	}

	THEORAWRAPPER_API float GetAspectRatio(PlaybackState *state)
	{
		if (state && state->m_thInfo.aspect_numerator && state->m_thInfo.aspect_denominator && state->m_thInfo.pic_height)
		{
			return (float)(state->m_thInfo.aspect_numerator*state->m_thInfo.pic_width)/(float)(state->m_thInfo.aspect_denominator*state->m_thInfo.pic_height);
		}
		else
		{
			return 1.0f;
		}
	}

	THEORAWRAPPER_API double Seek (PlaybackState *state, double time, bool waitKeyFrame)
	{
		if (state)
		{
			return (double)(state->SeekInMSKeyFrame(time * 1000, waitKeyFrame )) / 1000.0;
		}
		else
		{
			return 0.0;
		}
	}

	THEORAWRAPPER_API double GetDuration(PlaybackState *state)
	{
		if (state)
		{
			return (double)(state->m_durationMS) / 1000.0;
		}
		else
		{
			return 0.0;
		}

	}


	THEORAWRAPPER_API void *GetNativeHandle( PlaybackState *state , int plane)
	{
		if (state && state->m_textureContext)
		{
            return state->m_textureContext->m_planes[plane].GetNativeHandle();
		}
        else
        {
            return NULL;
        }
	}

	

	THEORAWRAPPER_API void *GetNativeTextureContext( PlaybackState *state )
	{
		if (state)
		{
			return state->m_textureContext;
		}
		else
		{
			return NULL;
		}
	}

	THEORAWRAPPER_API void SetPostProcessingLevel( PlaybackState *state, int level )
	{
		if (state && state->m_thDecCtx)
		{
			state->m_thDecCtx->pp_level = level;
		}
	}
    
    THEORAWRAPPER_API void UploadReadyPlaybackStates ()
    {
#ifdef PTHREAD
        pthread_mutex_lock(&g_playBackStatesMutex);
#else
        EnterCriticalSection(&g_playBackStatesMutex);
#endif
        
        if (g_playBackStates != NULL)
        {
            for (int i = 0; i < MAX_PLAYBACK_STATES; ++i )
            {
                if (g_playBackStates[i] != NULL)
                {
                    g_playBackStates[i]->TryUpload();
                }
            }
        }
#ifdef PTHREAD
        pthread_mutex_unlock(&g_playBackStatesMutex);
#else
        LeaveCriticalSection(&g_playBackStatesMutex);
#endif
    }

		static void HandleGraphicsEvent (GfxDeviceRenderer deviceType, GfxDeviceEventType eventType)
	{
		// Create or release a small dynamic vertex buffer depending on the event type.
		switch (eventType) 
		{
		case kGfxDeviceEventInitialize:
		case kGfxDeviceEventAfterReset:
			// After device is initialized or was just reset, create the VB.
			if (g_playBackStates != NULL)
			{
				for (int i = 0; i < MAX_PLAYBACK_STATES; ++i )
				{
					if (g_playBackStates[i] != NULL)
					{
						g_playBackStates[i]->AllocateTextures();
					}
				}
			}
			

			break;
		case kGfxDeviceEventBeforeReset:
		case kGfxDeviceEventShutdown:
			// Before device is reset or being shut down, release the VB.
			
			if (g_playBackStates != NULL)
			{
				for (int i = 0; i < MAX_PLAYBACK_STATES; ++i )
				{
					if (g_playBackStates[i] != NULL)
					{
						g_playBackStates[i]->ReleaseTextures();
					}
				}
			}
			break;
		}
	}
    
    THEORAWRAPPER_API void SetGraphicsDevice (void* device, int deviceType, int eventType)
    {
    	// Set device type to kGfxRendererNull, i.e. "not recognized by our plugin"
		g_DeviceType = (GfxDeviceRenderer)deviceType;
        
		
#ifdef SUPPORT_D3D9
		// D3D9 device, remember device pointer and device type.
		// The pointer we get is IDirect3DDevice9.
		if (deviceType == kGfxRendererD3D9)
		{
			//DebugLog ("Set D3D9 graphics device\n");
			//g_DeviceType = deviceType;
			g_DeviceD3D9 = (IDirect3DDevice9*)device;
			HandleGraphicsEvent (g_DeviceType,(GfxDeviceEventType)eventType);
		}
#endif
        
#if SUPPORT_D3D11
		// D3D11 device, remember device pointer and device type.
		// The pointer we get is ID3D11Device.
		if (deviceType == kGfxRendererD3D11)
		{
			g_DeviceD3D11 = (ID3D11Device*)device;
			//SetGraphicsDeviceD3D11 ((ID3D11Device*)device, (GfxDeviceEventType)eventType);
		}
#endif
        
#ifdef SUPPORT_OPENGL
		// If we've got an OpenGL device, remember device type. There's no OpenGL
		// "device pointer" to remember since OpenGL always operates on a currently set
		// global context.
		/*if (deviceType == kGfxRendererOpenGL || deviceType == kGfxRendererOpenGLES20Mobile || deviceType == kGfxRendererOpenGLES30)
		{
			Log ("Set OpenGL graphics device\n");
		}*/
#endif
        
#ifdef SUPPORT_METAL
        if (deviceType == kGfxRendererMetal)
        {
            Log ("Set Metal graphics device\n");
            SetMetalDevice(device);
        }
#endif
    }
    
    
#if defined (iOS)
    THEORAWRAPPER_API void MMTUnityRenderEvent (int eventID)
    {
        if	(eventID == 7)
        {
            UploadReadyPlaybackStates();
        }
        
    }
    
    THEORAWRAPPER_API void MMTUnitySetGraphicsDevice (void* device, int deviceType, int eventType)
    {
        Log("Device Type %d\n Device %08X\n", deviceType,device);
        
        SetGraphicsDevice (device,deviceType,eventType);
    }
	

#else
    
    THEORAWRAPPER_API void UnityRenderEvent (int eventID)
    {
        if	(eventID == 7)
        {
            UploadReadyPlaybackStates();
        }
        
    }
    
    THEORAWRAPPER_API void UnitySetGraphicsDevice (void* device, int deviceType, int eventType)
    {
        SetGraphicsDevice (device,deviceType,eventType);
    }

#endif



}
