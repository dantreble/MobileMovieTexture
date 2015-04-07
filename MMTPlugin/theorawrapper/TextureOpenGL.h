//
//  TextureOpenGL.h
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef __theorawrapper__TextureOpenGL__
#define __theorawrapper__TextureOpenGL__

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
#include <windows.h>
#include <GL/gl.h>
#endif


void UploadTextureOpenGL( GLuint handle, int x, int y, void * data );
GLuint AllocateTextureOpenGL( int x, int y );
GLuint ReleaseTextureOpenGL(GLuint handle);
bool UploadPlaneOpenGL( GLuint handle, int stride, int height, unsigned char *planeData );
void FillByteOpenGL( GLuint handle, int x, int y , int val);


#endif
#endif /* defined(__theorawrapper__TextureOpenGL__) */
