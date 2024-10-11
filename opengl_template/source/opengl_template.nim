import staticglfw as glfw
import opengl

type Application = ref object 
    window: Window

const 
    screen_width = 800
    screen_height = 600
    title = "Nim OpenGL Template"


proc shouldClose(app: Application): bool {.inline.} =
    return bool( app.window.windowShouldClose() )


proc initalize(app: Application): bool =
    if glfw.init().bool == false:
        return false

    glfw.windowHint(CONTEXT_VERSION_MAJOR, 3)
    glfw.windowHint(CONTEXT_VERSION_MINOR, 3)
    glfw.windowHint(OPENGL_FORWARD_COMPAT, true.cint)
    glfw.windowHint(OPENGL_PROFILE, OPENGL_COMPAT_PROFILE)

    app.window = createWindow(
        screen_width, screen_height, 
        title, nil, nil
    )

    if (app.window == nil):
        return false

    app.window.makeContextCurrent()
    glfw.swapInterval(1)

    discard glfw.setFramebufferSizeCallback(app.window,
    proc (window: Window, width, height: int32): void {.cdecl.} =
        glViewport(0, 0, width, height)
    )

    opengl.loadExtensions()

    debugEcho "INFO: ", cast[cstring]( glGetString(GL_VERSION) )
    debugEcho "INFO: ", cast[cstring]( glGetString(GL_RENDERER) )

    return true


proc close(app: Application): void {.noreturn.} =
    app.window.destroyWindow()
    glfw.terminate()

    debugEcho "INFO: Succesfully closed app"

    quit(0)


proc initalizeGl(): void =
    glViewport(0, 0, screen_width, screen_height)
    glClearColor(0.67, 0.73, 0.8, 1)

    return


proc loadShaderSource(file_path: string): string {.inline.} =
    try: result = readFile(file_path)
    except ref IOError as e: echo e.msg
    return result


proc checkCompileStatus(shader_type: GLenum, shader_id: uint32): uint32 =
    var did_compile: int32 # treating it as a bool here
    glGetShaderiv(shader_id, GL_COMPILE_STATUS, did_compile.addr)

    if did_compile.bool:
        debugEcho "DEBUG INFO: Shader compiled!"
        return shader_id

    var shader_length: int32
    glGetShaderiv(result, GL_INFO_LOG_LENGTH, shader_length.addr)
    var message: cstring 
    glGetShaderInfoLog(result, shader_length, shader_length.addr, message)
            
    let shader_type_text = if (shader_type == GL_VERTEX_SHADER):
        "vertext"
    else:
        "fragment"

    echo "ERROR: Failed to compile `", shader_type_text, " shader!"
    echo message
    glDeleteShader(result)

    return 0


proc compileShader(shader_type: GLenum, source: string): uint32 =    
    result = glCreateShader(shader_type)

    let c_source = cstring(source)
    # v this is just a char**
    let c_source_ptr = cast[cstringArray](c_source.addr)

    glShaderSource(result, 1, c_source_ptr, nil)
    glCompileShader(result)

    result = checkCompileStatus(shader_type, result)
    return result


proc createShader(vertex, fragment: string): uint32 =
    result = glCreateProgram()
    let vertex_id = compileShader(GL_VERTEX_SHADER, vertex)
    let fragment_id = compileShader(GL_FRAGMENT_SHADER, fragment)

    glAttachShader(result, vertex_id)
    glAttachShader(result, fragment_id)
    glLinkProgram(result)
    glValidateProgram(result)

    glDeleteShader(vertex_id)
    glDeleteShader(fragment_id)

    return result

#[ proc getCursorPosition(app: Application): (float32, float32) =
    var mouse_x, mouse_y: float64
    getCursorPos(app.window, mouse_x.addr, mouse_y.addr)

    var width, height: int32
    app.window.getWindowSize(width.addr, height.addr)

    return (
        (2.0*mouse_x / width.float) - 1.0,
        1.0 - (2.0*mouse_y / height.float) # flip y to match openGL
    ) ]#

# main && entry #
proc main(): void =
    # init the app
    let app = Application(window: nil)
    defer: app.close()

    if not app.initalize():
        app.close()
    
    initalizeGl()
    # end init the app

    # triangle buffer #
    let positions: array[8, float32] = [
        -1.0, -1.0,
         1.0, -1.0,
         1.0,  1.0,
        -1.0,  1.0,
    ]

    let indices: array[6, uint32] = [
        0, 1, 2,
        2, 3, 0,
    ]

    var vao: uint32
    glGenVertexArrays(1, vao.addr)
    glBindVertexArray(vao)

    var buffer: uint32
    glGenBuffers(1, buffer.addr)
    glBindBuffer(GL_ARRAY_BUFFER, buffer)
    glBufferData(
        GL_ARRAY_BUFFER, ( sizeof(float32)*8 ), 
        positions[0].addr, GL_STATIC_DRAW
    )

    var ibo: uint32 
    glGenBuffers(1, ibo.addr)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo)
    glBufferData(
        GL_ELEMENT_ARRAY_BUFFER, ( sizeof(uint32)*6 ),
        indices[0].addr, GL_STATIC_DRAW
    )

    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 2, cGL_FLOAT, false, sizeof(float32) * 2, nil)
    # end triangle buffer #

    # load shader program
    # these get loaded during compile time, pretty cool
    const vert_shader = loadShaderSource("assets/shaders/chroma.vert")
    const frag_shader = loadShaderSource("assets/shaders/chroma.frag")

    let shader_id = createShader(vert_shader, frag_shader)
    defer: glDeleteProgram(shader_id)

    if (shader_id == 0):
        app.close()

    glUseProgram(shader_id) 
    # end load shader program

    # main loop
    while not app.shouldClose():
        glClear(GL_COLOR_BUFFER_BIT)

        glUniform1f(glGetUniformLocation(shader_id, "time"), glfw.getTime() )
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nil)

        app.window.swapBuffers()
        glfw.pollEvents()

    return

when is_main_module: main()