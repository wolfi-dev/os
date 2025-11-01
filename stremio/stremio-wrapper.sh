#!/bin/sh
# Intelligent hardware acceleration detection for containers
# Tests actual capabilities before enabling features

detect_container() {
    [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -q '/docker/\|/lxc/' /proc/1/cgroup 2>/dev/null
}

test_dri_access() {
    # Test if DRI devices are accessible and functional
    [ -c /dev/dri/card0 ] && [ -r /dev/dri/card0 ] && [ -w /dev/dri/card0 ]
}

test_glx_support() {
    # Test if GLX context can be created
    if command -v glxinfo >/dev/null 2>&1; then
        glxinfo >/dev/null 2>&1
        return $?
    fi
    return 1
}

test_egl_support() {
    # Test if EGL context works
    if command -v eglinfo >/dev/null 2>&1; then
        eglinfo >/dev/null 2>&1
        return $?
    fi
    return 1
}

if detect_container; then
    echo "Container environment detected"

    # Test hardware acceleration capabilities
    HW_ACCEL=false
    GPU_BACKEND=""

    if test_dri_access; then
        echo "DRI device access: OK"

        # Test GLX first (preferred)
        if test_glx_support; then
            echo "GLX support: AVAILABLE"
            export QT_XCB_GL_INTEGRATION=xcb_glx
            export LIBGL_DRIVERS_PATH=/usr/lib/xorg/modules/dri
            HW_ACCEL=true
            GPU_BACKEND="GLX"
        # Fallback to EGL
        elif test_egl_support; then
            echo "EGL support: AVAILABLE (GLX failed)"
            export QT_XCB_GL_INTEGRATION=xcb_egl
            export LIBGL_DRIVERS_PATH=/usr/lib/xorg/modules/dri
            HW_ACCEL=true
            GPU_BACKEND="EGL"
        else
            echo "Hardware rendering tests failed - using software"
        fi
    else
        echo "DRI device access: FAILED"
    fi

    if [ "$HW_ACCEL" = "true" ]; then
        echo "Hardware acceleration: ENABLED ($GPU_BACKEND)"

        # Enable hardware acceleration for Qt
        export QT_QUICK_BACKEND=rhi

        # QtWebEngine with hardware acceleration
        export QTWEBENGINE_CHROMIUM_FLAGS="--autoplay-policy=no-user-gesture-required --no-sandbox --disable-seccomp-filter-sandbox --disable-setuid-sandbox --disable-namespace-sandbox --disable-dev-shm-usage --enable-accelerated-2d-canvas --enable-gpu-rasterization --ignore-gpu-blocklist"

    else
        echo "Hardware acceleration: DISABLED (fallback to software)"

        # CRITICAL: Use software OpenGL rendering (Mesa llvmpipe)
        # This allows libmpv to work without hardware GPU
        export LIBGL_ALWAYS_SOFTWARE=1
        export GALLIUM_DRIVER=llvmpipe
        
        # Qt configuration for software OpenGL
        export QT_XCB_GL_INTEGRATION=xcb_glx  # Still use GLX, but with software rendering
        export QT_QUICK_BACKEND=rhi           # Use RHI backend (can work with software GL)
        
        # QtWebEngine software rendering
        export QTWEBENGINE_DISABLE_GPU=1
        export QTWEBENGINE_CHROMIUM_FLAGS="--autoplay-policy=no-user-gesture-required --no-sandbox --disable-seccomp-filter-sandbox --disable-setuid-sandbox --disable-namespace-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-accelerated-2d-canvas --disable-accelerated-jpeg-decoding --disable-accelerated-mjpeg-decode --disable-accelerated-video-decode --disable-background-timer-throttling --disable-renderer-backgrounding --disable-backgrounding-occluded-windows --in-process-gpu"
    fi

    # CRITICAL: Disable MIT-SHM to prevent BadShmSeg errors in containers
    export QT_X11_NO_MITSHM=1
    export _X11_NO_MITSHM=1
    export SDL_VIDEO_X11_NO_MITSHM=1

else
    # Bare metal: full hardware acceleration
    echo "Bare metal environment detected"

    if [ -e /dev/dri/card0 ]; then
        export LIBGL_DRIVERS_PATH=/usr/lib/xorg/modules/dri
        export QT_XCB_GL_INTEGRATION=xcb_glx
        export QT_QUICK_BACKEND=rhi
    else
        export QT_QUICK_BACKEND=software
    fi
fi

# Common settings
export QT_AUTO_SCREEN_SCALE_FACTOR="${QT_AUTO_SCREEN_SCALE_FACTOR:-1}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
export QTWEBENGINE_DISABLE_SANDBOX=1

# Debug output
echo "OpenGL: ${LIBGL_ALWAYS_SOFTWARE:-hardware}"
echo "Qt Backend: ${QT_QUICK_BACKEND}"
echo "Qt GL Integration: ${QT_XCB_GL_INTEGRATION:-default}"

exec /usr/libexec/stremio/stremio "$@"
