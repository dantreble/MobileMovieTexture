//
//  TextureOpenGL.cpp
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#include <stdlib.h>
#include <string.h>

#include "TextureOpenGL.h"

#ifdef SUPPORT_OPENGL
bool UploadPlaneOpenGL( GLuint handle, int stride, int height, unsigned char *planeData )
{
    if (handle == GL_INVALID_VALUE)
    {
        return false;
    }
    
    glBindTexture(GL_TEXTURE_2D, handle);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); //Try GL_NEAREST
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST); //GL_NEAREST
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, stride, height, GL_ALPHA, GL_UNSIGNED_BYTE, planeData);
    //glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, x, y, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, data );

    return true;
}

GLuint AllocateTextureOpenGL( int x, int y )
{
    GLuint handle;
    
    glGenTextures( 1, &handle );
    //UploadTextureOpenGL(handle, x, y, NULL);
    glBindTexture(GL_TEXTURE_2D, handle);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); //Try GL_NEAREST
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST); //GL_NEAREST
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, x, y, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, x, y, 0, GL_ALPHA, GL_UNSIGNED_BYTE, 0 );
    
    return handle;
}

GLuint ReleaseTextureOpenGL(GLuint handle)
{
    glDeleteTextures(1,&handle);
    return GL_INVALID_VALUE;
}

void FillByteOpenGL( GLuint handle, int x, int y , int val)
{
    unsigned char *buffer = (unsigned char *)malloc(x*y);
    
    memset(buffer,val,x*y);
    
    UploadPlaneOpenGL( handle, x, y, buffer );
    
    free(buffer);
}


#endif